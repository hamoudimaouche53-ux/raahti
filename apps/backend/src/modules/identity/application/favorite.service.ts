import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Favorite } from '../domain/entities/favorite.entity';
import { FAVORITE_REPOSITORY, FavoritePage, FavoriteRepository } from '../domain/ports/favorite.repository';

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
}
