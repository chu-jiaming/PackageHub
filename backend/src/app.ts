import Fastify from 'fastify';
import rateLimit from '@fastify/rate-limit';
import { Buffer } from 'node:buffer';
import { AuthService } from './auth/auth_service.js';
import { AppleJwtVerifier } from './auth/apple_token_verifier.js';
import { AppleHttpTokenExchange } from './auth/apple_token_exchange.js';
import { pgRepositories } from './db/repositories.js';

const errorCode = (e: unknown) => e instanceof Error && /^(AUTH_|REFRESH_|APPLE_)/.test(e.message) ? e.message : 'REQUEST_FAILED';

export function createApp(service?: AuthService) {
  const clientId = process.env.APPLE_CLIENT_ID || 'com.charm1ng.packagehub';
  const config = process.env.APPLE_TEAM_ID && process.env.APPLE_KEY_ID && process.env.APPLE_PRIVATE_KEY ? { teamId: process.env.APPLE_TEAM_ID, keyId: process.env.APPLE_KEY_ID, clientId, privateKey: process.env.APPLE_PRIVATE_KEY } : undefined;
  const secret = process.env.SESSION_JWT_SECRET || 'local-development-secret-change-me-32chars';
  const encryptionKey = Buffer.from(process.env.TOKEN_ENCRYPTION_KEY || 'local-development-encryption-key-32', 'utf8').subarray(0, 32);
  const auth = service ?? new AuthService(new AppleJwtVerifier(clientId), new AppleHttpTokenExchange(config), secret, encryptionKey, pgRepositories());
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
  app.delete('/v1/me', async (req, reply) => { try { await auth.delete(req.headers.authorization); return reply.code(204).send(); } catch (e) { return reply.code(409).send({ error: errorCode(e) }); } });
  return app;
}
