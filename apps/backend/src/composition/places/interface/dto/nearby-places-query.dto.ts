import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsArray, IsIn, IsInt, IsLatitude, IsLongitude, IsOptional, IsString, Max, Min } from 'class-validator';

const DEFAULT_RADIUS_METERS = 2000;
const MAX_RADIUS_METERS = 20000;
const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 100;
const VALID_TYPES = ['free_wc', 'paid_wc', 'rahati_unit', 'slatoki'] as const;

/** Matches the GET /places/nearby query parameters (openapi.yaml) exactly. */
export class NearbyPlacesQueryDto {
  @ApiPropertyOptional()
  @Type(() => Number)
  @IsLatitude()
  lat!: number;

  @ApiPropertyOptional()
  @Type(() => Number)
  @IsLongitude()
  lng!: number;

  @ApiPropertyOptional({ default: DEFAULT_RADIUS_METERS })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_RADIUS_METERS)
  radiusMeters: number = DEFAULT_RADIUS_METERS;

  @ApiPropertyOptional({ enum: VALID_TYPES, isArray: true })
  @IsOptional()
  @Transform(({ value }) => (value === undefined ? [] : Array.isArray(value) ? value : [value]))
  @IsArray()
  @IsIn(VALID_TYPES, { each: true })
  type: string[] = [];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ default: DEFAULT_LIMIT })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_LIMIT)
  limit: number = DEFAULT_LIMIT;
}
