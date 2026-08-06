import type { DiabeticVerificationStatus } from '../../../identity/domain/value-objects/diabetic-verification-status.vo';

/**
 * FR-EMG-03 — Mode Urgence yields a discount only for a diabetic-verified
 * usager (Domain Model §7 invariant: "yields a non-zero discount only when
 * User.diabeticVerificationStatus = verified"). 50% duplicated here rather
 * than shared-kernel'd — AccessPaymentModule independently re-implements the
 * same one-line check server-side at payment time rather than importing this
 * class (see ADR-0031: EmergencyModule has no sanctioned incoming edge from
 * any module, module-dependency-diagram.md §3, so nothing may depend on it —
 * this pass's own documented judgment call, not an oversight).
 */
const EMERGENCY_DISCOUNT_PERCENTAGE = 50; // FR-EMG-03

export class EmergencyDiscountPolicy {
  static readonly DISCOUNT_PERCENTAGE = EMERGENCY_DISCOUNT_PERCENTAGE;

  static isEligible(status: DiabeticVerificationStatus): boolean {
    return status === 'verified';
  }
}
