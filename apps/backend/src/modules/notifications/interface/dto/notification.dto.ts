import { ApiProperty } from '@nestjs/swagger';
import { Notification } from '../../domain/entities/notification.entity';

/**
 * Matches openapi.yaml components.schemas.Notification, plus `isRead`/`readAt`
 * — an additive gap-fill confirmed with the user (Notifications module
 * kickoff, 2026-08-05): the documented schema had no field for a client to
 * observe read/unread state at all, even though PATCH .../{id} is
 * documented as "Mark a notification as read". See
 * docs/phase-4-implementation-plan.md for the full writeup.
 */
export class NotificationResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['availability', 'operator_alert', 'payment_confirmation'] })
  type!: string;

  @ApiProperty({ enum: ['queued', 'sent', 'delivered', 'failed'] })
  status!: string;

  @ApiProperty({ format: 'date-time' })
  createdAt!: string;

  @ApiProperty()
  isRead!: boolean;

  @ApiProperty({ format: 'date-time', nullable: true })
  readAt!: string | null;

  static fromDomain(notification: Notification): NotificationResponseDto {
    const dto = new NotificationResponseDto();
    dto.id = notification.id;
    dto.type = notification.type;
    dto.status = notification.status;
    dto.createdAt = notification.createdAt.toISOString();
    dto.isRead = notification.isRead;
    dto.readAt = notification.readAt ? notification.readAt.toISOString() : null;
    return dto;
  }
}
