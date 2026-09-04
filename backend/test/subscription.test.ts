import { describe, expect, it } from 'vitest';
import { mapAppleStatus, PRO_STATES } from '../src/subscription/entitlement.js';

describe('server entitlement mapping', () => {
  it.each([[1, 'active'], [2, 'expired'], [3, 'billingRetry'], [4, 'gracePeriod']])('maps Apple status %s', (status, expected) => {
    expect(mapAppleStatus(status)).toBe(expected);
  });
  it('keeps revoked and expiry authoritative', () => {
    expect(mapAppleStatus(1, new Date(Date.now() + 1000), new Date())).toBe('revoked');
    expect(mapAppleStatus(1, new Date(Date.now() - 1000))).toBe('expired');
  });
  it('only active lifecycle states are Pro', () => {
    expect([...PRO_STATES]).toEqual(expect.arrayContaining(['active', 'trial', 'gracePeriod', 'billingRetry']));
    expect(PRO_STATES.has('expired')).toBe(false);
  });
});
