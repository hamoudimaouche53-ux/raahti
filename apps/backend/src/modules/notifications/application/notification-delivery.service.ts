import { Inject, Injectable } from '@nestjs/common';
import { LanguagePreference } from '../../../shared-kernel';
import { UserQueryService } from '../../identity/application/user-query.service';
import { Notification } from '../domain/entities/notification.entity';
import { NOTIFICATION_REPOSITORY, NotificationRepository } from '../domain/ports/notification.repository';
import {
  IN_APP_NOTIFICATION_SENDER,
  NotificationSender,
  PUSH_NOTIFICATION_SENDER,
} from '../infrastructure/channels/notification-sender.port';
import { DELAY_FN, DelayFn } from './delay.token';
import { NotificationCopyResolver } from './notification-copy-resolver';

const MAX_ATTEMPTS = 3;
const BASE_BACKOFF_MS = 200;

/**
 * cross-cutting-architecture.md — Notifications: "at-least-once... a
 * NotificationQueued → Sent → Delivered/Failed state machine... with a
 * bounded retry (3 attempts, exponential backoff) before marking Failed".
 * `sent` and `delivered` are set together on a successful send — neither
 * sender in this codebase has a separate asynchronous delivery-confirmation
 * step to observe (in-app has none by construction; push has no real
 * provider at all, see PushNotificationSender), so collapsing them is the
 * honest behavior given what's actually implemented, not a shortcut around
 * a distinction that would otherwise matter.
 */
@Injectable()
export class NotificationDeliveryService {
  constructor(
    @Inject(IN_APP_NOTIFICATION_SENDER) private readonly inAppSender: NotificationSender,
    @Inject(PUSH_NOTIFICATION_SENDER) private readonly pushSender: NotificationSender,
    @Inject(NOTIFICATION_REPOSITORY) private readonly notificationRepository: NotificationRepository,
    private readonly copyResolver: NotificationCopyResolver,
    private readonly userQueryService: UserQueryService,
    @Inject(DELAY_FN) private readonly delay: DelayFn,
  ) {}

  async deliver(notification: Notification): Promise<void> {
    const sender = notification.channel === 'push' ? this.pushSender : this.inAppSender;
    const language = await this.resolveLanguage(notification.userId);
    const copy = this.copyResolver.resolve(notification.type, language);

    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      try {
        await sender.send(notification, copy);
        notification.markSent();
        notification.markDelivered();
        await this.notificationRepository.save(notification);
        return;
      } catch {
        if (attempt === MAX_ATTEMPTS) {
          notification.markFailed();
          await this.notificationRepository.save(notification);
          return;
        }
        await this.delay(BASE_BACKOFF_MS * 2 ** (attempt - 1));
      }
    }
  }

  private async resolveLanguage(userId: string | null): Promise<LanguagePreference> {
    if (!userId) {
      return LanguagePreference.FR;
    }
    const user = await this.userQueryService.findById(userId);
    return user?.preferredLanguage ?? LanguagePreference.FR;
  }
}
