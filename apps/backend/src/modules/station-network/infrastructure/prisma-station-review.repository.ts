import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../platform/database/prisma.service';
import { StationReview } from '../domain/entities/review.entity';
import { StationRatingAggregate, StationReviewRepository } from '../domain/ports/station-review.repository';

@Injectable()
export class PrismaStationReviewRepository implements StationReviewRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(review: StationReview): Promise<void> {
    await this.prisma.review.create({
      data: {
        id: review.id,
        userId: review.userId,
        stationId: review.stationId,
        thirdPartyPlaceId: null,
        rating: review.rating,
        comment: review.comment,
      },
    });
  }

  async aggregateByStationId(stationId: string): Promise<StationRatingAggregate> {
    const result = await this.prisma.review.aggregate({
      where: { stationId },
      _avg: { rating: true },
      _count: { _all: true },
    });
    return {
      averageRating: result._avg.rating,
      reviewCount: result._count._all,
    };
  }
}
