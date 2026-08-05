import { Injectable } from '@nestjs/common';
import { GeoPosition } from '../../../shared-kernel';
import { StationQueryService } from '../../station-network/application/station-query.service';
import { ThirdPartyPlaceQueryService } from '../../third-party-places/application/third-party-place-query.service';
import { PrayerFacilityFilter } from '../domain/value-objects/prayer-facility-filter.vo';
import { WomenVerificationLevel } from '../domain/value-objects/women-verification-level.vo';

/**
 * The single fixed radius/page-size used internally — GET /slatoki/places
 * (openapi.yaml) takes no radiusMeters/cursor/limit params at all (unlike
 * /places/nearby), so there is nothing for a client to configure. Flagged
 * judgment call: values chosen to match /places/nearby's own defaults for
 * consistency, not specified anywhere for this endpoint.
 */
const SEARCH_RADIUS_METERS = 2000;
const MAX_RESULTS_PER_SOURCE = 100;

export interface SlatokiPlaceSearchItem {
  id: string;
  placeKind: 'station' | 'third_party_place';
  name: { fr: string; ar: string; en: string };
  position: { lat: number; lng: number };
  pinColor: 'green' | 'blue' | 'amber' | 'magenta';
  distanceMeters: number;
  averageRating: number | null;
  reviewCount: number;
  isFree: boolean;
  tags: string[];
  womenVerificationLevel: WomenVerificationLevel;
}

/**
 * Slatoki bounded context (Domain Model §4) — owns no aggregate, no
 * persisted state, no Prisma models. Depends only on StationNetworkModule's
 * and ThirdPartyPlacesModule's exported *QueryService, the read edge the
 * module-dependency-diagram.md §3 matrix grants specifically to Slatoki
 * (`Slatoki -.->|read| StationNetwork`, `Slatoki -.->|read| ThirdPartyPlaces`).
 */
@Injectable()
export class SlatokiQueryService {
  constructor(
    private readonly stationQueryService: StationQueryService,
    private readonly thirdPartyPlaceQueryService: ThirdPartyPlaceQueryService,
  ) {}

  /** Backing GET /slatoki/places (FR-SLK-03/04/05). */
  async searchPlaces(criteria: { position: GeoPosition; filter?: PrayerFacilityFilter }): Promise<SlatokiPlaceSearchItem[]> {
    const [stationPage, thirdPartyPage] = await Promise.all([
      this.stationQueryService.searchNearby({
        position: criteria.position,
        radiusMeters: SEARCH_RADIUS_METERS,
        types: [],
        limit: MAX_RESULTS_PER_SOURCE,
      }),
      this.thirdPartyPlaceQueryService.searchNearby({
        position: criteria.position,
        radiusMeters: SEARCH_RADIUS_METERS,
        types: [],
        limit: MAX_RESULTS_PER_SOURCE,
      }),
    ]);

    const stationItems: SlatokiPlaceSearchItem[] = stationPage.data
      .filter((item) => item.hasSlatokiTent)
      .map((item) => ({
        id: item.id,
        placeKind: item.placeKind,
        name: item.name,
        position: item.position,
        pinColor: item.pinColor,
        distanceMeters: item.distanceMeters,
        averageRating: item.averageRating,
        reviewCount: item.reviewCount,
        isFree: item.isFree,
        tags: item.tags,
        // A RAHETI Slatoki tent is a full prayer+ablution facility by
        // construction (FR-SLK-05) and is RAHETI-operated, not a self-declared
        // third-party claim — always the highest verification level.
        womenVerificationLevel: 'verified_confirmed' as const,
      }));

    const thirdPartyItems: SlatokiPlaceSearchItem[] = thirdPartyPage.data
      .filter((item) => item.tags.includes('prayer') || item.tags.includes('wudu'))
      .map((item) => ({
        id: item.id,
        placeKind: item.placeKind,
        name: item.name,
        position: item.position,
        pinColor: item.pinColor,
        distanceMeters: item.distanceMeters,
        averageRating: item.averageRating,
        reviewCount: item.reviewCount,
        isFree: item.isFree,
        tags: item.tags,
        // FR-SLK-04: verified only when explicitly tagged; otherwise shown as generic, not excluded.
        womenVerificationLevel: (item.tags.includes('women_confirmed')
          ? 'verified_confirmed'
          : 'generic') satisfies WomenVerificationLevel,
      }));

    const combined = [...stationItems, ...thirdPartyItems].filter((item) =>
      this.matchesFilter(item, criteria.filter),
    );

    return combined.sort((a, b) => a.distanceMeters - b.distanceMeters);
  }

  /**
   * FR-SLK-03. A RAHETI Slatoki tent always offers both prayer and wudu
   * (FR-SLK-05's "espaces de prière et d'ablution"), so it matches every
   * filter value unconditionally. For a ThirdPartyPlace, matching is a
   * capability check ("supports at least what was asked for"), not an exact
   * match — a place tagged with both `prayer` and `wudu` still matches
   * `prayer_only`. Flagged judgment call: the filter's exact semantics
   * aren't specified beyond the three enum values (openapi.yaml, ADR
   * precedent — same treatment as the /places/nearby type[] filters).
   */
  private matchesFilter(item: SlatokiPlaceSearchItem, filter?: PrayerFacilityFilter): boolean {
    if (!filter || item.placeKind === 'station') {
      return true;
    }
    switch (filter) {
      case 'prayer_only':
        return item.tags.includes('prayer');
      case 'wudu_only':
        return item.tags.includes('wudu');
      case 'prayer_and_wudu':
        return item.tags.includes('prayer') && item.tags.includes('wudu');
    }
  }
}
