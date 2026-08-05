import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { StationReview } from '../domain/entities/review.entity';
import { STATION_REVIEW_REPOSITORY, StationReviewRepository } from '../domain/ports/station-review.repository';

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
}
