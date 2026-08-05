import { Controller, Get, Param, ParseUUIDPipe, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { NotificationService } from '../../application/notification.service';
import { NotificationResponseDto } from '../dto/notification.dto';

/** GET/PATCH /users/me/notifications — openapi.yaml tag Notifications. No security:[] override — authenticated (bearerAuth applies by default). */
@ApiTags('Notifications')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/notifications')
export class NotificationsController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  async list(@CurrentUser() principal: AuthenticatedPrincipal): Promise<{ data: NotificationResponseDto[] }> {
    const notifications = await this.notificationService.listForUser(principal.sub);
    return { data: notifications.map((notification) => NotificationResponseDto.fromDomain(notification)) };
  }

  @Patch(':notificationId')
  async markAsRead(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('notificationId', ParseUUIDPipe) notificationId: string,
  ): Promise<NotificationResponseDto> {
    const notification = await this.notificationService.markAsRead(principal.sub, notificationId);
    return NotificationResponseDto.fromDomain(notification);
  }
}
