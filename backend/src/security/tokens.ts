import { createHash, randomBytes } from 'node:crypto';
import { SignJWT } from 'jose';
export const hashToken=(v:string)=>createHash('sha256').update(v).digest('hex');
export const newRefreshToken=()=>randomBytes(48).toString('base64url');
export async function accessToken(userId:string, sessionId:string, deviceId:string, secret:string) { return new SignJWT({session_id:sessionId,device_id:deviceId}).setProtectedHeader({alg:'HS256'}).setSubject(userId).setIssuedAt().setExpirationTime('15m').sign(Buffer.from(secret)); }
