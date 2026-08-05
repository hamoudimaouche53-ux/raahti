import { Injectable } from '@nestjs/common';
import { GeoPosition } from '../../shared-kernel';
import { StationPlaceSearchItem, StationQueryService } from '../../modules/station-network/application/station-query.service';
import {
  ThirdPartyPlacePlaceSearchItem,
  ThirdPartyPlaceQueryService,
} from '../../modules/third-party-places/application/third-party-place-query.service';
import { EXHAUSTED_MARKER, decodeMergeCursor, encodeItemCursor, encodeMergeCursor } from './places-merge-cursor';
import { PlaceFilterType } from './place-filter-type';

export type PlaceSearchItem = StationPlaceSearchItem | ThirdPartyPlacePlaceSearchItem;

export interface PlacesNearbySearchCriteria {
  position: GeoPosition;
  radiusMeters: number;
  types: PlaceFilterType[];
  query?: string;
  cursor?: string | null;
  limit: number;
}

export interface PlacesNearbySearchPage {
  data: PlaceSearchItem[];
  nextCursor: string | null;
}

interface SourcePage<T> {
  data: readonly T[];
  nextCursor: string | null;
}

/**
 * Read-only cross-context composition for GET /places/nearby (ADR-0029).
 * Depends ONLY on StationNetworkModule's and ThirdPartyPlacesModule's
 * exported *QueryService — never their domain/infrastructure layers.
 * StationNetworkModule and ThirdPartyPlacesModule remain fully independent
 * of each other; this is the one sanctioned place their read results meet.
 */
@Injectable()
export class PlacesQueryService {
  constructor(
    private readonly stationQueryService: StationQueryService,
    private readonly thirdPartyPlaceQueryService: ThirdPartyPlaceQueryService,
  ) {}

  async searchNearby(criteria: PlacesNearbySearchCriteria): Promise<PlacesNearbySearchPage> {
    const incoming = decodeMergeCursor(criteria.cursor);

    const [stationPage, thirdPartyPage] = await Promise.all([
      incoming.station === EXHAUSTED_MARKER
        ? ({ data: [], nextCursor: null } satisfies SourcePage<StationPlaceSearchItem>)
        : this.stationQueryService.searchNearby({
            position: criteria.position,
            radiusMeters: criteria.radiusMeters,
            types: criteria.types,
            query: criteria.query,
            cursor: incoming.station,
            limit: criteria.limit,
          }),
      incoming.thirdParty === EXHAUSTED_MARKER
        ? ({ data: [], nextCursor: null } satisfies SourcePage<ThirdPartyPlacePlaceSearchItem>)
        : this.thirdPartyPlaceQueryService.searchNearby({
            position: criteria.position,
            radiusMeters: criteria.radiusMeters,
            types: criteria.types,
            query: criteria.query,
            cursor: incoming.thirdParty,
            limit: criteria.limit,
          }),
    ]);

    const tagged: Array<{ item: PlaceSearchItem; source: 'station' | 'thirdParty' }> = [
      ...stationPage.data.map((item) => ({ item, source: 'station' as const })),
      ...thirdPartyPage.data.map((item) => ({ item, source: 'thirdParty' as const })),
    ].sort((a, b) => a.item.distanceMeters - b.item.distanceMeters || a.source.localeCompare(b.source));

    const taken = tagged.slice(0, criteria.limit);
    const stationConsumed = taken.filter((entry) => entry.source === 'station').length;
    const thirdPartyConsumed = taken.filter((entry) => entry.source === 'thirdParty').length;

    const nextStation = this.nextSourceCursor(stationConsumed, stationPage.data, stationPage.nextCursor, incoming.station);
    const nextThirdParty = this.nextSourceCursor(
      thirdPartyConsumed,
      thirdPartyPage.data,
      thirdPartyPage.nextCursor,
      incoming.thirdParty,
    );
    const bothExhausted = nextStation === EXHAUSTED_MARKER && nextThirdParty === EXHAUSTED_MARKER;

    return {
      data: taken.map((entry) => entry.item),
      nextCursor: bothExhausted ? null : encodeMergeCursor({ station: nextStation, thirdParty: nextThirdParty }),
    };
  }

  /**
   * Resume position for one source after this page. `null` means "resume
   * from the beginning" (nothing consumed from this source yet, distinct
   * from EXHAUSTED_MARKER's "confirmed nothing left"). Cases, in order:
   *  1. Nothing fetched at all this round, from wherever we started →
   *     confirmed empty from that point on: EXHAUSTED. (A repository query
   *     returning zero rows means nothing further matches, whether this was
   *     the very first call or a later one.)
   *  2. Fetched some, but none made it into this merged page (the other
   *     source's items were all closer) → resume from the SAME starting
   *     point unchanged, so nothing already-fetched-but-unused is lost.
   *  3. Fetched some, some consumed, some left over → resume right after the
   *     last consumed item (a fresh cursor built from it).
   *  4. Every fetched item was consumed → defer to the source's own reported
   *     nextCursor (more exist) or EXHAUSTED (confirmed none left).
   */
  private nextSourceCursor(
    consumedCount: number,
    fetchedItems: readonly PlaceSearchItem[],
    sourceNextCursor: string | null,
    incomingCursor: string | null,
  ): string | null {
    if (fetchedItems.length === 0) {
      return EXHAUSTED_MARKER;
    }
    if (consumedCount === 0) {
      return incomingCursor;
    }
    if (consumedCount < fetchedItems.length) {
      return encodeItemCursor(fetchedItems[consumedCount - 1]);
    }
    return sourceNextCursor ?? EXHAUSTED_MARKER;
  }
}
