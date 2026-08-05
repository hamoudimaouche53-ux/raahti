import { StationReview } from '../entities/review.entity';

export const STATION_REVIEW_REPOSITORY = Symbol('STATION_REVIEW_REPOSITORY');

export interface StationRatingAggregate {
  averageRating: number | null;
  reviewCount: number;
}

export interface StationReviewRepository {
  save(review: StationReview): Promise<void>;
  /**
   * Derived read-model aggregate (ERD §3.4 note — computed, never stored).
   * Only used by the single-station detail path (GET /stations/{id}) — the
   * nearby-search path computes the same aggregate inline in its own SQL
   * (PrismaStationRepository.searchNearby) to avoid an N+1 round trip.
   */
  aggregateByStationId(stationId: string): Promise<StationRatingAggregate>;
}
