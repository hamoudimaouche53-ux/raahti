import { Module } from '@nestjs/common';
import { IdentityModule } from '../identity/identity.module';
import { DELAY_FN, realDelay } from './application/delay.token';
import { NotificationCopyResolver } from './application/notification-copy-resolver';
import { NotificationDeliveryService } from './application/notification-delivery.service';
import { NotificationEventSubscriber } from './application/notification-event-subscriber';
import { NotificationService } from './application/notification.service';
import { NOTIFICATION_REPOSITORY } from './domain/ports/notification.repository';
import { InAppNotificationSender } from './infrastructure/channels/in-app-notification-sender';
import { IN_APP_NOTIFICATION_SENDER, PUSH_NOTIFICATION_SENDER } from './infrastructure/channels/notification-sender.port';
import { PushNotificationSender } from './infrastructure/channels/push-notification-sender';
import { PrismaNotificationRepository } from './infrastructure/prisma-notification.repository';
import { NotificationsController } from './interface/controllers/notifications.controller';

/**
 * Notifications bounded context (Domain Model §8). Imports IdentityModule
 * only to reach its exported UserQueryService — the sanctioned read edge
 * module-dependency-diagram.md §3 grants Notifications specifically
 * (`Notif -.->|read| Identity`), used for recipient-language resolution
 * (cross-cutting-architecture.md — notification copy localization).
 */
@Module({
  imports: [IdentityModule],
  controllers: [NotificationsController],
  providers: [
    { provide: NOTIFICATION_REPOSITORY, useClass: PrismaNotificationRepository },
    { provide: IN_APP_NOTIFICATION_SENDER, useClass: InAppNotificationSender },
    { provide: PUSH_NOTIFICATION_SENDER, useClass: PushNotificationSender },
    { provide: DELAY_FN, useValue: realDelay },
    NotificationService,
    NotificationCopyResolver,
    NotificationDeliveryService,
    NotificationEventSubscriber,
  ],
})
export class NotificationsModule {}
