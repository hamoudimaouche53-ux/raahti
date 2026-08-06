import { Favorite } from '../domain/entities/favorite.entity';
import { FavoriteRepository } from '../domain/ports/favorite.repository';
import { InvalidFavoriteTargetException } from '../domain/entities/favorite.entity';
import { FavoriteForbiddenException } from './favorite-forbidden.exception';
import { FavoriteNotFoundException } from './favorite-not-found.exception';
import { FavoriteService } from './favorite.service';

function createMockRepo(): jest.Mocked<FavoriteRepository> {
  return { save: jest.fn(), listByUserId: jest.fn(), findById: jest.fn(), delete: jest.fn() };
}

describe('FavoriteService', () => {
  it('creates a station favorite', async () => {
    const repo = createMockRepo();
    const service = new FavoriteService(repo);

    const favorite = await service.create('u1', { stationId: 's1' });

    expect(favorite.stationId).toBe('s1');
    expect(repo.save).toHaveBeenCalledWith(favorite);
  });

  it('rejects a favorite with no target', async () => {
    const repo = createMockRepo();
    const service = new FavoriteService(repo);

    await expect(service.create('u1', {})).rejects.toThrow(InvalidFavoriteTargetException);
  });

  it('lists a page of favorites via the repository', async () => {
    const repo = createMockRepo();
    repo.listByUserId.mockResolvedValue({ data: [], nextCursor: null });
    const service = new FavoriteService(repo);

    await service.list('u1', 'cursor1', 10);

    expect(repo.listByUserId).toHaveBeenCalledWith('u1', 'cursor1', 10);
  });

  describe('remove', () => {
    it('throws FavoriteNotFoundException when the favorite does not exist', async () => {
      const repo = createMockRepo();
      repo.findById.mockResolvedValue(null);
      const service = new FavoriteService(repo);

      await expect(service.remove('u1', 'f1')).rejects.toThrow(FavoriteNotFoundException);
      expect(repo.delete).not.toHaveBeenCalled();
    });

    it('throws FavoriteForbiddenException when the caller is not the owner', async () => {
      const repo = createMockRepo();
      const favorite = Favorite.create({ id: 'f1', userId: 'owner', stationId: 's1' });
      repo.findById.mockResolvedValue(favorite);
      const service = new FavoriteService(repo);

      await expect(service.remove('someone-else', 'f1')).rejects.toThrow(FavoriteForbiddenException);
      expect(repo.delete).not.toHaveBeenCalled();
    });

    it('deletes the favorite when the caller is the owner', async () => {
      const repo = createMockRepo();
      const favorite = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });
      repo.findById.mockResolvedValue(favorite);
      const service = new FavoriteService(repo);

      await service.remove('u1', 'f1');

      expect(repo.delete).toHaveBeenCalledWith('f1');
    });
  });

  describe('updateNotify', () => {
    it('throws FavoriteNotFoundException when the favorite does not exist', async () => {
      const repo = createMockRepo();
      repo.findById.mockResolvedValue(null);
      const service = new FavoriteService(repo);

      await expect(service.updateNotify('u1', 'f1', true)).rejects.toThrow(FavoriteNotFoundException);
      expect(repo.save).not.toHaveBeenCalled();
    });

    it('throws FavoriteForbiddenException when the caller is not the owner', async () => {
      const repo = createMockRepo();
      const favorite = Favorite.create({ id: 'f1', userId: 'owner', stationId: 's1' });
      repo.findById.mockResolvedValue(favorite);
      const service = new FavoriteService(repo);

      await expect(service.updateNotify('someone-else', 'f1', true)).rejects.toThrow(FavoriteForbiddenException);
      expect(repo.save).not.toHaveBeenCalled();
    });

    it('flips notifyOnAvailable and persists when the caller is the owner', async () => {
      const repo = createMockRepo();
      const favorite = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1', notifyOnAvailable: false });
      repo.findById.mockResolvedValue(favorite);
      const service = new FavoriteService(repo);

      const result = await service.updateNotify('u1', 'f1', true);

      expect(result.notifyOnAvailable).toBe(true);
      expect(repo.save).toHaveBeenCalledWith(favorite);
    });
  });
});
