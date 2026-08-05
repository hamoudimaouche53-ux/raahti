import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Notification } from '../domain/entities/notification.entity';
import { NOTIFICATION_REPOSITORY, NotificationRepository } from '../domain/ports/notification.repository';
import { NotificationChannel } from '../domain/value-objects/notification-channel.vo';
import { NotificationType } from '../domain/value-objects/notification-type.vo';
import { NotificationNotFoundException } from './notification-not-found.exception';

@Injectable()
export class NotificationService {
  constructor(@Inject(NOTIFICATION_REPOSITORY) private readonly notificationRepository: NotificationRepository) {}

  /** GET /users/me/notifications (FR-CLD-03). No pagination in the contract — see Phase 4 Implementation Plan. */
  async listForUser(userId: string): Promise<Notification[]> {
    return this.notificationRepository.findByUserId(userId);
  }

  /**
   * PATCH /users/me/notifications/{id}. Returns NotificationNotFoundException
   * (404) both when the id doesn't exist and when it belongs to a different
   * user — never confirms another user's notification id exists.
   */
  async markAsRead(userId: string, notificationId: string): Promise<Notification> {
    const notification = await this.notificationRepository.findById(notificationId);
    if (!notification || notification.userId !== userId) {
      throw new NotificationNotFoundException(notificationId);
    }
    notification.markAsRead();
    await this.notificationRepository.save(notification);
    return notification;
  }

  /**
   * Queues a new notification. Used internally by the event subscribers
   * (Facilities Pass 4 — dormant until a real publisher exists) and directly
   * testable on its own.
   */
  async queue(params: {
    userId: string | null;
    channel: NotificationChannel;
    type: NotificationType;
    relatedAlertId?: string | null;
    relatedTransactionId?: string | null;
  }): Promise<Notification> {
    const notification = Notification.queue({ id: randomUUID(), ...params });
    await this.notificationRepository.save(notification);
    return notification;
  }
}
