import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude } from 'class-validator';

/** Matches the GET /emergency/nearest-facility query parameters (openapi.yaml) exactly — lat/lng are both required. */
export class NearestFacilityQueryDto {
  @ApiProperty()
  @Type(() => Number)
  @IsLatitude()
  lat!: number;

  @ApiProperty()
  @Type(() => Number)
  @IsLongitude()
  lng!: number;
}
