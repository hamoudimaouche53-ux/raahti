import { ApiProperty } from '@nestjs/swagger';
import { SlatokiPlaceSearchItem } from '../../application/slatoki-query.service';
import { BilingualTextDto } from './bilingual-text.dto';
import { GeoPointDto } from './geo-point.dto';

/** Matches openapi.yaml components.schemas.SlatokiPlaceSummary (allOf PlaceSummary + womenVerificationLevel) exactly. */
export class SlatokiPlaceSummaryDto {
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

  @ApiProperty({ enum: ['verified_confirmed', 'generic'] })
  womenVerificationLevel!: string;

  static fromSearchItem(item: SlatokiPlaceSearchItem): SlatokiPlaceSummaryDto {
    const dto = new SlatokiPlaceSummaryDto();
    dto.id = item.id;
    dto.placeKind = item.placeKind;
    dto.name = item.name;
    dto.position = GeoPointDto.fromLatLng(item.position.lat, item.position.lng);
    dto.pinColor = item.pinColor;
    dto.distanceMeters = item.distanceMeters;
    dto.averageRating = item.averageRating;
    dto.reviewCount = item.reviewCount;
    dto.isFree = item.isFree;
    dto.tags = item.tags;
    dto.womenVerificationLevel = item.womenVerificationLevel;
    return dto;
  }
}
