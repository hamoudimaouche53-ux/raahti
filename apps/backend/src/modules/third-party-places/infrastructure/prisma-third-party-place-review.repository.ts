import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../platform/database/prisma.service';
import { ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import {
  ThirdPartyPlaceRatingAggregate,
  ThirdPartyPlaceReviewRepository,
} from '../domain/ports/third-party-place-review.repository';

@Injectable()
export class PrismaThirdPartyPlaceReviewRepository implements ThirdPartyPlaceReviewRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(review: ThirdPartyPlaceReview): Promise<void> {
    await this.prisma.review.create({
      data: {
        id: review.id,
        userId: review.userId,
        stationId: null,
        thirdPartyPlaceId: review.thirdPartyPlaceId,
        rating: review.rating,
        comment: review.comment,
      },
    });
  }

  async aggregateByThirdPartyPlaceId(thirdPartyPlaceId: string): Promise<ThirdPartyPlaceRatingAggregate> {
    const result = await this.prisma.review.aggregate({
      where: { thirdPartyPlaceId },
      _avg: { rating: true },
      _count: { _all: true },
    });
    return {
      averageRating: result._avg.rating,
      reviewCount: result._count._all,
    };
  }
}
