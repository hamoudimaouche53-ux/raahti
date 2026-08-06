import { ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import { encodeReviewCursor } from './review-cursor';
import { PrismaThirdPartyPlaceReviewRepository } from './prisma-third-party-place-review.repository';

function createPrismaMock() {
  return {
    review: { upsert: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), delete: jest.fn(), aggregate: jest.fn() },
  } as any;
}

describe('PrismaThirdPartyPlaceReviewRepository', () => {
  it('upserts a review row scoped to a third-party place (stationId null)', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 5 });

    await repo.save(review);

    expect(prisma.review.upsert).toHaveBeenCalledWith({
      where: { id: 'r1' },
      create: { id: 'r1', userId: 'u1', stationId: null, thirdPartyPlaceId: 'p1', rating: 5, comment: null },
      update: { rating: 5, comment: null },
    });
  });

  it('maps a Prisma aggregate result into the domain shape', async () => {
    const prisma = createPrismaMock();
    prisma.review.aggregate.mockResolvedValue({ _avg: { rating: 4.0 }, _count: { _all: 3 } });
    const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

    const result = await repo.aggregateByThirdPartyPlaceId('p1');

    expect(result).toEqual({ averageRating: 4.0, reviewCount: 3 });
  });

  describe('findById', () => {
    it('returns the domain entity for a third-party-place-scoped review row', async () => {
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
      const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

      const review = await repo.findById('r1');

      expect(review?.thirdPartyPlaceId).toBe('p1');
    });

    it('returns null (not the row) when the id belongs to a station review — defense-in-depth', async () => {
      const prisma = createPrismaMock();
      prisma.review.findUnique.mockResolvedValue({
        id: 'r1',
        userId: 'u1',
        stationId: 's1',
        thirdPartyPlaceId: null,
        rating: 4,
        comment: null,
        createdAt: new Date(),
      });
      const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

      expect(await repo.findById('r1')).toBeNull();
    });
  });

  describe('delete', () => {
    it('deletes the review row by id', async () => {
      const prisma = createPrismaMock();
      const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

      await repo.delete('r1');

      expect(prisma.review.delete).toHaveBeenCalledWith({ where: { id: 'r1' } });
    });
  });

  describe('listByUserId', () => {
    it('scopes to the given user and third-party-place-only rows, newest first', async () => {
      const prisma = createPrismaMock();
      prisma.review.findMany.mockResolvedValue([]);
      const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

      await repo.listByUserId('u1', null, 20);

      expect(prisma.review.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1', thirdPartyPlaceId: { not: null } },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 21,
      });
    });

    it('returns an encoded nextCursor when more rows exist than the limit', async () => {
      const prisma = createPrismaMock();
      const createdAt = new Date('2026-08-01T00:00:00.000Z');
      const rows = Array.from({ length: 2 }, (_, i) => ({
        id: `r${i}`,
        userId: 'u1',
        stationId: null,
        thirdPartyPlaceId: 'p1',
        rating: 4,
        comment: null,
        createdAt,
      }));
      prisma.review.findMany.mockResolvedValue(rows);
      const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

      const page = await repo.listByUserId('u1', null, 1);

      expect(page.data).toHaveLength(1);
      expect(page.nextCursor).toBe(encodeReviewCursor({ createdAt: createdAt.toISOString(), id: 'r0' }));
    });
  });
});
