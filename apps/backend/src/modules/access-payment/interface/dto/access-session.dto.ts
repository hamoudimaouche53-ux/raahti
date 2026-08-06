import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { AccessSession } from '../../domain/entities/access-session.entity';

const ACCESS_SESSION_STATUSES = ['initiated', 'payment_pending', 'unlocked', 'in_use', 'completed', 'cancelled'] as const;

/** Matches openapi.yaml components.schemas.AccessSessionCreateRequest exactly. */
export class AccessSessionCreateRequestDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  qrCodeScanned!: string;
}

/** Matches openapi.yaml components.schemas.AccessSession exactly. */
export class AccessSessionResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  cabinId!: string;

  @ApiProperty({ enum: ACCESS_SESSION_STATUSES })
  status!: string;

  @ApiProperty({ format: 'date-time' })
  startedAt!: string;

  @ApiProperty({ format: 'date-time', nullable: true })
  unlockedAt!: string | null;

  static fromDomain(session: AccessSession): AccessSessionResponseDto {
    const dto = new AccessSessionResponseDto();
    dto.id = session.id;
    dto.cabinId = session.cabinId;
    dto.status = session.status;
    dto.startedAt = session.startedAt.toISOString();
    dto.unlockedAt = session.unlockedAt ? session.unlockedAt.toISOString() : null;
    return dto;
  }
}
