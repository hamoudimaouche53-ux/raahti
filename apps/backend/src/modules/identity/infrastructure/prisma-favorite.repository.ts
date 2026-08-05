import { Injectable } from '@nestjs/common';
import { Favorite as PrismaFavorite } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { Favorite } from '../domain/entities/favorite.entity';
import { FavoritePage, FavoriteRepository } from '../domain/ports/favorite.repository';

const DEFAULT_LIMIT = 20;

@Injectable()
export class PrismaFavoriteRepository implements FavoriteRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(favorite: Favorite): Promise<void> {
    await this.prisma.favorite.create({
      data: {
        id: favorite.id,
        userId: favorite.userId,
        stationId: favorite.stationId,
        thirdPartyPlaceId: favorite.thirdPartyPlaceId,
        notifyOnAvailable: favorite.notifyOnAvailable,
      },
    });
  }

  async listByUserId(userId: string, cursor: string | null, limit: number = DEFAULT_LIMIT): Promise<FavoritePage> {
    const records = await this.prisma.favorite.findMany({
      where: { userId },
      orderBy: { id: 'asc' },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    });

    const hasMore = records.length > limit;
    const page = hasMore ? records.slice(0, limit) : records;

    return {
      data: page.map((record) => this.toDomain(record)),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  private toDomain(record: PrismaFavorite): Favorite {
    return Favorite.restore({
      id: record.id,
      userId: record.userId,
      stationId: record.stationId,
      thirdPartyPlaceId: record.thirdPartyPlaceId,
      notifyOnAvailable: record.notifyOnAvailable,
      createdAt: record.createdAt,
    });
  }
}
