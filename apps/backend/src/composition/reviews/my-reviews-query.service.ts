import { Injectable } from '@nestjs/common';
import { StationQueryService, StationReviewListItem } from '../../modules/station-network/application/station-query.service';
import {
  ThirdPartyPlaceQueryService,
  ThirdPartyPlaceReviewListItem,
} from '../../modules/third-party-places/application/third-party-place-query.service';
import { EXHAUSTED_MARKER, decodeMergeCursor, encodeItemCursor, encodeMergeCursor } from './my-reviews-merge-cursor';

export type MyReviewListItem = (StationReviewListItem | ThirdPartyPlaceReviewListItem) & {
  placeType: 'station' | 'third-party-place';
};

export interface MyReviewsListPage {
  data: MyReviewListItem[];
  nextCursor: string | null;
}

interface SourcePage<T> {
  data: readonly T[];
  nextCursor: string | null;
}

/**
 * Read-only cross-context composition for GET /users/me/reviews (EPIC-05
 * US-05.2) — mirrors composition/places's PlacesQueryService exactly (ADR-0029
 * rule 3: "any future endpoint that is genuinely a unified read model
 * spanning both contexts"). Depends ONLY on StationNetworkModule's and
 * ThirdPartyPlacesModule's exported *QueryService — never their domain/
 * infrastructure layers. Writes (review update/delete) stay inside each
 * owning module's own controller (ADR-0029 rule 3) — this layer is read-only.
 */
@Injectable()
export class MyReviewsQueryService {
  constructor(
    private readonly stationQueryService: StationQueryService,
    private readonly thirdPartyPlaceQueryService: ThirdPartyPlaceQueryService,
  ) {}

  async listForUser(userId: string, cursor: string | null, limit: number): Promise<MyReviewsListPage> {
    const incoming = decodeMergeCursor(cursor);

    const [stationPage, thirdPartyPage] = await Promise.all([
      incoming.station === EXHAUSTED_MARKER
        ? ({ data: [], nextCursor: null } satisfies SourcePage<StationReviewListItem>)
        : this.stationQueryService.listReviewsByUserId(userId, incoming.station, limit),
      incoming.thirdParty === EXHAUSTED_MARKER
        ? ({ data: [], nextCursor: null } satisfies SourcePage<ThirdPartyPlaceReviewListItem>)
        : this.thirdPartyPlaceQueryService.listReviewsByUserId(userId, incoming.thirdParty, limit),
    ]);

    const tagged: Array<{ item: MyReviewListItem; source: 'station' | 'thirdParty' }> = [
      ...stationPage.data.map((item) => ({ item: { ...item, placeType: 'station' as const }, source: 'station' as const })),
      ...thirdPartyPage.data.map((item) => ({
        item: { ...item, placeType: 'third-party-place' as const },
        source: 'thirdParty' as const,
      })),
    ].sort((a, b) => b.item.createdAt.getTime() - a.item.createdAt.getTime() || a.source.localeCompare(b.source));

    const taken = tagged.slice(0, limit);
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

  /** Same resume-position logic as PlacesQueryService.nextSourceCursor — see that method's doc comment for the four cases. */
  private nextSourceCursor(
    consumedCount: number,
    fetchedItems: readonly { createdAt: Date; id: string }[],
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
