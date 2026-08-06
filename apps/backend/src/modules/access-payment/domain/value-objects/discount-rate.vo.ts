import { DomainException, Money } from '../../../../shared-kernel';

export class InvalidDiscountRateException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_INVALID_DISCOUNT_RATE';
  readonly status = 400;

  constructor(value: number) {
    super(`Discount rate ${value} is out of range (expected 0-100).`);
  }
}

/**
 * Percentage discount (Domain Model §6 value object list) — persists as
 * `transaction.discount_applied` (ERD §3.10, FR-EMG-03's Mode Urgence 50%
 * discount). Built for domain completeness now; NOT wired into
 * `AuthorizeAndCapturePaymentService` this pass — see that service's doc
 * comment for why `applyEmergencyDiscount` is accepted but currently inert.
 * `applyTo` works against the codebase's existing `Money` VO (shared-kernel)
 * rather than a raw `Decimal`/`number` — `Money` has no built-in multiply
 * (only `add`/`equals`), so this performs the percentage arithmetic via
 * `Money`'s own decimal-string parse/format boundary rather than reaching
 * into its private minor-units representation.
 */
export class DiscountRate {
  private constructor(private readonly percent: number) {}

  static of(percent: number): DiscountRate {
    if (percent < 0 || percent > 100) {
      throw new InvalidDiscountRateException(percent);
    }
    return new DiscountRate(percent);
  }

  get value(): number {
    return this.percent;
  }

  applyTo(amount: Money): Money {
    const original = Number(amount.toDecimalString());
    const discounted = Math.round(original * (1 - this.percent / 100) * 100) / 100;
    return Money.fromDecimalString(discounted.toFixed(2), amount.currency);
  }
}
