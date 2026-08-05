import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { DOMAIN_EVENT_BUS, DomainEventBus } from '../../../shared-kernel';
import { PaymentCapturedEvent } from '../domain/events/payment-captured.event';
import { NotificationService } from './notification.service';

/**
 * domain-model.md §8 — Notifications "Subscribes to": CabinOccupancyChanged
 * (Station Network), AlertRaised (Operations), PaymentCaptured (Access &
 * Payment). Only PaymentCaptured is wired here.
 *
 * CabinOccupancyChanged and AlertRaised are NOT implemented this pass —
 * flagged, not silently dropped. Both need a cross-module "which users to
 * notify" lookup that no module currently exports:
 *   - CabinOccupancyChanged → "users who favorited this station/place with
 *     notifyOnAvailable=true" — Identity's FavoriteService only supports
 *     list-for-the-current-user, not query-by-place; the module-dependency-
 *     diagram.md matrix also grants Notifications no read path to Station
 *     Network to know which place the event concerns.
 *   - AlertRaised → "operators scoped to this alert's site" — needs an
 *     Identity query by role+site_scope that doesn't exist yet.
 * Both publishing modules (Station Network's occupancy-write-path,
 * Operations) are themselves out of scope for this pass, so there is
 * nothing to subscribe to yet in practice either way. Resolving the exact
 * cross-module shape is deferred to when those modules are actually built,
 * rather than designed blind now against a hypothetical event.
 *
 * PaymentCaptured is wired because it needs no such lookup — the event
 * itself carries the recipient (userId) and the reference
 * (transactionId) directly.
 */
@Injectable()
export class NotificationEventSubscriber implements OnModuleInit {
  private readonly logger = new Logger(NotificationEventSubscriber.name);

  constructor(
    @Inject(DOMAIN_EVENT_BUS) private readonly eventBus: DomainEventBus,
    private readonly notificationService: NotificationService,
  ) {}

  onModuleInit(): void {
    this.eventBus.subscribe<PaymentCapturedEvent>('PaymentCaptured', async (event) => {
      await this.notificationService.queue({
        userId: event.userId,
        channel: 'in_app',
        type: 'payment_confirmation',
        relatedTransactionId: event.transactionId,
      });
      this.logger.log(`Queued payment_confirmation notification for user ${event.userId}`);
    });
  }
}
