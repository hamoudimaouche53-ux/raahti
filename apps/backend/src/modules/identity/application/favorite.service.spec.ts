import { FavoriteRepository } from '../domain/ports/favorite.repository';
import { InvalidFavoriteTargetException } from '../domain/entities/favorite.entity';
import { FavoriteService } from './favorite.service';

describe('FavoriteService', () => {
  it('creates a station favorite', async () => {
    const repo: jest.Mocked<FavoriteRepository> = { save: jest.fn(), listByUserId: jest.fn() };
    const service = new FavoriteService(repo);

    const favorite = await service.create('u1', { stationId: 's1' });

    expect(favorite.stationId).toBe('s1');
    expect(repo.save).toHaveBeenCalledWith(favorite);
  });

  it('rejects a favorite with no target', async () => {
    const repo: jest.Mocked<FavoriteRepository> = { save: jest.fn(), listByUserId: jest.fn() };
    const service = new FavoriteService(repo);

    await expect(service.create('u1', {})).rejects.toThrow(InvalidFavoriteTargetException);
  });

  it('lists a page of favorites via the repository', async () => {
    const repo: jest.Mocked<FavoriteRepository> = {
      save: jest.fn(),
      listByUserId: jest.fn().mockResolvedValue({ data: [], nextCursor: null }),
    };
    const service = new FavoriteService(repo);

    await service.list('u1', 'cursor1', 10);

    expect(repo.listByUserId).toHaveBeenCalledWith('u1', 'cursor1', 10);
  });
});
