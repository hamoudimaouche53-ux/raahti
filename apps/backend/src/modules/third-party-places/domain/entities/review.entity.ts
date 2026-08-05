import { DomainException } from '../../../../shared-kernel';

export class InvalidReviewRatingException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_REVIEW_RATING';
  readonly status = 400;

  constructor(rating: number) {
    super(`Rating ${rating} must be an integer between 1 and 5.`);
  }
}

export interface ThirdPartyPlaceReviewProps {
  id: string;
  userId: string;
  thirdPartyPlaceId: string;
  rating: number;
  comment: string | null;
  createdAt: Date;
}

/** ERD §3.15 — this module's own independent copy of the polymorphic Review concept, scoped to ThirdPartyPlace (see station-network's copy for the ADR-0029 rationale). */
export class ThirdPartyPlaceReview {
  private constructor(private readonly props: ThirdPartyPlaceReviewProps) {}

  static submit(params: {
    id: string;
    userId: string;
    thirdPartyPlaceId: string;
    rating: number;
    comment?: string | null;
  }): ThirdPartyPlaceReview {
    if (!Number.isInteger(params.rating) || params.rating < 1 || params.rating > 5) {
      throw new InvalidReviewRatingException(params.rating);
    }
    return new ThirdPartyPlaceReview({
      id: params.id,
      userId: params.userId,
      thirdPartyPlaceId: params.thirdPartyPlaceId,
      rating: params.rating,
      comment: params.comment ?? null,
      createdAt: new Date(),
    });
  }

  static restore(props: ThirdPartyPlaceReviewProps): ThirdPartyPlaceReview {
    return new ThirdPartyPlaceReview(props);
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string {
    return this.props.userId;
  }

  get thirdPartyPlaceId(): string {
    return this.props.thirdPartyPlaceId;
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
