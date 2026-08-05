import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional } from 'class-validator';
import { Alert } from '../../domain/entities/alert.entity';

const ALERT_STATUSES = ['open', 'acknowledged', 'in_progress', 'resolved'] as const;
const UPDATABLE_ALERT_STATUSES = ['acknowledged', 'in_progress', 'resolved'] as const;

/** GET /ops/alerts?status= — matches openapi.yaml's query parameter exactly. */
export class AlertListQueryDto {
  @ApiPropertyOptional({ enum: ALERT_STATUSES })
  @IsOptional()
  @IsIn(ALERT_STATUSES)
  status?: (typeof ALERT_STATUSES)[number];
}

/** Matches openapi.yaml components.schemas.AlertUpdateRequest exactly. */
export class AlertUpdateRequestDto {
  @ApiProperty({ enum: UPDATABLE_ALERT_STATUSES })
  @IsIn(UPDATABLE_ALERT_STATUSES)
  status!: (typeof UPDATABLE_ALERT_STATUSES)[number];
}

/** Matches openapi.yaml components.schemas.Alert exactly. */
export class AlertResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  stationId!: string;

  @ApiProperty({ enum: ['fire', 'sos', 'technical_anomaly', 'preventive_maintenance'] })
  type!: string;

  @ApiProperty({ enum: ['critical', 'high', 'medium', 'low'] })
  severity!: string;

  @ApiProperty({ enum: ALERT_STATUSES })
  status!: string;

  @ApiProperty({ format: 'date-time' })
  raisedAt!: string;

  static fromDomain(alert: Alert): AlertResponseDto {
    const dto = new AlertResponseDto();
    dto.id = alert.id;
    dto.stationId = alert.stationId;
    dto.type = alert.type;
    dto.severity = alert.severity;
    dto.status = alert.status;
    dto.raisedAt = alert.raisedAt.toISOString();
    return dto;
  }
}
