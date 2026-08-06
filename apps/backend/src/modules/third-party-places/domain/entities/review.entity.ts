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
  private constructor(private props: ThirdPartyPlaceReviewProps) {}

  private static assertValidRating(rating: number): void {
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw new InvalidReviewRatingException(rating);
    }
  }

  static submit(params: {
    id: string;
    userId: string;
    thirdPartyPlaceId: string;
    rating: number;
    comment?: string | null;
  }): ThirdPartyPlaceReview {
    ThirdPartyPlaceReview.assertValidRating(params.rating);
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

  /**
   * PATCH /places/third-party-place/{placeId}/reviews/{reviewId} (EPIC-05
   * US-05.2) mutator — `props` made mutable (readonly dropped), same pattern
   * as station-network's `Cabin.changeOccupancy`. Reuses the same rating
   * validation `submit()` uses.
   */
  update(rating: number, comment?: string | null): void {
    ThirdPartyPlaceReview.assertValidRating(rating);
    this.props = { ...this.props, rating, comment: comment ?? null };
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
