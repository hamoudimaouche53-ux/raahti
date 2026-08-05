import { Inject, Injectable } from '@nestjs/common';
import { GeoPosition } from '../../../shared-kernel';
import { Station } from '../domain/entities/station.entity';
import { STATION_REPOSITORY, StationRepository } from '../domain/ports/station.repository';
import { STATION_REVIEW_REPOSITORY, StationRatingAggregate, StationReviewRepository } from '../domain/ports/station-review.repository';
import { PlaceFilterType } from '../domain/value-objects/place-filter-type.vo';
import { deriveStationPinColorFromSearchResult, PinColor } from './pin-color';
import { StationNotFoundException } from './station-not-found.exception';

export interface StationPlaceSearchItem {
  id: string;
  placeKind: 'station';
  name: { fr: string; ar: string; en: string };
  position: { lat: number; lng: number };
  pinColor: PinColor;
  distanceMeters: number;
  isFree: boolean;
  averageRating: number | null;
  reviewCount: number;
  /** Stations carry no tag system (ERD §3.5/§3.6 tags are Third-Party-Place-only) — always empty, present for PlaceSummary shape parity. */
  tags: string[];
  /**
   * Exposed for SlatokiModule's sanctioned read dependency (module-dependency-diagram.md
   * §3: `Slatoki -.->|read| StationNetwork`) — Slatoki needs to know Slatoki-tent
   * presence directly to determine qualification/verification level (FR-SLK-04/05),
   * not by reverse-inferring it from `pinColor === 'magenta'`, which would silently
   * couple Slatoki's business rule to this module's presentation-color derivation.
   */
  hasSlatokiTent: boolean;
}

export interface StationPlaceSearchPage {
  data: StationPlaceSearchItem[];
  nextCursor: string | null;
}

export interface StationNearbySearchCriteria {
  position: GeoPosition;
  radiusMeters: number;
  types: PlaceFilterType[];
  query?: string;
  cursor?: string | null;
  limit: number;
}

/**
 * Exported application-layer query surface for this module — the only thing
 * another module (or the Places composition layer, ADR-0029) may depend on.
 * Never expose the repository/domain entity constructor directly
 * (module-dependency-diagram.md §5 rule 1).
 */
@Injectable()
export class StationQueryService {
  constructor(
    @Inject(STATION_REPOSITORY) private readonly stationRepository: StationRepository,
    @Inject(STATION_REVIEW_REPOSITORY) private readonly stationReviewRepository: StationReviewRepository,
  ) {}

  async getById(id: string): Promise<Station> {
    const station = await this.stationRepository.findById(id);
    if (!station) {
      throw new StationNotFoundException(id);
    }
    return station;
  }

  /** ERD §3.4 note — derived read-model, computed alongside (not stored on) the Station aggregate. */
  async getRatingAggregate(stationId: string): Promise<StationRatingAggregate> {
    return this.stationReviewRepository.aggregateByStationId(stationId);
  }

  /** Backing GET /places/nearby (via the Places composition layer, ADR-0029). */
  async searchNearby(criteria: StationNearbySearchCriteria): Promise<StationPlaceSearchPage> {
    const page = await this.stationRepository.searchNearby(criteria);
    return {
      data: page.data.map((result) => ({
        id: result.id,
        placeKind: 'station' as const,
        name: { fr: result.code, ar: result.code, en: result.code },
        position: { lat: result.position.lat, lng: result.position.lng },
        pinColor: deriveStationPinColorFromSearchResult(result),
        distanceMeters: result.distanceMeters,
        isFree: result.cabinPricingMix === 'all_free',
        averageRating: result.averageRating,
        reviewCount: result.reviewCount,
        tags: [],
        hasSlatokiTent: result.hasSlatokiTent,
      })),
      nextCursor: page.nextCursor,
    };
  }
}
