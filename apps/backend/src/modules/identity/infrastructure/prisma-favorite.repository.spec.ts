import { Favorite } from '../domain/entities/favorite.entity';
import { PrismaFavoriteRepository } from './prisma-favorite.repository';

function createPrismaMock() {
  return {
    favorite: { create: jest.fn(), findMany: jest.fn(), upsert: jest.fn(), findUnique: jest.fn(), delete: jest.fn() },
  } as any;
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
  it('upserts a favorite row from the domain entity', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaFavoriteRepository(prisma);
    const favorite = Favorite.create({ id: 'f1', userId: 'u1', stationId: 's1' });

    await repo.save(favorite);

    expect(prisma.favorite.upsert).toHaveBeenCalledWith({
      where: { id: 'f1' },
      create: { id: 'f1', userId: 'u1', stationId: 's1', thirdPartyPlaceId: null, notifyOnAvailable: false },
      update: { notifyOnAvailable: false },
    });
  });

  it('returns null from findById when the record does not exist', async () => {
    const prisma = createPrismaMock();
    prisma.favorite.findUnique.mockResolvedValue(null);
    const repo = new PrismaFavoriteRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('maps a record into the domain entity via findById', async () => {
    const prisma = createPrismaMock();
    prisma.favorite.findUnique.mockResolvedValue(record('f1'));
    const repo = new PrismaFavoriteRepository(prisma);

    const favorite = await repo.findById('f1');

    expect(favorite?.id).toBe('f1');
    expect(favorite?.stationId).toBe('s1');
  });

  it('deletes a favorite by id', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaFavoriteRepository(prisma);

    await repo.delete('f1');

    expect(prisma.favorite.delete).toHaveBeenCalledWith({ where: { id: 'f1' } });
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
