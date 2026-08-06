import { StationReview } from '../entities/review.entity';

export const STATION_REVIEW_REPOSITORY = Symbol('STATION_REVIEW_REPOSITORY');

export interface StationRatingAggregate {
  averageRating: number | null;
  reviewCount: number;
}

export interface StationReviewPage {
  data: StationReview[];
  nextCursor: string | null;
}

export interface StationReviewRepository {
  /** Upsert-by-id — used for both the create path (submit) and the update path (EPIC-05 US-05.2). */
  save(review: StationReview): Promise<void>;
  findById(id: string): Promise<StationReview | null>;
  /** GET /users/me/reviews source query (EPIC-05 US-05.2) — newest first, cursor-paginated (see infrastructure/review-cursor.ts). */
  listByUserId(userId: string, cursor: string | null, limit: number): Promise<StationReviewPage>;
  delete(id: string): Promise<void>;
  /**
   * Derived read-model aggregate (ERD §3.4 note — computed, never stored).
   * Only used by the single-station detail path (GET /stations/{id}) — the
   * nearby-search path computes the same aggregate inline in its own SQL
   * (PrismaStationRepository.searchNearby) to avoid an N+1 round trip.
   */
  aggregateByStationId(stationId: string): Promise<StationRatingAggregate>;
}
