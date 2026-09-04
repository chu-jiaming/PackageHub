import { createRemoteJWKSet, jwtVerify, JWTPayload } from 'jose';
const keys=createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
export interface AppleTokenVerifier { verify(token:string, nonce:string): Promise<JWTPayload & {sub:string}>; }
export class AppleJwtVerifier implements AppleTokenVerifier { constructor(private audience:string){} async verify(token:string,nonce:string){ const {payload}=await jwtVerify(token,keys,{issuer:'https://appleid.apple.com',audience:this.audience}); if(typeof payload.sub!=='string'||payload.nonce!==nonce) throw new Error('APPLE_TOKEN_INVALID'); return payload as JWTPayload & {sub:string}; } }
