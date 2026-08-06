import { DomainException } from '../../../../shared-kernel';

export class InvalidReviewRatingException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_REVIEW_RATING';
  readonly status = 400;

  constructor(rating: number) {
    super(`Rating ${rating} must be an integer between 1 and 5.`);
  }
}

export interface StationReviewProps {
  id: string;
  userId: string;
  stationId: string;
  rating: number;
  comment: string | null;
  createdAt: Date;
}

/**
 * ERD §3.15 — this module's own independent copy of the polymorphic Review
 * concept, scoped to Station (see ADR-0029: StationNetworkModule and
 * ThirdPartyPlacesModule each keep their own Review entity/repository,
 * backed by the same shared `review` table, rather than sharing one domain
 * type across bounded contexts).
 */
export class StationReview {
  private constructor(private props: StationReviewProps) {}

  private static assertValidRating(rating: number): void {
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw new InvalidReviewRatingException(rating);
    }
  }

  static submit(params: { id: string; userId: string; stationId: string; rating: number; comment?: string | null }): StationReview {
    StationReview.assertValidRating(params.rating);
    return new StationReview({
      id: params.id,
      userId: params.userId,
      stationId: params.stationId,
      rating: params.rating,
      comment: params.comment ?? null,
      createdAt: new Date(),
    });
  }

  static restore(props: StationReviewProps): StationReview {
    return new StationReview(props);
  }

  /**
   * PATCH /places/station/{stationId}/reviews/{reviewId} (EPIC-05 US-05.2)
   * mutator — `props` made mutable (readonly dropped), same pattern as
   * `Cabin.changeOccupancy`. Reuses the same rating validation `submit()` uses.
   */
  update(rating: number, comment?: string | null): void {
    StationReview.assertValidRating(rating);
    this.props = { ...this.props, rating, comment: comment ?? null };
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string {
    return this.props.userId;
  }

  get stationId(): string {
    return this.props.stationId;
  }

  get rating(): number {
    return this.props.rating;
  }

  get comment(): string | null {
    return this.props.comment;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }
}
