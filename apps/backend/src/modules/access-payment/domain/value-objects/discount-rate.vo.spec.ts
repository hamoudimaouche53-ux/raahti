import { Money } from '../../../../shared-kernel';
import { DiscountRate, InvalidDiscountRateException } from './discount-rate.vo';

describe('DiscountRate', () => {
  it('accepts 0', () => {
    expect(DiscountRate.of(0).value).toBe(0);
  });

  it('accepts 100', () => {
    expect(DiscountRate.of(100).value).toBe(100);
  });

  it('accepts a mid-range value (FR-EMG-03 — 50%)', () => {
    expect(DiscountRate.of(50).value).toBe(50);
  });

  it('rejects a negative value', () => {
    expect(() => DiscountRate.of(-1)).toThrow(InvalidDiscountRateException);
  });

  it('rejects a value above 100', () => {
    expect(() => DiscountRate.of(101)).toThrow(InvalidDiscountRateException);
  });

  describe('applyTo', () => {
    it('halves the amount at 50%', () => {
      const discounted = DiscountRate.of(50).applyTo(Money.fromDecimalString('100.00', 'DZD'));
      expect(discounted.toDecimalString()).toBe('50.00');
    });

    it('leaves the amount unchanged at 0%', () => {
      const discounted = DiscountRate.of(0).applyTo(Money.fromDecimalString('75.50', 'DZD'));
      expect(discounted.toDecimalString()).toBe('75.50');
    });

    it('zeroes the amount at 100%', () => {
      const discounted = DiscountRate.of(100).applyTo(Money.fromDecimalString('75.50', 'DZD'));
      expect(discounted.toDecimalString()).toBe('0.00');
    });

    it('preserves currency', () => {
      const discounted = DiscountRate.of(10).applyTo(Money.fromDecimalString('100.00', 'DZD'));
      expect(discounted.currency).toBe('DZD');
    });
  });
});
