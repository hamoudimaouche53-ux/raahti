import { ApiProperty } from '@nestjs/swagger';
import { Station } from '../../domain/entities/station.entity';
import { deriveStationPinColor } from '../../application/pin-color';
import { StationRatingAggregate } from '../../domain/ports/station-review.repository';
import { BilingualTextDto } from './bilingual-text.dto';
import { CabinDto } from './cabin.dto';
import { GeoPointDto } from './geo-point.dto';
import { SlatokiTentDto } from './slatoki-tent.dto';

/**
 * Matches openapi.yaml components.schemas.StationDetail (allOf PlaceSummary +
 * station-specific fields), flattened into one DTO class. `name` has no ERD
 * source (Station has no name column, only `code`) and `name.en` has no
 * distinct source (BilingualText requires fr/ar/en, ERD only ever has
 * fr/ar-shaped content) — both are flagged, documented judgment calls: `name`
 * uses `code` in all three languages; nothing is machine-translated. See the
 * Facilities module completion notes.
 */
export class StationDetailDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['station'] })
  placeKind!: 'station';

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

  @ApiProperty({ enum: ['fixe', 'mobile', 'event'] })
  configuration!: string;

  @ApiProperty({ enum: ['active', 'inactive', 'maintenance'] })
  status!: string;

  @ApiProperty({ type: [CabinDto] })
  cabins!: CabinDto[];

  @ApiProperty({ type: SlatokiTentDto, nullable: true })
  slatokiTent!: SlatokiTentDto | null;

  static fromDomain(station: Station, rating: StationRatingAggregate): StationDetailDto {
    const dto = new StationDetailDto();
    dto.id = station.id;
    dto.placeKind = 'station';
    dto.name = { fr: station.code, ar: station.code, en: station.code };
    dto.position = GeoPointDto.fromDomain(station.position);
    dto.pinColor = deriveStationPinColor(station);
    dto.averageRating = rating.averageRating;
    dto.reviewCount = rating.reviewCount;
    dto.isFree = station.cabinPricingMix() === 'all_free';
    dto.tags = [];
    dto.configuration = station.configuration;
    dto.status = station.status;
    dto.cabins = station.cabins.map((cabin) => CabinDto.fromDomain(cabin));
    dto.slatokiTent = station.slatokiTent ? SlatokiTentDto.fromDomain(station.slatokiTent) : null;
    return dto;
  }
}
