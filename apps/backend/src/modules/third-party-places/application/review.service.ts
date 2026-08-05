import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceReviewRepository,
} from '../domain/ports/third-party-place-review.repository';

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
}
