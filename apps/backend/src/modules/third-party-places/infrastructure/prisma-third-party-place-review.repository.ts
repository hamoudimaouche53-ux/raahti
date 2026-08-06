import { Injectable } from '@nestjs/common';
import { Review as PrismaReview } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import {
  ThirdPartyPlaceRatingAggregate,
  ThirdPartyPlaceReviewPage,
  ThirdPartyPlaceReviewRepository,
} from '../domain/ports/third-party-place-review.repository';
import { decodeReviewCursor, encodeReviewCursor } from './review-cursor';

const DEFAULT_LIMIT = 20;

@Injectable()
export class PrismaThirdPartyPlaceReviewRepository implements ThirdPartyPlaceReviewRepository {
  constructor(private readonly prisma: PrismaService) {}

  /** Upsert-by-id (create for submit(), update for update() — EPIC-05 US-05.2). */
  async save(review: ThirdPartyPlaceReview): Promise<void> {
    await this.prisma.review.upsert({
      where: { id: review.id },
      create: {
        id: review.id,
        userId: review.userId,
        stationId: null,
        thirdPartyPlaceId: review.thirdPartyPlaceId,
        rating: review.rating,
        comment: review.comment,
      },
      update: {
        rating: review.rating,
        comment: review.comment,
      },
    });
  }

  async findById(id: string): Promise<ThirdPartyPlaceReview | null> {
    const record = await this.prisma.review.findUnique({ where: { id } });
    if (!record || record.thirdPartyPlaceId === null) {
      // Defense-in-depth: a review id that belongs to a station (shared
      // `review` table, ADR-0029) is never visible through this module's
      // repository — the caller sees "not found", not leaked data.
      return null;
    }
    return this.toDomain(record);
  }

  async listByUserId(
    userId: string,
    cursor: string | null,
    limit: number = DEFAULT_LIMIT,
  ): Promise<ThirdPartyPlaceReviewPage> {
    const decoded = cursor ? decodeReviewCursor(cursor) : null;

    const records = await this.prisma.review.findMany({
      where: {
        userId,
        thirdPartyPlaceId: { not: null },
        ...(decoded
          ? {
              OR: [
                { createdAt: { lt: new Date(decoded.createdAt) } },
                { createdAt: new Date(decoded.createdAt), id: { lt: decoded.id } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });

    const hasMore = records.length > limit;
    const page = hasMore ? records.slice(0, limit) : records;
    const last = page[page.length - 1];

    return {
      data: page.map((record) => this.toDomain(record)),
      nextCursor: hasMore ? encodeReviewCursor({ createdAt: last.createdAt.toISOString(), id: last.id }) : null,
    };
  }

  async delete(id: string): Promise<void> {
    await this.prisma.review.delete({ where: { id } });
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

  private toDomain(record: PrismaReview): ThirdPartyPlaceReview {
    return ThirdPartyPlaceReview.restore({
      id: record.id,
      userId: record.userId,
      thirdPartyPlaceId: record.thirdPartyPlaceId as string,
      rating: record.rating,
      comment: record.comment,
      createdAt: record.createdAt,
    });
  }
}
