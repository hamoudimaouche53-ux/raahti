import { DomainException } from '../../../../shared-kernel';

/** ERD §3.14, domain-model.md §8. */
export type NotificationType = 'availability' | 'operator_alert' | 'payment_confirmation';

const VALID: readonly NotificationType[] = ['availability', 'operator_alert', 'payment_confirmation'];

export class InvalidNotificationTypeException extends DomainException {
  readonly code = 'NOTIFICATIONS_INVALID_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized notification type (expected availability|operator_alert|payment_confirmation).`);
  }
}

export function assertNotificationType(value: string): asserts value is NotificationType {
  if (!VALID.includes(value as NotificationType)) {
    throw new InvalidNotificationTypeException(value);
  }
}
