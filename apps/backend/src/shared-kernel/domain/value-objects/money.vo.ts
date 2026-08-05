import { DomainException } from '../domain-exception';

export class InvalidMoneyException extends DomainException {
  readonly code = 'SHARED_KERNEL_INVALID_MONEY';
  readonly status = 400;

  constructor(message: string) {
    super(message);
  }
}

export class CurrencyMismatchException extends DomainException {
  readonly code = 'SHARED_KERNEL_CURRENCY_MISMATCH';
  readonly status = 400;

  constructor(a: string, b: string) {
    super(`Cannot combine amounts in different currencies: ${a} vs ${b}.`);
  }
}

const DECIMAL_AMOUNT = /^-?\d+(\.\d{1,2})?$/;

/**
 * Monetary amount (Domain Model §6). Stored as integer minor units (cents) internally
 * to avoid the floating-point rounding error api-architecture.md §4 explicitly calls
 * out — transport represents it as a decimal string, this VO is the parse/format
 * boundary. Assumes 2-decimal-subunit currencies (DZD, the only currency in scope
 * per the current docs) — noted as a scope-limited judgment call, not a documented
 * requirement, should a 0- or 3-decimal currency ever be introduced.
 */
export class Money {
  private constructor(
    private readonly minorUnits: bigint,
    readonly currency: string,
  ) {}

  static fromDecimalString(amount: string, currency: string): Money {
    if (!DECIMAL_AMOUNT.test(amount)) {
      throw new InvalidMoneyException(`"${amount}" is not a valid decimal amount.`);
    }
    if (!currency || currency.length !== 3) {
      throw new InvalidMoneyException(`"${currency}" is not a valid ISO 4217 currency code.`);
    }
    const [whole, fraction = ''] = amount.split('.');
    const paddedFraction = fraction.padEnd(2, '0');
    const minorUnits = BigInt(whole) * 100n + BigInt(paddedFraction) * (whole.startsWith('-') ? -1n : 1n);
    return new Money(minorUnits, currency.toUpperCase());
  }

  toDecimalString(): string {
    const negative = this.minorUnits < 0n;
    const abs = negative ? -this.minorUnits : this.minorUnits;
    const whole = abs / 100n;
    const fraction = (abs % 100n).toString().padStart(2, '0');
    return `${negative ? '-' : ''}${whole}.${fraction}`;
  }

  add(other: Money): Money {
    if (other.currency !== this.currency) {
      throw new CurrencyMismatchException(this.currency, other.currency);
    }
    return new Money(this.minorUnits + other.minorUnits, this.currency);
  }

  equals(other: Money): boolean {
    return this.currency === other.currency && this.minorUnits === other.minorUnits;
  }
}
