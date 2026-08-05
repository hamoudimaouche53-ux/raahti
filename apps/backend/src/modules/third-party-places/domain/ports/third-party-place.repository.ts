import { GeoPosition } from '../../../../shared-kernel';
import { ThirdPartyPlace } from '../entities/third-party-place.entity';
import { DeclaredStatus, StatusSource } from '../value-objects/declared-status.vo';
import { PlaceFilterType } from '../value-objects/place-filter-type.vo';
import { PlaceType } from '../value-objects/place-type.vo';
import { TagCode } from '../value-objects/tag.vo';

export const THIRD_PARTY_PLACE_REPOSITORY = Symbol('THIRD_PARTY_PLACE_REPOSITORY');

export interface ThirdPartyPlaceSearchCriteria {
  position: GeoPosition;
  radiusMeters: number;
  /** OR semantics across selected types — empty/undefined means no filter (ADR-0021). `rahati_unit` never matches. */
  types: PlaceFilterType[];
  /** Bilingual free-text search (FR-MAP-04) — matched against name_fr/name_ar. */
  query?: string;
  cursor?: string | null;
  limit: number;
}

export interface ThirdPartyPlaceSearchResult {
  id: string;
  nameFr: string;
  nameAr: string;
  placeType: PlaceType;
  position: GeoPosition;
  distanceMeters: number;
  isFree: boolean;
  declaredStatus: DeclaredStatus;
  statusSource: StatusSource;
  tags: TagCode[];
  /** Derived read-model aggregate (ERD §3.4 note) — computed inline in the same query, not a separate round trip. */
  averageRating: number | null;
  reviewCount: number;
}

export interface ThirdPartyPlaceSearchPage {
  data: ThirdPartyPlaceSearchResult[];
  nextCursor: string | null;
}

export interface ThirdPartyPlaceRepository {
  findById(id: string): Promise<ThirdPartyPlace | null>;

  /** ST_DWithin nearby search (FR-MAP-01/02/04/05). */
  searchNearby(criteria: ThirdPartyPlaceSearchCriteria): Promise<ThirdPartyPlaceSearchPage>;
}
