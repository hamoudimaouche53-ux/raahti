import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { StationReview } from '../domain/entities/review.entity';
import {
  STATION_REVIEW_REPOSITORY,
  StationReviewPage,
  StationReviewRepository,
} from '../domain/ports/station-review.repository';
import { ReviewForbiddenException } from './review-forbidden.exception';
import { ReviewNotFoundException } from './review-not-found.exception';

@Injectable()
export class ReviewService {
  constructor(@Inject(STATION_REVIEW_REPOSITORY) private readonly stationReviewRepository: StationReviewRepository) {}

  /** POST /places/station/{stationId}/reviews (FR-PLC-01). */
  async submit(userId: string, stationId: string, params: { rating: number; comment?: string | null }): Promise<StationReview> {
    const review = StationReview.submit({
      id: randomUUID(),
      userId,
      stationId,
      rating: params.rating,
      comment: params.comment,
    });
    await this.stationReviewRepository.save(review);
    return review;
  }

  /**
   * PATCH /places/station/{stationId}/reviews/{reviewId} (EPIC-05 US-05.2) —
   * ownership check mirrors CompleteAccessSessionService.execute (load by id,
   * `.userId !== callerId` -> Forbidden). Also verifies the review actually
   * belongs to `stationId` before exposing it — defense-in-depth, throws the
   * same not-found exception as "doesn't exist" so existence isn't leaked.
   */
  async update(
    userId: string,
    stationId: string,
    reviewId: string,
    params: { rating: number; comment?: string | null },
  ): Promise<StationReview> {
    const review = await this.loadOwnedReview(userId, stationId, reviewId);
    review.update(params.rating, params.comment);
    await this.stationReviewRepository.save(review);
    return review;
  }

  /** DELETE /places/station/{stationId}/reviews/{reviewId} (EPIC-05 US-05.2). */
  async delete(userId: string, stationId: string, reviewId: string): Promise<void> {
    await this.loadOwnedReview(userId, stationId, reviewId);
    await this.stationReviewRepository.delete(reviewId);
  }

  /**
   * GET /users/me/reviews source (EPIC-05 US-05.2) — thin delegate to the
   * repository; exported so the Reviews composition layer's read model can
   * call it without depending on this module's domain/infrastructure layers.
   */
  async listByUserId(userId: string, cursor: string | null, limit: number): Promise<StationReviewPage> {
    return this.stationReviewRepository.listByUserId(userId, cursor, limit);
  }

  private async loadOwnedReview(userId: string, stationId: string, reviewId: string): Promise<StationReview> {
    const review = await this.stationReviewRepository.findById(reviewId);
    if (!review || review.stationId !== stationId) {
      throw new ReviewNotFoundException(reviewId);
    }
    if (review.userId !== userId) {
      throw new ReviewForbiddenException(reviewId);
    }
    return review;
  }
}
