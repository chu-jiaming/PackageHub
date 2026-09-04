import { SignJWT, importPKCS8 } from 'jose';
import type { DbExecutor, DbRow } from '../db/repositories.js';
import { withTransaction } from '../db/repositories.js';
import type { AppStoreServerClient, AppStoreSignedDataVerifier, VerifiedTransaction } from './apple.js';

export const PRO_STATES = new Set(['active','trial','gracePeriod','billingRetry']);
export type BindingResult = 'accepted'|'alreadyProcessed'|'alreadyBoundSameAccount'|'subscriptionBoundToAnotherAccount'|'unboundPurchase'|'accountTokenMismatch';
export const mapAppleStatus = (status: number|undefined, expiresAt?: Date|null, revokedAt?: Date|null) => revokedAt ? 'revoked' : status === 4 ? 'gracePeriod' : status === 3 ? 'billingRetry' : status === 2 ? 'expired' : expiresAt && expiresAt <= new Date() ? 'expired' : 'active';

export interface SubscriptionRepository {
  findByOriginal(db: DbExecutor, original: string): Promise<DbRow|null>;
  findCurrent(db: DbExecutor, userId: string): Promise<DbRow|null>;
  upsert(db: DbExecutor, value: Record<string, any>): Promise<DbRow>;
  markNotification(db: DbExecutor, n: Record<string, any>): Promise<boolean>;
  setProcessed(db: DbExecutor, uuid: string): Promise<void>;
  deleteByUser(db: DbExecutor, userId: string): Promise<void>;
}
export class PgSubscriptionRepository implements SubscriptionRepository {
  async findByOriginal(db: DbExecutor,o: string){const row=(await db.query('SELECT * FROM subscriptions WHERE original_transaction_id=$1',[o])).rows[0]??null;if(row)return row;const tombstone=(await db.query('SELECT original_transaction_id FROM subscription_binding_tombstones WHERE original_transaction_id=$1',[o])).rows[0];return tombstone?{deleted_binding:true,original_transaction_id:o}:null;}
  async findCurrent(db: DbExecutor,u: string){return (await db.query("SELECT * FROM subscriptions WHERE user_id=$1 ORDER BY (status IN ('active','trial','gracePeriod','billingRetry')) DESC, expires_at DESC NULLS LAST LIMIT 1",[u])).rows[0]??null;}
  async upsert(db: DbExecutor,v: Record<string,any>){return (await db.query(`INSERT INTO subscriptions(user_id,original_transaction_id,product_id,app_account_token,environment,status,latest_transaction_id,expires_at,auto_renew_enabled,revoked_at,last_reconciled_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,now()) ON CONFLICT(original_transaction_id) DO UPDATE SET product_id=EXCLUDED.product_id,environment=EXCLUDED.environment,status=EXCLUDED.status,latest_transaction_id=EXCLUDED.latest_transaction_id,expires_at=EXCLUDED.expires_at,auto_renew_enabled=EXCLUDED.auto_renew_enabled,revoked_at=EXCLUDED.revoked_at,last_reconciled_at=now(),updated_at=now() RETURNING *`,[v.userId,v.originalTransactionId,v.productId,v.appAccountToken,v.environment,v.status,v.latestTransactionId,v.expiresAt,v.autoRenewEnabled,v.revokedAt])).rows[0];}
  async markNotification(db: DbExecutor,n: Record<string,any>){try{await db.query('INSERT INTO app_store_notification_events(notification_uuid,notification_type,notification_subtype,original_transaction_id) VALUES($1,$2,$3,$4)',[n.uuid,n.type,n.subtype,n.original]);return true;}catch(e:any){if(e.code==='23505')return false;throw e;}}
  async setProcessed(db: DbExecutor,u: string){await db.query('UPDATE app_store_notification_events SET processed_at=now() WHERE notification_uuid=$1',[u]);}
  async deleteByUser(db: DbExecutor,u: string){await db.query('DELETE FROM subscriptions WHERE user_id=$1',[u]);}
}
export class SubscriptionService {
  constructor(private readonly verifier: AppStoreSignedDataVerifier, private readonly server: AppStoreServerClient, private readonly subscriptions: SubscriptionRepository, private readonly signingKey?: string, private readonly signingKid='local') {}
  async confirm(db: DbExecutor, user: DbRow, signed: string): Promise<{result: BindingResult; subscription?: DbRow}> {
    const tx = await this.verifier.verifyTransaction(signed);
    if(tx.productId !== (process.env.PACKAGEHUB_PRO_PRODUCT_ID || 'packagehub.pro')) throw new Error('WRONG_PRODUCT');
    if(!tx.appAccountToken) return {result:'unboundPurchase'};
    if(tx.appAccountToken !== user.app_account_token) return {result:'accountTokenMismatch'};
    const existing=await this.subscriptions.findByOriginal(db,tx.originalTransactionId);
    if(existing && existing.user_id !== user.id) return {result:'subscriptionBoundToAnotherAccount'};
    const subscription=await this.reconcile(db,user.id,tx);
    return {result:existing?'alreadyBoundSameAccount':'accepted',subscription};
  }
  async reconcile(db: DbExecutor, userId: string, tx: VerifiedTransaction) {
    let statusResponse; try { statusResponse=await this.server.getAllSubscriptionStatuses(tx.originalTransactionId); } catch { statusResponse=undefined; }
    const item=statusResponse?.data?.flatMap(x=>x.lastTransactions ?? []).find(x=>x?.signedTransactionInfo) as any;
    let latest=tx; let status:number|undefined; let renewal:any;
    if(item?.signedTransactionInfo) { latest=await this.verifier.verifyTransaction(item.signedTransactionInfo); status=typeof item.status==='number'?item.status:undefined; }
    if(item?.signedRenewalInfo) renewal=await this.verifier.verifyRenewal(item.signedRenewalInfo);
    return this.subscriptions.upsert(db,{userId,originalTransactionId:latest.originalTransactionId,productId:latest.productId,appAccountToken:latest.appAccountToken,environment:latest.environment,status:mapAppleStatus(status,latest.expiresDate?new Date(latest.expiresDate):null,latest.revocationDate?new Date(latest.revocationDate):null),latestTransactionId:latest.transactionId,expiresAt:latest.expiresDate?new Date(latest.expiresDate):null,autoRenewEnabled:renewal?.autoRenewStatus===1,revokedAt:latest.revocationDate?new Date(latest.revocationDate):null});
  }
  async token(claims: Record<string,any>) { if(!this.signingKey) return undefined; const key=await importPKCS8(this.signingKey,'ES256'); return new SignJWT(claims).setProtectedHeader({alg:'ES256',kid:this.signingKid}).setIssuer('packagehub').setIssuedAt().setExpirationTime(`${process.env.ENTITLEMENT_TTL_HOURS||48}h`).sign(key); }
}
