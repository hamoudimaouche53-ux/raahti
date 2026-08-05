import { Notification } from '../../domain/entities/notification.entity';

export const IN_APP_NOTIFICATION_SENDER = Symbol('IN_APP_NOTIFICATION_SENDER');
export const PUSH_NOTIFICATION_SENDER = Symbol('PUSH_NOTIFICATION_SENDER');

export interface NotificationCopy {
  title: string;
  body: string;
}

/**
 * cross-cutting-architecture.md — Notifications: "both [FCM and APNs] behind
 * a single NotificationSender port... mirrors the ADR-0014 adapter pattern".
 * Lives in infrastructure/channels/ (not domain/ports/), matching
 * repository-structure.md's explicit precedent for `access-payment`'s
 * PaymentGateway: an external-system integration port, not a persistence
 * repository port — the same "provider-agnostic port + swappable adapter"
 * shape, but not a domain dependency-inversion concern.
 */
export interface NotificationSender {
  send(notification: Notification, copy: NotificationCopy): Promise<void>;
}
