import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude } from 'class-validator';

/** Matches the GET /routes/walking query parameters (openapi.yaml) exactly. */
export class RouteQueryDto {
  @ApiProperty()
  @Type(() => Number)
  @IsLatitude()
  originLat!: number;

  @ApiProperty()
  @Type(() => Number)
  @IsLongitude()
  originLng!: number;

  @ApiProperty()
  @Type(() => Number)
  @IsLatitude()
  destLat!: number;

  @ApiProperty()
  @Type(() => Number)
  @IsLongitude()
  destLng!: number;
}
