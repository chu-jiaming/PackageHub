import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { encryptToken, decryptToken } from '../src/security/encryption.js';
describe('account foundation',()=>{
  it('encrypts and authenticates Apple tokens',()=>{const key=Buffer.alloc(32,7);const value=encryptToken('refresh-secret',key);expect(decryptToken(value,key)).toBe('refresh-secret');});
  it('health is intentionally minimal',async()=>{const r=await createApp().inject({method:'GET',url:'/health'});expect(r.statusCode).toBe(200);expect(r.json()).toEqual({ok:true});});
});
