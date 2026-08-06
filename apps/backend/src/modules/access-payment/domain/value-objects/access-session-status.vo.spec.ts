import { assertAccessSessionStatus, InvalidAccessSessionStatusException } from './access-session-status.vo';

describe('assertAccessSessionStatus', () => {
  it.each(['initiated', 'payment_pending', 'unlocked', 'in_use', 'completed', 'cancelled'])(
    'accepts "%s"',
    (value) => {
      expect(() => assertAccessSessionStatus(value)).not.toThrow();
    },
  );

  it('rejects an unrecognized value', () => {
    expect(() => assertAccessSessionStatus('bogus')).toThrow(InvalidAccessSessionStatusException);
  });
});
