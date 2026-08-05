import { ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import { PrismaThirdPartyPlaceReviewRepository } from './prisma-third-party-place-review.repository';

function createPrismaMock() {
  return { review: { create: jest.fn(), aggregate: jest.fn() } } as any;
}

describe('PrismaThirdPartyPlaceReviewRepository', () => {
  it('creates a review row scoped to a third-party place (stationId null)', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 5 });

    await repo.save(review);

    expect(prisma.review.create).toHaveBeenCalledWith({
      data: { id: 'r1', userId: 'u1', stationId: null, thirdPartyPlaceId: 'p1', rating: 5, comment: null },
    });
  });

  it('maps a Prisma aggregate result into the domain shape', async () => {
    const prisma = createPrismaMock();
    prisma.review.aggregate.mockResolvedValue({ _avg: { rating: 4.0 }, _count: { _all: 3 } });
    const repo = new PrismaThirdPartyPlaceReviewRepository(prisma);

    const result = await repo.aggregateByThirdPartyPlaceId('p1');

    expect(result).toEqual({ averageRating: 4.0, reviewCount: 3 });
  });
});
