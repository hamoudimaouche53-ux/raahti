import { DomainException } from '../../../shared-kernel';

/**
 * Also thrown when a notification exists but belongs to a different user —
 * PATCH /users/me/notifications/{id} must not confirm another user's
 * notification ID exists (404, not 403).
 */
export class NotificationNotFoundException extends DomainException {
  readonly code = 'NOTIFICATIONS_NOTIFICATION_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Notification ${id} was not found.`);
  }
}
