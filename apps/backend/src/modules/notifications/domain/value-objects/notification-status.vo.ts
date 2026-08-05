import { DomainException } from '../../../../shared-kernel';

/** ERD §3.14. Delivery lifecycle — cross-cutting-architecture.md's "NotificationQueued → Sent → Delivered/Failed state machine". */
export type NotificationStatus = 'queued' | 'sent' | 'delivered' | 'failed';

const VALID: readonly NotificationStatus[] = ['queued', 'sent', 'delivered', 'failed'];

export class InvalidNotificationStatusException extends DomainException {
  readonly code = 'NOTIFICATIONS_INVALID_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized notification status (expected queued|sent|delivered|failed).`);
  }
}

export function assertNotificationStatus(value: string): asserts value is NotificationStatus {
  if (!VALID.includes(value as NotificationStatus)) {
    throw new InvalidNotificationStatusException(value);
  }
}
