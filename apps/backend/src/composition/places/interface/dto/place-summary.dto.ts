import { ApiProperty } from '@nestjs/swagger';
import { PlaceSearchItem } from '../../places-query.service';
import { BilingualTextDto } from './bilingual-text.dto';
import { GeoPointDto } from './geo-point.dto';

/** Matches openapi.yaml components.schemas.PlaceSummary exactly. */
export class PlaceSummaryDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['station', 'third_party_place'] })
  placeKind!: string;

  @ApiProperty({ type: BilingualTextDto })
  name!: BilingualTextDto;

  @ApiProperty({ type: GeoPointDto })
  position!: GeoPointDto;

  @ApiProperty({ enum: ['green', 'blue', 'amber', 'magenta'] })
  pinColor!: string;

  @ApiProperty()
  distanceMeters!: number;

  @ApiProperty({ nullable: true })
  averageRating!: number | null;

  @ApiProperty()
  reviewCount!: number;

  @ApiProperty()
  isFree!: boolean;

  @ApiProperty({ type: [String] })
  tags!: string[];

  static fromSearchItem(item: PlaceSearchItem): PlaceSummaryDto {
    const dto = new PlaceSummaryDto();
    dto.id = item.id;
    dto.placeKind = item.placeKind;
    dto.name = item.name;
    dto.position = GeoPointDto.fromLatLng(item.position.lat, item.position.lng);
    dto.pinColor = item.pinColor;
    dto.distanceMeters = item.distanceMeters;
    dto.averageRating = null; // Reviews land in Facilities Pass 4.
    dto.reviewCount = 0;
    dto.isFree = item.isFree;
    dto.tags = item.tags;
    return dto;
  }
}
