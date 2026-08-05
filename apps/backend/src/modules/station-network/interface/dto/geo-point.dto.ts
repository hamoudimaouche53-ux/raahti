import { ApiProperty } from '@nestjs/swagger';
import { GeoPosition } from '../../../../shared-kernel';

/** Matches openapi.yaml components.schemas.GeoPoint — GeoJSON [lng, lat] order (api-architecture.md §4). */
export class GeoPointDto {
  @ApiProperty({ enum: ['Point'] })
  type!: 'Point';

  @ApiProperty({ type: [Number] })
  coordinates!: [number, number];

  static fromDomain(position: GeoPosition): GeoPointDto {
    const dto = new GeoPointDto();
    dto.type = 'Point';
    dto.coordinates = [position.lng, position.lat];
    return dto;
  }
}
