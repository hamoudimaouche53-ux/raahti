import { ThirdPartyPlaceReview } from '../entities/review.entity';

export const THIRD_PARTY_PLACE_REVIEW_REPOSITORY = Symbol('THIRD_PARTY_PLACE_REVIEW_REPOSITORY');

export interface ThirdPartyPlaceRatingAggregate {
  averageRating: number | null;
  reviewCount: number;
}

export interface ThirdPartyPlaceReviewPage {
  data: ThirdPartyPlaceReview[];
  nextCursor: string | null;
}

export interface ThirdPartyPlaceReviewRepository {
  /** Upsert-by-id — used for both the create path (submit) and the update path (EPIC-05 US-05.2). */
  save(review: ThirdPartyPlaceReview): Promise<void>;
  findById(id: string): Promise<ThirdPartyPlaceReview | null>;
  /** GET /users/me/reviews source query (EPIC-05 US-05.2) — newest first, cursor-paginated (see infrastructure/review-cursor.ts). */
  listByUserId(userId: string, cursor: string | null, limit: number): Promise<ThirdPartyPlaceReviewPage>;
  delete(id: string): Promise<void>;
  /**
   * Derived read-model aggregate (ERD §3.4 note — computed, never stored).
   * Only used by the single-place detail path — the nearby-search path
   * computes the same aggregate inline in its own SQL to avoid an N+1 round trip.
   */
  aggregateByThirdPartyPlaceId(thirdPartyPlaceId: string): Promise<ThirdPartyPlaceRatingAggregate>;
}
