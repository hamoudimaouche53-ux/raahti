import { assertTransactionStatus, InvalidTransactionStatusException } from './transaction-status.vo';

describe('assertTransactionStatus', () => {
  it.each(['pending', 'authorized', 'captured', 'failed', 'refunded'])('accepts "%s"', (value) => {
    expect(() => assertTransactionStatus(value)).not.toThrow();
  });

  it('rejects an unrecognized value', () => {
    expect(() => assertTransactionStatus('bogus')).toThrow(InvalidTransactionStatusException);
  });
});
