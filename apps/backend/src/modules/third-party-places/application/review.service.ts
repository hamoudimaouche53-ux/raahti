import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceReviewPage,
  ThirdPartyPlaceReviewRepository,
} from '../domain/ports/third-party-place-review.repository';
import { ReviewForbiddenException } from './review-forbidden.exception';
import { ReviewNotFoundException } from './review-not-found.exception';

@Injectable()
export class ReviewService {
  constructor(
    @Inject(THIRD_PARTY_PLACE_REVIEW_REPOSITORY)
    private readonly thirdPartyPlaceReviewRepository: ThirdPartyPlaceReviewRepository,
  ) {}

  /** POST /places/third-party-place/{placeId}/reviews (FR-PLC-01). */
  async submit(
    userId: string,
    thirdPartyPlaceId: string,
    params: { rating: number; comment?: string | null },
  ): Promise<ThirdPartyPlaceReview> {
    const review = ThirdPartyPlaceReview.submit({
      id: randomUUID(),
      userId,
      thirdPartyPlaceId,
      rating: params.rating,
      comment: params.comment,
    });
    await this.thirdPartyPlaceReviewRepository.save(review);
    return review;
  }

  /**
   * PATCH /places/third-party-place/{placeId}/reviews/{reviewId} (EPIC-05
   * US-05.2) — ownership check mirrors AccessPayment's
   * CompleteAccessSessionService.execute (load by id, `.userId !== callerId`
   * -> Forbidden). Also verifies the review actually belongs to
   * `thirdPartyPlaceId` before exposing it — defense-in-depth, throws the
   * same not-found exception as "doesn't exist" so existence isn't leaked.
   */
  async update(
    userId: string,
    thirdPartyPlaceId: string,
    reviewId: string,
    params: { rating: number; comment?: string | null },
  ): Promise<ThirdPartyPlaceReview> {
    const review = await this.loadOwnedReview(userId, thirdPartyPlaceId, reviewId);
    review.update(params.rating, params.comment);
    await this.thirdPartyPlaceReviewRepository.save(review);
    return review;
  }

  /** DELETE /places/third-party-place/{placeId}/reviews/{reviewId} (EPIC-05 US-05.2). */
  async delete(userId: string, thirdPartyPlaceId: string, reviewId: string): Promise<void> {
    await this.loadOwnedReview(userId, thirdPartyPlaceId, reviewId);
    await this.thirdPartyPlaceReviewRepository.delete(reviewId);
  }

  /**
   * GET /users/me/reviews source (EPIC-05 US-05.2) — thin delegate to the
   * repository; exported so the Reviews composition layer's read model can
   * call it without depending on this module's domain/infrastructure layers.
   */
  async listByUserId(userId: string, cursor: string | null, limit: number): Promise<ThirdPartyPlaceReviewPage> {
    return this.thirdPartyPlaceReviewRepository.listByUserId(userId, cursor, limit);
  }

  private async loadOwnedReview(userId: string, thirdPartyPlaceId: string, reviewId: string): Promise<ThirdPartyPlaceReview> {
    const review = await this.thirdPartyPlaceReviewRepository.findById(reviewId);
    if (!review || review.thirdPartyPlaceId !== thirdPartyPlaceId) {
      throw new ReviewNotFoundException(reviewId);
    }
    if (review.userId !== userId) {
      throw new ReviewForbiddenException(reviewId);
    }
    return review;
  }
}
