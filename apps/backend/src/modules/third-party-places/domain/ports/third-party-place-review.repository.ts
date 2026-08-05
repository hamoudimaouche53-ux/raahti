import { ThirdPartyPlaceReview } from '../entities/review.entity';

export const THIRD_PARTY_PLACE_REVIEW_REPOSITORY = Symbol('THIRD_PARTY_PLACE_REVIEW_REPOSITORY');

export interface ThirdPartyPlaceRatingAggregate {
  averageRating: number | null;
  reviewCount: number;
}

export interface ThirdPartyPlaceReviewRepository {
  save(review: ThirdPartyPlaceReview): Promise<void>;
  /**
   * Derived read-model aggregate (ERD §3.4 note — computed, never stored).
   * Only used by the single-place detail path — the nearby-search path
   * computes the same aggregate inline in its own SQL to avoid an N+1 round trip.
   */
  aggregateByThirdPartyPlaceId(thirdPartyPlaceId: string): Promise<ThirdPartyPlaceRatingAggregate>;
}
