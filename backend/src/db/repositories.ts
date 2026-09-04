import type { PoolClient } from 'pg';
import { pool } from './pool.js';

export class PostgreSQLAccountRepositories {
  async withTransaction<T>(work:(client:PoolClient)=>Promise<T>):Promise<T>{if(!pool)throw new Error('DATABASE_NOT_CONFIGURED');const client=await pool.connect();try{await client.query('BEGIN');const value=await work(client);await client.query('COMMIT');return value;}catch(e){await client.query('ROLLBACK');throw e;}finally{client.release();}}
  async findUserByAppleSubject(client:PoolClient,subject:string){const r=await client.query('SELECT id,display_name,email,app_account_token FROM users WHERE apple_subject=$1',[subject]);return r.rows[0]??null;}
  async createUser(client:PoolClient,subject:string,displayName:string|null,email:string|null){const r=await client.query('INSERT INTO users(apple_subject,display_name,email) VALUES($1,$2,$3) RETURNING id,display_name,email,app_account_token',[subject,displayName,email]);return r.rows[0];}
  async updateProfileIfMissing(client:PoolClient,id:string,displayName:string|null,email:string|null){return client.query('UPDATE users SET display_name=COALESCE(display_name,$2),email=COALESCE(email,$3),updated_at=now() WHERE id=$1',[id,displayName,email]);}
  async upsertDevice(client:PoolClient,userId:string,installationId:string,platform:string,label:string,version?:string){const r=await client.query('INSERT INTO devices(user_id,installation_id,platform,device_label,app_version) VALUES($1,$2,$3,$4,$5) ON CONFLICT(user_id,installation_id) DO UPDATE SET last_seen_at=now() RETURNING *',[userId,installationId,platform,label,version]);return r.rows[0];}
  async listDevices(client:PoolClient,userId:string){return (await client.query('SELECT id,installation_id,platform,device_label,app_version,last_seen_at FROM devices WHERE user_id=$1 AND revoked_at IS NULL ORDER BY last_seen_at DESC',[userId])).rows;}
  async findSession(client:PoolClient,hash:string){return (await client.query('SELECT * FROM sessions WHERE refresh_token_hash=$1 AND revoked_at IS NULL AND expires_at>now()',[hash])).rows[0]??null;}
  async revokeSession(client:PoolClient,id:string){await client.query('UPDATE sessions SET revoked_at=now() WHERE id=$1',[id]);}
  async deleteUser(client:PoolClient,id:string){await client.query('DELETE FROM users WHERE id=$1',[id]);}
}
