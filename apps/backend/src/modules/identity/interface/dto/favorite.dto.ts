import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsUUID, ValidateIf } from 'class-validator';
import { Favorite } from '../../domain/entities/favorite.entity';

/** Matches openapi.yaml components.schemas.FavoriteCreateRequest exactly (FR-USR-04). */
export class FavoriteCreateRequestDto {
  @ApiProperty({ format: 'uuid', nullable: true, required: false })
  @IsOptional()
  @ValidateIf((dto: FavoriteCreateRequestDto) => dto.stationId !== null && dto.stationId !== undefined)
  @IsUUID()
  stationId?: string | null;

  @ApiProperty({ format: 'uuid', nullable: true, required: false })
  @IsOptional()
  @ValidateIf((dto: FavoriteCreateRequestDto) => dto.thirdPartyPlaceId !== null && dto.thirdPartyPlaceId !== undefined)
  @IsUUID()
  thirdPartyPlaceId?: string | null;

  @ApiProperty({ default: false, required: false })
  @IsOptional()
  @IsBoolean()
  notifyOnAvailable?: boolean;
}

/** Matches openapi.yaml components.schemas.FavoriteUpdateRequest exactly (FR-USR-04). */
export class FavoriteUpdateRequestDto {
  @ApiProperty()
  @IsBoolean()
  notifyOnAvailable!: boolean;
}

/** Matches openapi.yaml components.schemas.Favorite exactly. */
export class FavoriteResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid', nullable: true, type: String })
  stationId!: string | null;

  @ApiProperty({ format: 'uuid', nullable: true, type: String })
  thirdPartyPlaceId!: string | null;

  @ApiProperty()
  notifyOnAvailable!: boolean;

  static fromDomain(favorite: Favorite): FavoriteResponseDto {
    const dto = new FavoriteResponseDto();
    dto.id = favorite.id;
    dto.stationId = favorite.stationId;
    dto.thirdPartyPlaceId = favorite.thirdPartyPlaceId;
    dto.notifyOnAvailable = favorite.notifyOnAvailable;
    return dto;
  }
}

export class FavoriteListResponseDto {
  @ApiProperty({ type: [FavoriteResponseDto] })
  data!: FavoriteResponseDto[];

  @ApiProperty({ nullable: true, type: String })
  nextCursor!: string | null;
}
