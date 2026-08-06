import { ApiProperty } from '@nestjs/swagger';
import { EmergencyNearestFacilityResult } from '../../application/emergency-query.service';
import { BilingualTextDto } from './bilingual-text.dto';
import { GeoPointDto } from './geo-point.dto';

type PlaceSearchItem = EmergencyNearestFacilityResult['place'];

/**
 * Matches openapi.yaml components.schemas.PlaceSummary exactly. Duplicated
 * locally rather than reaching into composition/places/interface/ or
 * station-network/interface/ — same precedent as Slatoki's own
 * SlatokiPlaceSummaryDto (module-dependency-diagram.md §5 rule 1: only the
 * exported *QueryService/application-layer shape may cross a module
 * boundary, never another module's interface/ DTOs).
 */
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
    dto.averageRating = item.averageRating;
    dto.reviewCount = item.reviewCount;
    dto.isFree = item.isFree;
    dto.tags = item.tags;
    return dto;
  }
}
