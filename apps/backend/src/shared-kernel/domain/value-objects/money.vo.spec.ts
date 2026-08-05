import { CurrencyMismatchException, InvalidMoneyException, Money } from './money.vo';

describe('Money', () => {
  it('round-trips a decimal string without floating-point drift', () => {
    const money = Money.fromDecimalString('150.00', 'DZD');
    expect(money.toDecimalString()).toBe('150.00');
  });

  it('handles single-decimal input by padding to 2dp', () => {
    expect(Money.fromDecimalString('10.5', 'DZD').toDecimalString()).toBe('10.50');
  });

  it('handles whole-number input', () => {
    expect(Money.fromDecimalString('10', 'DZD').toDecimalString()).toBe('10.00');
  });

  it('adds two amounts in the same currency', () => {
    const a = Money.fromDecimalString('10.10', 'DZD');
    const b = Money.fromDecimalString('0.05', 'DZD');
    expect(a.add(b).toDecimalString()).toBe('10.15');
  });

  it('rejects addition across different currencies', () => {
    const dzd = Money.fromDecimalString('10.00', 'DZD');
    const eur = Money.fromDecimalString('10.00', 'EUR');
    expect(() => dzd.add(eur)).toThrow(CurrencyMismatchException);
  });

  it('rejects a malformed decimal amount', () => {
    expect(() => Money.fromDecimalString('10.999', 'DZD')).toThrow(InvalidMoneyException);
    expect(() => Money.fromDecimalString('abc', 'DZD')).toThrow(InvalidMoneyException);
  });

  it('rejects a non-ISO-4217-shaped currency code', () => {
    expect(() => Money.fromDecimalString('10.00', 'DZ')).toThrow(InvalidMoneyException);
  });

  it('treats equal amount+currency as equal', () => {
    const a = Money.fromDecimalString('10.00', 'DZD');
    const b = Money.fromDecimalString('10.00', 'dzd');
    expect(a.equals(b)).toBe(true);
  });
});
