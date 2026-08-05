import { DomainException } from '../../../../shared-kernel';

/** ERD §3.14, domain-model.md §8. */
export type NotificationChannel = 'push' | 'in_app';

const VALID: readonly NotificationChannel[] = ['push', 'in_app'];

export class InvalidNotificationChannelException extends DomainException {
  readonly code = 'NOTIFICATIONS_INVALID_CHANNEL';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized notification channel (expected push|in_app).`);
  }
}

export function assertNotificationChannel(value: string): asserts value is NotificationChannel {
  if (!VALID.includes(value as NotificationChannel)) {
    throw new InvalidNotificationChannelException(value);
  }
}
