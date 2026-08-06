import { AccessSession, InvalidAccessSessionStatusTransitionException } from './access-session.entity';

function initiateSession() {
  return AccessSession.initiate({ id: 'as1', cabinId: 'c1', userId: 'u1', qrCodeScanned: 'c1' });
}

describe('AccessSession', () => {
  it('starts initiated, with no unlockedAt/closedAt', () => {
    const session = initiateSession();
    expect(session.status).toBe('initiated');
    expect(session.unlockedAt).toBeNull();
    expect(session.closedAt).toBeNull();
    expect(session.cabinId).toBe('c1');
    expect(session.userId).toBe('u1');
  });

  describe('markPaymentPending', () => {
    it('allows initiated -> payment_pending (paid cabin path)', () => {
      const session = initiateSession();
      session.markPaymentPending();
      expect(session.status).toBe('payment_pending');
    });
  });

  describe('markUnlocked', () => {
    it('allows initiated -> unlocked directly (free cabin path)', () => {
      const session = initiateSession();
      session.markUnlocked();
      expect(session.status).toBe('unlocked');
      expect(session.unlockedAt).not.toBeNull();
    });

    it('allows payment_pending -> unlocked (paid cabin, after capture)', () => {
      const session = initiateSession();
      session.markPaymentPending();
      session.markUnlocked();
      expect(session.status).toBe('unlocked');
    });
  });

  describe('markInUse', () => {
    it('allows unlocked -> in_use', () => {
      const session = initiateSession();
      session.markUnlocked();
      session.markInUse();
      expect(session.status).toBe('in_use');
    });
  });

  describe('complete', () => {
    it('allows unlocked -> completed directly (manual "J\'ai terminé", ADR-0030)', () => {
      const session = initiateSession();
      session.markUnlocked();
      session.complete();
      expect(session.status).toBe('completed');
      expect(session.closedAt).not.toBeNull();
    });

    it('allows in_use -> completed', () => {
      const session = initiateSession();
      session.markUnlocked();
      session.markInUse();
      session.complete();
      expect(session.status).toBe('completed');
    });
  });

  describe('cancel', () => {
    it('allows initiated -> cancelled', () => {
      const session = initiateSession();
      session.cancel();
      expect(session.status).toBe('cancelled');
    });

    it('allows payment_pending -> cancelled', () => {
      const session = initiateSession();
      session.markPaymentPending();
      session.cancel();
      expect(session.status).toBe('cancelled');
    });
  });

  describe('illegal transitions', () => {
    it('rejects initiated -> in_use', () => {
      const session = initiateSession();
      expect(() => session.markInUse()).toThrow(InvalidAccessSessionStatusTransitionException);
    });

    it('rejects unlocked -> payment_pending', () => {
      const session = initiateSession();
      session.markUnlocked();
      expect(() => session.markPaymentPending()).toThrow(InvalidAccessSessionStatusTransitionException);
    });

    it('rejects unlocked -> cancelled', () => {
      const session = initiateSession();
      session.markUnlocked();
      expect(() => session.cancel()).toThrow(InvalidAccessSessionStatusTransitionException);
    });

    it('rejects any transition once completed', () => {
      const session = initiateSession();
      session.markUnlocked();
      session.complete();
      expect(() => session.markInUse()).toThrow(InvalidAccessSessionStatusTransitionException);
    });

    it('rejects any transition once cancelled', () => {
      const session = initiateSession();
      session.cancel();
      expect(() => session.markUnlocked()).toThrow(InvalidAccessSessionStatusTransitionException);
    });
  });
});
