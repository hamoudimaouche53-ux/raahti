import { EmergencyDiscountPolicy } from './emergency-discount-policy';

describe('EmergencyDiscountPolicy', () => {
  it('is eligible only when diabeticVerificationStatus is verified', () => {
    expect(EmergencyDiscountPolicy.isEligible('verified')).toBe(true);
  });

  it.each(['none', 'pending', 'rejected'] as const)('is not eligible for status "%s"', (status) => {
    expect(EmergencyDiscountPolicy.isEligible(status)).toBe(false);
  });
});
