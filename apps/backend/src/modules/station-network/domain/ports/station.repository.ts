import { GeoPosition } from '../../../../shared-kernel';
import { CabinPricingMix } from '../entities/station.entity';
import { Station } from '../entities/station.entity';
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

export interface StationRepository {
  /** Full aggregate (cabins + slatokiTent) for the /stations/{id} detail view. */
  findById(id: string): Promise<Station | null>;

  /** ST_DWithin nearby search (FR-MAP-01/02/04/05) — lightweight projection, not the full aggregate (no cabin rows fetched per result). */
  searchNearby(criteria: StationSearchCriteria): Promise<StationSearchPage>;

  /** Every station with its cabins, fleet-wide, no filter/pagination — backs Operations FR-OPS-01 via StationQueryService.listAllForFleetView(). */
  findAll(): Promise<Station[]>;
}
