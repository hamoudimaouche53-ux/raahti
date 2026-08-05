import { Favorite } from '../domain/entities/favorite.entity';
import { PrismaFavoriteRepository } from './prisma-favorite.repository';

function createPrismaMock() {
  return { favorite: { create: jest.fn(), findMany: jest.fn() } } as any;
}

function record(id: string) {
  return {
    id,
    userId: 'u1',
    stationId: 's1',
    thirdPartyPlaceId: null,
    notifyOnAvailable: false,
    createdAt: new Date(),
  };
}

describe('PrismaFavoriteRepository', () => {
  it('creates a favorite row from the domain entity', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaFavoriteRepository(prisma);
    const favorite = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });

    await repo.save(favorite);

    expect(prisma.favorite.create).toHaveBeenCalledWith({
      data: { id: 'f1', userId: 'u1', stationId: 's1', thirdPartyPlaceId: null, notifyOnAvailable: false },
    });
  });

  it('returns nextCursor null when the page is not full', async () => {
    const prisma = createPrismaMock();
    prisma.favorite.findMany.mockResolvedValue([record('f1'), record('f2')]);
    const repo = new PrismaFavoriteRepository(prisma);

    const page = await repo.listByUserId('u1', null, 20);

    expect(page.data).toHaveLength(2);
    expect(page.nextCursor).toBeNull();
  });

  it('returns nextCursor when more results exist beyond the limit', async () => {
    const prisma = createPrismaMock();
    prisma.favorite.findMany.mockResolvedValue([record('f1'), record('f2'), record('f3')]);
    const repo = new PrismaFavoriteRepository(prisma);

    const page = await repo.listByUserId('u1', null, 2);

    expect(page.data).toHaveLength(2);
    expect(page.nextCursor).toBe('f2');
    expect(prisma.favorite.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'u1' }, take: 3 }),
    );
  });

  it('passes the cursor through to Prisma when provided', async () => {
    const prisma = createPrismaMock();
    prisma.favorite.findMany.mockResolvedValue([]);
    const repo = new PrismaFavoriteRepository(prisma);

    await repo.listByUserId('u1', 'f2', 20);

    expect(prisma.favorite.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ cursor: { id: 'f2' }, skip: 1 }),
    );
  });
});
