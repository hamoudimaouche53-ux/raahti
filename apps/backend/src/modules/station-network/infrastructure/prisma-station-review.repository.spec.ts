import { StationReview } from '../domain/entities/review.entity';
import { encodeReviewCursor } from './review-cursor';
import { PrismaStationReviewRepository } from './prisma-station-review.repository';

function createPrismaMock() {
  return {
    review: { upsert: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), delete: jest.fn(), aggregate: jest.fn() },
  } as any;
}

describe('PrismaStationReviewRepository', () => {
  it('upserts a review row scoped to a station (thirdPartyPlaceId null)', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaStationReviewRepository(prisma);
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 4, comment: 'Good.' });

    await repo.save(review);

    expect(prisma.review.upsert).toHaveBeenCalledWith({
      where: { id: 'r1' },
      create: { id: 'r1', userId: 'u1', stationId: 's1', thirdPartyPlaceId: null, rating: 4, comment: 'Good.' },
      update: { rating: 4, comment: 'Good.' },
    });
  });

  it('maps a Prisma aggregate result into the domain shape', async () => {
    const prisma = createPrismaMock();
    prisma.review.aggregate.mockResolvedValue({ _avg: { rating: 3.5 }, _count: { _all: 2 } });
    const repo = new PrismaStationReviewRepository(prisma);

    const result = await repo.aggregateByStationId('s1');

    expect(result).toEqual({ averageRating: 3.5, reviewCount: 2 });
    expect(prisma.review.aggregate).toHaveBeenCalledWith({
      where: { stationId: 's1' },
      _avg: { rating: true },
      _count: { _all: true },
    });
  });

  it('returns a null average when there are no reviews yet', async () => {
    const prisma = createPrismaMock();
    prisma.review.aggregate.mockResolvedValue({ _avg: { rating: null }, _count: { _all: 0 } });
    const repo = new PrismaStationReviewRepository(prisma);

    const result = await repo.aggregateByStationId('s1');

    expect(result).toEqual({ averageRating: null, reviewCount: 0 });
  });

  describe('findById', () => {
    it('returns the domain entity for a station-scoped review row', async () => {
      const prisma = createPrismaMock();
      const createdAt = new Date('2026-08-01T00:00:00.000Z');
      prisma.review.findUnique.mockResolvedValue({
        id: 'r1',
        userId: 'u1',
        stationId: 's1',
        thirdPartyPlaceId: null,
        rating: 4,
        comment: 'Good.',
        createdAt,
      });
      const repo = new PrismaStationReviewRepository(prisma);

      const review = await repo.findById('r1');

      expect(review?.id).toBe('r1');
      expect(review?.stationId).toBe('s1');
      expect(prisma.review.findUnique).toHaveBeenCalledWith({ where: { id: 'r1' } });
    });

    it('returns null when the row does not exist', async () => {
      const prisma = createPrismaMock();
      prisma.review.findUnique.mockResolvedValue(null);
      const repo = new PrismaStationReviewRepository(prisma);

      expect(await repo.findById('missing')).toBeNull();
    });

    it('returns null (not the row) when the id belongs to a third-party-place review — defense-in-depth', async () => {
      const prisma = createPrismaMock();
      prisma.review.findUnique.mockResolvedValue({
        id: 'r1',
        userId: 'u1',
        stationId: null,
        thirdPartyPlaceId: 'p1',
        rating: 4,
        comment: null,
        createdAt: new Date(),
      });
      const repo = new PrismaStationReviewRepository(prisma);

      expect(await repo.findById('r1')).toBeNull();
    });
  });

  describe('delete', () => {
    it('deletes the review row by id', async () => {
      const prisma = createPrismaMock();
      const repo = new PrismaStationReviewRepository(prisma);

      await repo.delete('r1');

      expect(prisma.review.delete).toHaveBeenCalledWith({ where: { id: 'r1' } });
    });
  });

  describe('listByUserId', () => {
    it('scopes to the given user and station-only rows, newest first', async () => {
      const prisma = createPrismaMock();
      prisma.review.findMany.mockResolvedValue([]);
      const repo = new PrismaStationReviewRepository(prisma);

      await repo.listByUserId('u1', null, 20);

      expect(prisma.review.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1', stationId: { not: null } },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 21,
      });
    });

    it('returns nextCursor null when fewer rows than the limit come back', async () => {
      const prisma = createPrismaMock();
      const createdAt = new Date('2026-08-01T00:00:00.000Z');
      prisma.review.findMany.mockResolvedValue([
        { id: 'r1', userId: 'u1', stationId: 's1', thirdPartyPlaceId: null, rating: 4, comment: null, createdAt },
      ]);
      const repo = new PrismaStationReviewRepository(prisma);

      const page = await repo.listByUserId('u1', null, 20);

      expect(page.data).toHaveLength(1);
      expect(page.nextCursor).toBeNull();
    });

    it('returns an encoded nextCursor when more rows exist than the limit', async () => {
      const prisma = createPrismaMock();
      const createdAt = new Date('2026-08-01T00:00:00.000Z');
      const rows = Array.from({ length: 3 }, (_, i) => ({
        id: `r${i}`,
        userId: 'u1',
        stationId: 's1',
        thirdPartyPlaceId: null,
        rating: 4,
        comment: null,
        createdAt,
      }));
      prisma.review.findMany.mockResolvedValue(rows);
      const repo = new PrismaStationReviewRepository(prisma);

      const page = await repo.listByUserId('u1', null, 2);

      expect(page.data).toHaveLength(2);
      expect(page.nextCursor).toBe(encodeReviewCursor({ createdAt: createdAt.toISOString(), id: 'r1' }));
    });

    it('decodes a supplied cursor into a createdAt/id keyset filter', async () => {
      const prisma = createPrismaMock();
      prisma.review.findMany.mockResolvedValue([]);
      const repo = new PrismaStationReviewRepository(prisma);
      const cursor = encodeReviewCursor({ createdAt: '2026-08-01T00:00:00.000Z', id: 'r5' });

      await repo.listByUserId('u1', cursor, 20);

      expect(prisma.review.findMany).toHaveBeenCalledWith({
        where: {
          userId: 'u1',
          stationId: { not: null },
          OR: [
            { createdAt: { lt: new Date('2026-08-01T00:00:00.000Z') } },
            { createdAt: new Date('2026-08-01T00:00:00.000Z'), id: { lt: 'r5' } },
          ],
        },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 21,
      });
    });
  });
});
