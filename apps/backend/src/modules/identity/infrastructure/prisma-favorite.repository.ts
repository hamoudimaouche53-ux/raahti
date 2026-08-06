import { Injectable } from '@nestjs/common';
import { Favorite as PrismaFavorite } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { Favorite } from '../domain/entities/favorite.entity';
import { FavoritePage, FavoriteRepository } from '../domain/ports/favorite.repository';

const DEFAULT_LIMIT = 20;

@Injectable()
export class PrismaFavoriteRepository implements FavoriteRepository {
  constructor(private readonly prisma: PrismaService) {}

  /** Upsert-by-id — also serves as the update path for PATCH /users/me/favorites/{favoriteId} (mirrors PrismaAccessSessionRepository.save). */
  async save(favorite: Favorite): Promise<void> {
    await this.prisma.favorite.upsert({
      where: { id: favorite.id },
      create: {
        id: favorite.id,
        userId: favorite.userId,
        stationId: favorite.stationId,
        thirdPartyPlaceId: favorite.thirdPartyPlaceId,
        notifyOnAvailable: favorite.notifyOnAvailable,
      },
      update: {
        notifyOnAvailable: favorite.notifyOnAvailable,
      },
    });
  }

  async findById(id: string): Promise<Favorite | null> {
    const record = await this.prisma.favorite.findUnique({ where: { id } });
    return record ? this.toDomain(record) : null;
  }

  async delete(id: string): Promise<void> {
    await this.prisma.favorite.delete({ where: { id } });
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
