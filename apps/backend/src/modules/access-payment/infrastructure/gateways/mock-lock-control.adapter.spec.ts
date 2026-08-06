import { MockLockControlAdapter } from './mock-lock-control.adapter';

describe('MockLockControlAdapter', () => {
  it('unlocks deterministically by default', async () => {
    const gateway = new MockLockControlAdapter();
    const result = await gateway.issueUnlockOrder({ cabinId: 'c1', accessSessionId: 'as1' });
    expect(result.result).toBe('unlocked');
    expect(result.acknowledgedAt).not.toBeNull();
  });

  it('fails deterministically when configured with outcome=failed', async () => {
    const gateway = new MockLockControlAdapter({ outcome: 'failed' });
    const result = await gateway.issueUnlockOrder({ cabinId: 'c1', accessSessionId: 'as1' });
    expect(result.result).toBe('failed');
    expect(result.acknowledgedAt).toBeNull();
  });
});
