import { Injectable } from '@nestjs/common';
import { Notification } from '../../domain/entities/notification.entity';
import { NotificationCopy, NotificationSender } from './notification-sender.port';

/**
 * "Delivery" for the in-app channel is trivial by construction — the
 * persisted Notification row IS the delivery mechanism (read via
 * GET /users/me/notifications, cross-cutting-architecture.md). No external
 * system involved, so this always succeeds.
 */
@Injectable()
export class InAppNotificationSender implements NotificationSender {
  async send(_notification: Notification, _copy: NotificationCopy): Promise<void> {
    // No-op: nothing to dispatch. The row already exists once queued.
  }
}
