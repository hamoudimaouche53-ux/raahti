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
  private constructor(private readonly props: StationReviewProps) {}

  static submit(params: { id: string; userId: string; stationId: string; rating: number; comment?: string | null }): StationReview {
    if (!Number.isInteger(params.rating) || params.rating < 1 || params.rating > 5) {
      throw new InvalidReviewRatingException(params.rating);
    }
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
