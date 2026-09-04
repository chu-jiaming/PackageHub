import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { pool } from '../../src/db/pool.js';
import { requireDb, withTransaction, pgRepositories } from '../../src/db/repositories.js';
import { PgSubscriptionRepository, SubscriptionService } from '../../src/subscription/entitlement.js';
import type { VerifiedTransaction } from '../../src/subscription/apple.js';

const token='00000000-0000-4000-8000-000000000099';
class FakeVerifier { async verifyTransaction(_:string):Promise<VerifiedTransaction>{return {transactionId:'t-1',originalTransactionId:'o-1',productId:process.env.PACKAGEHUB_PRO_PRODUCT_ID||'packagehub.pro',appAccountToken:token,environment:'Sandbox',expiresDate:Date.now()+86400000};} async verifyNotification(){throw new Error('not used');} async verifyRenewal(){return {};} }
class FakeServer { async getAllSubscriptionStatuses(){return {data:[]};} }
describe.skipIf(!process.env.TEST_DATABASE_URL)('PostgreSQL subscription persistence',()=>{
  let userA:string,userB:string; const subscriptions=new PgSubscriptionRepository();
  beforeAll(async()=>{const db=requireDb(); await db.query("INSERT INTO users(apple_subject,app_account_token) VALUES('subscription-a',$1),('subscription-b','00000000-0000-4000-8000-000000000098') RETURNING id",[token]).then(r=>{userA=r.rows[0].id;userB=r.rows[1].id;});});
  afterAll(async()=>{await pool?.end();});
  it('binds matching token, is idempotent, and rejects another user',async()=>{const s=new SubscriptionService(new FakeVerifier() as any,new FakeServer() as any,subscriptions);const first=await withTransaction(tx=>s.confirm(tx,{id:userA,app_account_token:token},'signed'));expect(first.result).toBe('accepted');const same=await withTransaction(tx=>s.confirm(tx,{id:userA,app_account_token:token},'signed'));expect(same.result).toBe('alreadyBoundSameAccount');const other=await withTransaction(tx=>s.confirm(tx,{id:userB,app_account_token:'00000000-0000-4000-8000-000000000098'},'signed'));expect(other.result).toBe('subscriptionBoundToAnotherAccount');});
  it('enforces two Pro devices under concurrent claims',async()=>{const devices=pgRepositories().devices;const ids=[] as string[];for(const i of [1,2,3])ids.push((await devices.upsertByUserAndInstallation(requireDb(),userA,`00000000-0000-4000-8000-00000000000${i}`,'ios',`device-${i}`,'test')).id);await withTransaction(tx=>devices.claimProSlot(tx,userA,ids[0]));await withTransaction(tx=>devices.revoke(tx,ids[1]));const results=await Promise.all(ids.slice(1).map(id=>withTransaction(tx=>devices.claimProSlot(tx,userA,id))));expect(results.filter(Boolean)).toHaveLength(1);const count=await requireDb().query('SELECT count(*)::int AS count FROM devices WHERE user_id=$1 AND pro_access_granted_at IS NOT NULL AND pro_access_revoked_at IS NULL',[userA]);expect(count.rows[0].count).toBeLessThanOrEqual(2);});
});
