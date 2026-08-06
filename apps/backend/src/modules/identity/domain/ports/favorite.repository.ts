import { Favorite } from '../entities/favorite.entity';

export const FAVORITE_REPOSITORY = Symbol('FAVORITE_REPOSITORY');

export interface FavoritePage {
  data: Favorite[];
  nextCursor: string | null;
}

export interface FavoriteRepository {
  save(favorite: Favorite): Promise<void>;
  listByUserId(userId: string, cursor: string | null, limit: number): Promise<FavoritePage>;
  findById(id: string): Promise<Favorite | null>;
  delete(id: string): Promise<void>;
}
