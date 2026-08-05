import { ApiProperty } from '@nestjs/swagger';
import { deriveThirdPartyPlacePinColor } from '../../application/pin-color';
import { ThirdPartyPlace } from '../../domain/entities/third-party-place.entity';
import { ThirdPartyPlaceRatingAggregate } from '../../domain/ports/third-party-place-review.repository';
import { BilingualTextDto } from './bilingual-text.dto';
import { GeoPointDto } from './geo-point.dto';

/**
 * Matches openapi.yaml components.schemas.ThirdPartyPlaceDetail (allOf
 * PlaceSummary + third-party-place-specific fields), flattened into one DTO
 * class. `name.en` has no ERD source (only name_fr/name_ar) — flagged,
 * documented judgment call: falls back to name_fr, mirroring the shipped
 * mobile LocalizedText.forLanguageCode() convention (falls back to French for
 * missing/unrecognized language data). Nothing is machine-translated. See
 * the Facilities module completion notes.
 */
export class ThirdPartyPlaceDetailDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['third_party_place'] })
  placeKind!: 'third_party_place';

  @ApiProperty({ type: BilingualTextDto })
  name!: BilingualTextDto;

  @ApiProperty({ type: GeoPointDto })
  position!: GeoPointDto;

  @ApiProperty({ enum: ['green', 'blue', 'amber', 'magenta'] })
  pinColor!: string;

  @ApiProperty({ nullable: true })
  averageRating!: number | null;

  @ApiProperty()
  reviewCount!: number;

  @ApiProperty()
  isFree!: boolean;

  @ApiProperty({ type: [String] })
  tags!: string[];

  @ApiProperty({ enum: ['mosque', 'business', 'gas_station', 'other'] })
  placeType!: string;

  @ApiProperty({ enum: ['open', 'closed', 'unknown'] })
  declaredStatus!: string;

  @ApiProperty({ enum: ['community', 'owner_declared'] })
  statusSource!: string;

  static fromDomain(place: ThirdPartyPlace, rating: ThirdPartyPlaceRatingAggregate): ThirdPartyPlaceDetailDto {
    const dto = new ThirdPartyPlaceDetailDto();
    dto.id = place.id;
    dto.placeKind = 'third_party_place';
    dto.name = { fr: place.nameFr, ar: place.nameAr, en: place.nameFr };
    dto.position = GeoPointDto.fromDomain(place.position);
    dto.pinColor = deriveThirdPartyPlacePinColor(place);
    dto.averageRating = rating.averageRating;
    dto.reviewCount = rating.reviewCount;
    dto.isFree = place.isFree;
    dto.tags = [...place.tags];
    dto.placeType = place.placeType;
    dto.declaredStatus = place.declaredStatus;
    dto.statusSource = place.statusSource;
    return dto;
  }
}
