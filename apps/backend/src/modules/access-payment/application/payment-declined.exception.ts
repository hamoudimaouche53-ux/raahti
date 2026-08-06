import { DomainException } from '../../../shared-kernel';

export class PaymentDeclinedException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_PAYMENT_DECLINED';
  readonly status = 402;

  constructor(accessSessionId: string) {
    super(`Payment for access session ${accessSessionId} was declined.`);
  }
}
