import { Injectable } from '@nestjs/common';
import { Notification } from '../../domain/entities/notification.entity';
import { NotificationCopy, NotificationSender } from './notification-sender.port';

export class PushNotificationNotConfiguredException extends Error {
  constructor() {
    super(
      'Push notification delivery is not configured: no FCM/APNs credentials exist in this ' +
        'environment, and no device-token storage is modeled anywhere in the ERD/domain model ' +
        '(there is nowhere to look up which device to target). Documented placeholder, same ' +
        'precedent as ADR-0014\'s payment-provider mock adapter — "do not introduce infrastructure ' +
        'beyond current project scope".',
    );
  }
}

/**
 * Placeholder adapter — FCM (Android) / APNs (iOS) integration is out of
 * scope for this pass: no real credentials exist, and there is no
 * device-token field anywhere in the ERD to target a push even if there
 * were. Always fails (honestly, not a fabricated success) so
 * NotificationDeliveryService's documented retry-then-fail state machine
 * (cross-cutting-architecture.md) has real, correct behavior to exercise —
 * a `push`-channel notification queued today will end up `failed` after
 * its bounded retries, which is the truthful outcome, not a silently
 * swallowed no-op.
 */
@Injectable()
export class PushNotificationSender implements NotificationSender {
  async send(_notification: Notification, _copy: NotificationCopy): Promise<void> {
    throw new PushNotificationNotConfiguredException();
  }
}
