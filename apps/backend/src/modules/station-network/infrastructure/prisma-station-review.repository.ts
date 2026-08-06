import { Injectable } from '@nestjs/common';
import { Review as PrismaReview } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { StationReview } from '../domain/entities/review.entity';
import { StationRatingAggregate, StationReviewPage, StationReviewRepository } from '../domain/ports/station-review.repository';
import { decodeReviewCursor, encodeReviewCursor } from './review-cursor';

const DEFAULT_LIMIT = 20;

@Injectable()
export class PrismaStationReviewRepository implements StationReviewRepository {
  constructor(private readonly prisma: PrismaService) {}

  /** Upsert-by-id (create for submit(), update for update() — EPIC-05 US-05.2). */
  async save(review: StationReview): Promise<void> {
    await this.prisma.review.upsert({
      where: { id: review.id },
      create: {
        id: review.id,
        userId: review.userId,
        stationId: review.stationId,
        thirdPartyPlaceId: null,
        rating: review.rating,
        comment: review.comment,
      },
      update: {
        rating: review.rating,
        comment: review.comment,
      },
    });
  }

  async findById(id: string): Promise<StationReview | null> {
    const record = await this.prisma.review.findUnique({ where: { id } });
    if (!record || record.stationId === null) {
      // Defense-in-depth: a review id that belongs to a third-party place
      // (shared `review` table, ADR-0029) is never visible through this
      // module's repository — the caller sees "not found", not leaked data.
      return null;
    }
    return this.toDomain(record);
  }

  async listByUserId(userId: string, cursor: string | null, limit: number = DEFAULT_LIMIT): Promise<StationReviewPage> {
    const decoded = cursor ? decodeReviewCursor(cursor) : null;

    const records = await this.prisma.review.findMany({
      where: {
        userId,
        stationId: { not: null },
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

  private toDomain(record: PrismaReview): StationReview {
    return StationReview.restore({
      id: record.id,
      userId: record.userId,
      stationId: record.stationId as string,
      rating: record.rating,
      comment: record.comment,
      createdAt: record.createdAt,
    });
  }
}
