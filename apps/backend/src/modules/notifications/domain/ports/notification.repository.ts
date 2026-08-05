import { Notification } from '../entities/notification.entity';

export const NOTIFICATION_REPOSITORY = Symbol('NOTIFICATION_REPOSITORY');

export interface NotificationRepository {
  save(notification: Notification): Promise<void>;
  findById(id: string): Promise<Notification | null>;
  /** GET /users/me/notifications — no pagination in the contract (flagged, see Phase 4 Implementation Plan); returns every notification for the user, newest first. */
  findByUserId(userId: string): Promise<Notification[]>;
}
