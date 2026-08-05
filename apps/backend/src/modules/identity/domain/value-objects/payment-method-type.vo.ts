import { DomainException } from '../../../../shared-kernel';

export type PaymentMethodType = 'card' | 'mobile_wallet' | 'subscription';

const VALID_TYPES: readonly PaymentMethodType[] = ['card', 'mobile_wallet', 'subscription'];

export class InvalidPaymentMethodTypeException extends DomainException {
  readonly code = 'IDENTITY_INVALID_PAYMENT_METHOD_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized payment method type (expected card|mobile_wallet|subscription).`);
  }
}

export function assertPaymentMethodType(value: string): asserts value is PaymentMethodType {
  if (!VALID_TYPES.includes(value as PaymentMethodType)) {
    throw new InvalidPaymentMethodTypeException(value);
  }
}
