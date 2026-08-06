import { Inject, Injectable } from '@nestjs/common';
import { GeoPosition, Money } from '../../../shared-kernel';
import { Station } from '../domain/entities/station.entity';
import { STATION_REPOSITORY, StationRepository, StationSearchResult } from '../domain/ports/station.repository';
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

export interface StationFleetCabinSummary {
  id: string;
  code: string;
  type: string;
  occupancyStatus: string;
  isPaid: boolean;
  price: Money | null;
}

export interface StationFleetSummary {
  stationId: string;
  status: string;
  cabins: StationFleetCabinSummary[];
}

export interface NearestAccessibleFacility {
  place: StationPlaceSearchItem;
  nearestCabinId: string | null;
}

/**
 * Judgment call — FR-EMG-02 does not specify a search radius for Mode
 * Urgence's "nearest accessible facility" flow (unlike /places/nearby, this
 * endpoint takes no client-configurable radius param at all). 20km chosen as
 * a generous emergency-flow default; mirrors Slatoki's own SEARCH_RADIUS_METERS
 * flagged-judgment-call pattern.
 */
const EMERGENCY_SEARCH_RADIUS_METERS = 20_000;

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
      data: page.data.map((result) => this.toPlaceSearchItem(result)),
      nextCursor: page.nextCursor,
    };
  }

  /**
   * Backing GET /emergency/nearest-facility (EmergencyModule's sanctioned
   * `Emergency -.->|read| StationNetwork` edge, module-dependency-diagram.md
   * §3; FR-EMG-01/02). Returns the same `StationPlaceSearchItem` shape
   * `searchNearby` returns, so EmergencyQueryService/EmergencyController never
   * need to know about this module's raw `StationSearchResult` projection.
   */
  async findNearestAccessible(position: GeoPosition): Promise<NearestAccessibleFacility | null> {
    const result = await this.stationRepository.findNearestAccessible(position, EMERGENCY_SEARCH_RADIUS_METERS);
    if (!result) {
      return null;
    }
    return {
      place: this.toPlaceSearchItem(result.station),
      nearestCabinId: result.nearestCabinId,
    };
  }

  private toPlaceSearchItem(result: StationSearchResult): StationPlaceSearchItem {
    return {
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
    };
  }

  /**
   * Backing GET /ops/stations (Operations, FR-OPS-01) — the sanctioned
   * `Ops -> StationNet` edge (module-dependency-diagram.md §3, plain ✔).
   * Returns a plain projection (not the `Station`/`Cabin` domain entities)
   * so the consuming module never needs to import station-network/domain —
   * same pattern as `StationPlaceSearchItem` above.
   */
  async listAllForFleetView(): Promise<StationFleetSummary[]> {
    const stations = await this.stationRepository.findAll();
    return stations.map((station) => ({
      stationId: station.id,
      status: station.status,
      cabins: station.cabins.map((cabin) => ({
        id: cabin.id,
        code: cabin.code,
        type: cabin.type,
        occupancyStatus: cabin.occupancyStatus,
        isPaid: cabin.isPaid,
        price: cabin.price,
      })),
    }));
  }
}
