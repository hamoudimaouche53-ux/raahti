import { Money } from '../../../../shared-kernel';
import { InvalidTransactionStatusTransitionException, Transaction } from './transaction.entity';

function pendingTransaction() {
  return Transaction.pending({
    id: 't1',
    userId: 'u1',
    accessSessionId: 'as1',
    paymentMethodId: 'pm1',
    amount: Money.fromDecimalString('50.00', 'DZD'),
  });
}

describe('Transaction', () => {
  it('starts pending, with no providerRef', () => {
    const transaction = pendingTransaction();
    expect(transaction.status).toBe('pending');
    expect(transaction.providerRef).toBeNull();
    expect(transaction.amount.toDecimalString()).toBe('50.00');
  });

  describe('authorize', () => {
    it('allows pending -> authorized, recording the providerRef', () => {
      const transaction = pendingTransaction();
      transaction.authorize('prov-auth-123');
      expect(transaction.status).toBe('authorized');
      expect(transaction.providerRef).toBe('prov-auth-123');
    });
  });

  describe('capture', () => {
    it('allows authorized -> captured', () => {
      const transaction = pendingTransaction();
      transaction.authorize('prov-auth-123');
      transaction.capture();
      expect(transaction.status).toBe('captured');
    });
  });

  describe('fail', () => {
    it('allows pending -> failed', () => {
      const transaction = pendingTransaction();
      transaction.fail();
      expect(transaction.status).toBe('failed');
    });

    it('allows authorized -> failed', () => {
      const transaction = pendingTransaction();
      transaction.authorize('prov-auth-123');
      transaction.fail();
      expect(transaction.status).toBe('failed');
    });
  });

  describe('refund', () => {
    it('allows captured -> refunded (Risk R-12 path)', () => {
      const transaction = pendingTransaction();
      transaction.authorize('prov-auth-123');
      transaction.capture();
      transaction.refund();
      expect(transaction.status).toBe('refunded');
    });
  });

  describe('illegal transitions', () => {
    it('rejects pending -> captured (must authorize first)', () => {
      const transaction = pendingTransaction();
      expect(() => transaction.capture()).toThrow(InvalidTransactionStatusTransitionException);
    });

    it('rejects pending -> refunded', () => {
      const transaction = pendingTransaction();
      expect(() => transaction.refund()).toThrow(InvalidTransactionStatusTransitionException);
    });

    it('rejects authorized -> refunded (must capture first)', () => {
      const transaction = pendingTransaction();
      transaction.authorize('prov-auth-123');
      expect(() => transaction.refund()).toThrow(InvalidTransactionStatusTransitionException);
    });

    it('rejects any transition once failed', () => {
      const transaction = pendingTransaction();
      transaction.fail();
      expect(() => transaction.authorize('x')).toThrow(InvalidTransactionStatusTransitionException);
    });

    it('rejects any transition once refunded', () => {
      const transaction = pendingTransaction();
      transaction.authorize('prov-auth-123');
      transaction.capture();
      transaction.refund();
      expect(() => transaction.capture()).toThrow(InvalidTransactionStatusTransitionException);
    });
  });
});
