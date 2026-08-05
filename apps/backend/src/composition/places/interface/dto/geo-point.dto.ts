import { ApiProperty } from '@nestjs/swagger';

/** Matches openapi.yaml components.schemas.GeoPoint — GeoJSON [lng, lat] order (api-architecture.md §4). */
export class GeoPointDto {
  @ApiProperty({ enum: ['Point'] })
  type!: 'Point';

  @ApiProperty({ type: [Number] })
  coordinates!: [number, number];

  static fromLatLng(lat: number, lng: number): GeoPointDto {
    const dto = new GeoPointDto();
    dto.type = 'Point';
    dto.coordinates = [lng, lat];
    return dto;
  }
}
