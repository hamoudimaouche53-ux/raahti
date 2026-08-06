import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Favorite } from '../domain/entities/favorite.entity';
import { FAVORITE_REPOSITORY, FavoritePage, FavoriteRepository } from '../domain/ports/favorite.repository';
import { FavoriteForbiddenException } from './favorite-forbidden.exception';
import { FavoriteNotFoundException } from './favorite-not-found.exception';

@Injectable()
export class FavoriteService {
  constructor(@Inject(FAVORITE_REPOSITORY) private readonly favoriteRepository: FavoriteRepository) {}

  /** GET /users/me/favorites (FR-USR-04), cursor-paginated (api-architecture.md §6). */
  async list(userId: string, cursor: string | null, limit: number): Promise<FavoritePage> {
    return this.favoriteRepository.listByUserId(userId, cursor, limit);
  }

  /** POST /users/me/favorites (FR-USR-04). */
  async create(
    userId: string,
    params: { stationId?: string | null; thirdPartyPlaceId?: string | null; notifyOnAvailable?: boolean },
  ): Promise<Favorite> {
    const favorite = Favorite.create({
      id: randomUUID(),
      userId,
      stationId: params.stationId,
      thirdPartyPlaceId: params.thirdPartyPlaceId,
      notifyOnAvailable: params.notifyOnAvailable,
    });
    await this.favoriteRepository.save(favorite);
    return favorite;
  }

  /** DELETE /users/me/favorites/{favoriteId} (FR-USR-04). */
  async remove(userId: string, favoriteId: string): Promise<void> {
    const favorite = await this.favoriteRepository.findById(favoriteId);
    if (!favorite) {
      throw new FavoriteNotFoundException(favoriteId);
    }
    if (favorite.userId !== userId) {
      throw new FavoriteForbiddenException(favoriteId);
    }
    await this.favoriteRepository.delete(favoriteId);
  }

  /** PATCH /users/me/favorites/{favoriteId} (FR-USR-04) — toggles the availability-follow notification. */
  async updateNotify(userId: string, favoriteId: string, notifyOnAvailable: boolean): Promise<Favorite> {
    const favorite = await this.favoriteRepository.findById(favoriteId);
    if (!favorite) {
      throw new FavoriteNotFoundException(favoriteId);
    }
    if (favorite.userId !== userId) {
      throw new FavoriteForbiddenException(favoriteId);
    }
    favorite.setNotifyOnAvailable(notifyOnAvailable);
    await this.favoriteRepository.save(favorite);
    return favorite;
  }
}
