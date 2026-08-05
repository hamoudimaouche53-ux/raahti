import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsOptional, IsUUID } from 'class-validator';
import { MaintenanceIntervention } from '../../domain/entities/maintenance-intervention.entity';

const INTERVENTION_TYPES = ['refill', 'emptying', 'repair', 'preventive'] as const;
const INTERVENTION_STATUSES = ['scheduled', 'in_progress', 'completed', 'cancelled'] as const;

/**
 * Matches openapi.yaml components.schemas.MaintenanceInterventionCreateRequest
 * exactly — `assignedTo` is optional here per the contract (see
 * application/maintenance-intervention.service.ts's schedule() doc comment
 * for how the ERD's NOT NULL constraint is still satisfied).
 */
export class MaintenanceInterventionCreateRequestDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  stationId!: string;

  @ApiProperty({ enum: INTERVENTION_TYPES })
  @IsIn(INTERVENTION_TYPES)
  interventionType!: (typeof INTERVENTION_TYPES)[number];

  @ApiProperty({ format: 'date-time' })
  @IsDateString()
  scheduledAt!: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  assignedTo?: string;
}

/** Matches openapi.yaml components.schemas.MaintenanceIntervention exactly. */
export class MaintenanceInterventionResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  stationId!: string;

  @ApiProperty({ enum: INTERVENTION_TYPES })
  interventionType!: string;

  @ApiProperty({ enum: INTERVENTION_STATUSES })
  status!: string;

  @ApiProperty({ format: 'date-time' })
  scheduledAt!: string;

  static fromDomain(intervention: MaintenanceIntervention): MaintenanceInterventionResponseDto {
    const dto = new MaintenanceInterventionResponseDto();
    dto.id = intervention.id;
    dto.stationId = intervention.stationId;
    dto.interventionType = intervention.interventionType;
    dto.status = intervention.status;
    dto.scheduledAt = intervention.scheduledAt.toISOString();
    return dto;
  }
}
