import { describe, expect, it } from 'vitest';
import { AuthService } from '../src/auth/auth_service.js';
describe('AuthService production composition contract',()=>{
  it('accepts explicit repository dependencies',()=>{
    expect(() => new AuthService({} as any, {} as any, 'test-jwt-secret-which-is-long-enough-32', Buffer.alloc(32), {} as any)).not.toThrow();
  });
});
