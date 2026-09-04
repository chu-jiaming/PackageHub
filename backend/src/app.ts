import Fastify from 'fastify';
import rateLimit from '@fastify/rate-limit';
import { Buffer } from 'node:buffer';
import { AuthService } from './auth/auth_service.js';
import { AppleJwtVerifier } from './auth/apple_token_verifier.js';
import { AppleHttpTokenExchange } from './auth/apple_token_exchange.js';
import { pgRepositories } from './db/repositories.js';
import { withTransaction, requireDb } from './db/repositories.js';
import { AppleOfficialVerifier, AppleOfficialServerClient, createAppleClients } from './subscription/apple.js';
import { PgSubscriptionRepository, SubscriptionService, PRO_STATES } from './subscription/entitlement.js';

const errorCode = (e: unknown) => e instanceof Error && /^(AUTH_|REFRESH_|APPLE_)/.test(e.message) ? e.message : 'REQUEST_FAILED';

export function createApp(service?: AuthService, subscriptions?: SubscriptionService) {
  const clientId = process.env.APPLE_CLIENT_ID || 'com.charm1ng.packagehub';
  const config = process.env.APPLE_TEAM_ID && process.env.APPLE_KEY_ID && process.env.APPLE_PRIVATE_KEY ? { teamId: process.env.APPLE_TEAM_ID, keyId: process.env.APPLE_KEY_ID, clientId, privateKey: process.env.APPLE_PRIVATE_KEY } : undefined;
  const secret = process.env.SESSION_JWT_SECRET || 'local-development-secret-change-me-32chars';
  const encryptionKey = Buffer.from(process.env.TOKEN_ENCRYPTION_KEY || 'local-development-encryption-key-32', 'utf8').subarray(0, 32);
  const auth = service ?? new AuthService(new AppleJwtVerifier(clientId), new AppleHttpTokenExchange(config), secret, encryptionKey, pgRepositories());
  let subscriptionService = subscriptions;
  if (!subscriptionService && process.env.APP_STORE_PRIVATE_KEY && process.env.APP_STORE_KEY_ID && process.env.APP_STORE_ISSUER_ID && process.env.APP_STORE_APP_APPLE_ID && process.env.APP_STORE_ROOT_CA_CERTS) {
    const roots = process.env.APP_STORE_ROOT_CA_CERTS.split(',').map(v => Buffer.from(v, 'base64'));
    const c = createAppleClients({ key: process.env.APP_STORE_PRIVATE_KEY, keyId: process.env.APP_STORE_KEY_ID, issuerId: process.env.APP_STORE_ISSUER_ID, bundleId: process.env.APP_STORE_BUNDLE_ID || clientId, appAppleId: Number(process.env.APP_STORE_APP_APPLE_ID), rootCertificates: roots, environment: (process.env.APP_STORE_ENVIRONMENT === 'Production' ? 'Production' : 'Sandbox') });
    subscriptionService = new SubscriptionService(c.verifier, c.server, new PgSubscriptionRepository(), process.env.ENTITLEMENT_SIGNING_PRIVATE_KEY, process.env.ENTITLEMENT_SIGNING_KEY_ID || 'packagehub-entitlement');
  }
  const app = Fastify({ logger: { redact: ['req.headers.authorization', 'body.identityToken', 'body.authorizationCode', 'body.refreshToken'] } });
  app.register(rateLimit, { max: 30, timeWindow: '1 minute' });
  app.get('/health', async () => ({ ok: true }));
  app.post('/v1/auth/apple/challenge', async (req, reply) => { const b = req.body as { installationId: string }; if (!b?.installationId) return reply.code(400).send({ error: 'invalid_request' }); return auth.challenge(b.installationId); });
  app.post('/v1/auth/apple', async (req, reply) => { try { return await auth.login(req.body as any); } catch (e) { return reply.code(401).send({ error: errorCode(e) }); } });
  app.post('/v1/auth/refresh', async (req, reply) => { try { return await auth.refresh((req.body as any).refreshToken); } catch (_) { return reply.code(401).send({ error: 'REFRESH_INVALID' }); } });
  app.post('/v1/auth/logout', async (req, reply) => { try { await auth.logout(req.headers.authorization); return reply.code(204).send(); } catch (_) { return reply.code(401).send({ error: 'UNAUTHORIZED' }); } });
  app.get('/v1/me', async (req, reply) => { try { const u = await auth.authenticate(req.headers.authorization); return { id: u.id, displayName: u.display_name, email: u.email }; } catch (e) { return reply.code(401).send({ error: e instanceof Error && e.message === 'ACCOUNT_NOT_FOUND' ? 'ACCOUNT_NOT_FOUND' : 'UNAUTHORIZED' }); } });
  app.get('/v1/me/storekit-context', async (req, reply) => { try { return await auth.storeKitContext(req.headers.authorization); } catch (_) { return reply.code(401).send({ error: 'UNAUTHORIZED' }); } });
  app.get('/v1/me/devices', async (req, reply) => { try { return { devices: await auth.devicesFor(req.headers.authorization) }; } catch (_) { return reply.code(401).send({ error: 'UNAUTHORIZED' }); } });
  app.delete('/v1/me/devices/:deviceId', async (req, reply) => { try { await auth.removeDevice(req.headers.authorization, (req.params as any).deviceId); return reply.code(204).send(); } catch (e) { return reply.code(e instanceof Error && e.message === 'DEVICE_NOT_FOUND' ? 404 : 401).send({ error: e instanceof Error ? e.message : 'UNAUTHORIZED' }); } });
  app.post('/v1/me/subscription/transactions', async (req, reply) => {
    if (!subscriptionService) return reply.code(503).send({ error: 'SUBSCRIPTION_NOT_CONFIGURED' });
    try { const u=await auth.authenticate(req.headers.authorization); const body=req.body as any; if(!body?.signedTransaction || typeof body.signedTransaction!=='string') return reply.code(400).send({error:'INVALID_REQUEST'}); return await withTransaction(tx=>subscriptionService!.confirm(tx,u,body.signedTransaction)); }
    catch(e) { const code=e instanceof Error?e.message:'SUBSCRIPTION_CONFIRM_FAILED'; const status=['subscriptionBoundToAnotherAccount','accountTokenMismatch','unboundPurchase','WRONG_PRODUCT'].includes(code)?409:400; return reply.code(status).send({error:code}); }
  });
  app.get('/v1/me/entitlement', async (req, reply) => {
    if (!subscriptionService) return reply.code(503).send({error:'SUBSCRIPTION_NOT_CONFIGURED'});
    try { const {user,deviceId}=await auth.authenticateContext(req.headers.authorization); const repo=(subscriptionService as any).subscriptions as PgSubscriptionRepository; const result=await withTransaction(async tx=>{const s=await repo.findCurrent(tx,user.id);const isPro=!!s&&PRO_STATES.has(s.status);const allowed=isPro?await (pgRepositories().devices as any).claimProSlot(tx,user.id,deviceId):false;return {s,isPro,allowed};}); const token=await subscriptionService.token({sub:user.id,device_id:deviceId,subscription_state:result.s?.status||'free',is_pro:result.isPro&&result.allowed,product_id:result.s?.product_id||null}); return {state:result.s?.status||'free',isPro:result.isPro&&result.allowed,planDisplayName:result.isPro?'PackageHub Pro':null,productId:result.s?.product_id||null,expiresAt:result.s?.expires_at?.toISOString?.()||null,autoRenewEnabled:result.s?.auto_renew_enabled??false,deviceAccess:result.isPro&&result.allowed?'allowed':result.isPro?'limitReached':'allowed',signedEntitlementToken:token||null}; }
    catch(_) { return reply.code(401).send({error:'UNAUTHORIZED'}); }
  });
  app.post('/v1/app-store/notifications', async (req, reply) => {
    if (!subscriptionService) return reply.code(503).send({error:'SUBSCRIPTION_NOT_CONFIGURED'});
    try { const body=req.body as any; if(!body?.signedPayload) return reply.code(400).send({error:'INVALID_REQUEST'}); const n=await subscriptionService['verifier'].verifyNotification(body.signedPayload); if(!n.notificationUUID) return reply.code(400).send({error:'INVALID_NOTIFICATION'}); const repo=(subscriptionService as any).subscriptions as PgSubscriptionRepository; await withTransaction(async tx=>{const data:any=n.data; const txInfo=data?.signedTransactionInfo?await subscriptionService!['verifier'].verifyTransaction(data.signedTransactionInfo):undefined; const fresh=await repo.markNotification(tx,{uuid:n.notificationUUID,type:n.notificationType||'UNKNOWN',subtype:n.subtype,original:txInfo?.originalTransactionId}); if(fresh && txInfo) {const existing=await repo.findByOriginal(tx,txInfo.originalTransactionId); if(existing) await subscriptionService!.reconcile(tx,existing.user_id,txInfo); await repo.setProcessed(tx,n.notificationUUID!);}}); return reply.code(200).send({}); }
    catch(_) { return reply.code(400).send({error:'INVALID_NOTIFICATION'}); }
  });
  app.delete('/v1/me', async (req, reply) => { try { await auth.delete(req.headers.authorization); return reply.code(204).send(); } catch (e) { return reply.code(409).send({ error: errorCode(e) }); } });
  return app;
}
