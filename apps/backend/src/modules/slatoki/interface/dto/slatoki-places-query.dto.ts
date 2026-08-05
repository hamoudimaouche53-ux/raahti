import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsLatitude, IsLongitude, IsOptional } from 'class-validator';

const VALID_FILTERS = ['prayer_only', 'wudu_only', 'prayer_and_wudu'] as const;

/** Matches the GET /slatoki/places query parameters (openapi.yaml) exactly — no radius/cursor/limit params exist for this endpoint. */
export class SlatokiPlacesQueryDto {
  @ApiPropertyOptional()
  @Type(() => Number)
  @IsLatitude()
  lat!: number;

  @ApiPropertyOptional()
  @Type(() => Number)
  @IsLongitude()
  lng!: number;

  @ApiPropertyOptional({ enum: VALID_FILTERS })
  @IsOptional()
  @IsIn(VALID_FILTERS)
  filter?: string;
}
