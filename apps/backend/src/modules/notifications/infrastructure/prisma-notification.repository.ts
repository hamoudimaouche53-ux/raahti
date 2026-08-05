import { Injectable } from '@nestjs/common';
import { Notification as PrismaNotification } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { Notification } from '../domain/entities/notification.entity';
import { NotificationRepository } from '../domain/ports/notification.repository';
import { assertNotificationChannel } from '../domain/value-objects/notification-channel.vo';
import { assertNotificationStatus } from '../domain/value-objects/notification-status.vo';
import { assertNotificationType } from '../domain/value-objects/notification-type.vo';

@Injectable()
export class PrismaNotificationRepository implements NotificationRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(notification: Notification): Promise<void> {
    await this.prisma.notification.upsert({
      where: { id: notification.id },
      create: {
        id: notification.id,
        userId: notification.userId,
        channel: notification.channel,
        type: notification.type,
        relatedAlertId: notification.relatedAlertId,
        relatedTransactionId: notification.relatedTransactionId,
        status: notification.status,
        isRead: notification.isRead,
        readAt: notification.readAt,
      },
      update: {
        status: notification.status,
        isRead: notification.isRead,
        readAt: notification.readAt,
      },
    });
  }

  async findById(id: string): Promise<Notification | null> {
    const record = await this.prisma.notification.findUnique({ where: { id } });
    return record ? this.toDomain(record) : null;
  }

  async findByUserId(userId: string): Promise<Notification[]> {
    const records = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return records.map((record) => this.toDomain(record));
  }

  private toDomain(record: PrismaNotification): Notification {
    assertNotificationChannel(record.channel);
    assertNotificationType(record.type);
    assertNotificationStatus(record.status);
    return Notification.restore({
      id: record.id,
      userId: record.userId,
      channel: record.channel,
      type: record.type,
      relatedAlertId: record.relatedAlertId,
      relatedTransactionId: record.relatedTransactionId,
      status: record.status,
      isRead: record.isRead,
      readAt: record.readAt,
      createdAt: record.createdAt,
    });
  }
}
