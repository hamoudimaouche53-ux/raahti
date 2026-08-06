import { InvalidQrCodeException, QrCode } from './qr-code.vo';

const VALID_UUID = '550e8400-e29b-41d4-a716-446655440000';

describe('QrCode', () => {
  it('accepts a non-empty string', () => {
    expect(QrCode.of(VALID_UUID).raw).toBe(VALID_UUID);
  });

  it('rejects an empty string', () => {
    expect(() => QrCode.of('')).toThrow(InvalidQrCodeException);
  });

  it('rejects a whitespace-only string', () => {
    expect(() => QrCode.of('   ')).toThrow(InvalidQrCodeException);
  });

  it('rejects a payload longer than 500 characters', () => {
    expect(() => QrCode.of('a'.repeat(501))).toThrow(InvalidQrCodeException);
  });

  it('accepts a payload at exactly 500 characters', () => {
    // Not a UUID, so QrCode.of() itself succeeds (length-only check) — toCabinId() would separately reject it.
    expect(() => QrCode.of('a'.repeat(500))).not.toThrow();
  });

  describe('toCabinId', () => {
    it('returns the value when it is a well-formed UUID', () => {
      expect(QrCode.of(VALID_UUID).toCabinId()).toBe(VALID_UUID);
    });

    it('throws when the payload is not a UUID', () => {
      expect(() => QrCode.of('not-a-uuid').toCabinId()).toThrow(InvalidQrCodeException);
    });
  });
});
