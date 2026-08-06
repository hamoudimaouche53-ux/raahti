import { GeoPosition } from '../../../../shared-kernel';
import { Cabin } from '../entities/cabin.entity';
import { CabinPricingMix } from '../entities/station.entity';
import { Station } from '../entities/station.entity';
import { OccupancyStatus } from '../value-objects/occupancy-status.vo';
import { StationConfiguration } from '../value-objects/station-configuration.vo';
import { StationStatus } from '../value-objects/station-status.vo';
import { PlaceFilterType } from '../value-objects/place-filter-type.vo';

export const STATION_REPOSITORY = Symbol('STATION_REPOSITORY');

export interface StationSearchCriteria {
  position: GeoPosition;
  radiusMeters: number;
  /** OR semantics across selected types — empty/undefined means no filter (ADR-0021). */
  types: PlaceFilterType[];
  /** Bilingual free-text search (FR-MAP-04) — matched against Station.code (see StationDetailDto's flagged `name` judgment call). */
  query?: string;
  /** Opaque, previously-returned cursor (api-architecture.md §6) — null/undefined starts from the beginning. */
  cursor?: string | null;
  limit: number;
}

export interface StationSearchResult {
  id: string;
  code: string;
  configuration: StationConfiguration;
  status: StationStatus;
  position: GeoPosition;
  distanceMeters: number;
  hasSlatokiTent: boolean;
  cabinPricingMix: CabinPricingMix;
  /** Derived read-model aggregate (ERD §3.4 note) — computed inline in the same query, not a separate round trip. */
  averageRating: number | null;
  reviewCount: number;
}

export interface StationSearchPage {
  data: StationSearchResult[];
  nextCursor: string | null;
}

export interface NearestAccessibleStationResult {
  /** Same projection shape `searchNearby` returns — the application layer maps it into `StationPlaceSearchItem` the same way. */
  station: StationSearchResult;
  nearestCabinId: string | null;
}

export interface StationRepository {
  /** Full aggregate (cabins + slatokiTent) for the /stations/{id} detail view. */
  findById(id: string): Promise<Station | null>;

  /** ST_DWithin nearby search (FR-MAP-01/02/04/05) — lightweight projection, not the full aggregate (no cabin rows fetched per result). */
  searchNearby(criteria: StationSearchCriteria): Promise<StationSearchPage>;

  /** Every station with its cabins, fleet-wide, no filter/pagination — backs Operations FR-OPS-01 via StationQueryService.listAllForFleetView(). */
  findAll(): Promise<Station[]>;

  /**
   * Single-cabin lookup, added for AccessPaymentModule's sanctioned
   * `AccessPay -> StationNet` command dependency (module-dependency-diagram.md
   * §3) — backs StationCommandService.checkCabinAvailability(). Returns the
   * bare Cabin entity, not the full Station aggregate — the access-payment
   * flow never needs the owning station's other cabins/tent.
   */
  findCabinById(cabinId: string): Promise<Cabin | null>;

  /**
   * Direct occupancy write, added for the same sanctioned command dependency
   * — backs StationCommandService.setCabinOccupancy(), called synchronously
   * around the unlock/complete flow (module-dependency-diagram.md §5 rule 4:
   * "cabin availability must be checked synchronously before payment; station
   * status must update synchronously when maintenance starts" — the same
   * immediate-consistency rationale applies here).
   */
  updateCabinOccupancy(cabinId: string, status: OccupancyStatus): Promise<void>;

  /**
   * Nearest `active` station within `radiusMeters` (FR-EMG-02), backing
   * EmergencyModule's one-tap "nearest accessible facility" flow
   * (module-dependency-diagram.md §3: `Emergency -.->|read| StationNetwork`).
   * Also picks one cabin on the winning station: prefer `occupancyStatus =
   * 'free'`, else any cabin that isn't `out_of_service`, else `null` if the
   * station has no cabins at all — the exact tiebreak rule isn't specified by
   * any doc, flagged here as a judgment call, same as the radius itself
   * (EMERGENCY_SEARCH_RADIUS_METERS, station-query.service.ts).
   */
  findNearestAccessible(position: GeoPosition, radiusMeters: number): Promise<NearestAccessibleStationResult | null>;
}
