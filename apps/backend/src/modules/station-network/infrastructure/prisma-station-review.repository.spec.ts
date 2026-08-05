import { StationReview } from '../domain/entities/review.entity';
import { PrismaStationReviewRepository } from './prisma-station-review.repository';

function createPrismaMock() {
  return { review: { create: jest.fn(), aggregate: jest.fn() } } as any;
}

describe('PrismaStationReviewRepository', () => {
  it('creates a review row scoped to a station (thirdPartyPlaceId null)', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaStationReviewRepository(prisma);
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 4, comment: 'Good.' });

    await repo.save(review);

    expect(prisma.review.create).toHaveBeenCalledWith({
      data: { id: 'r1', userId: 'u1', stationId: 's1', thirdPartyPlaceId: null, rating: 4, comment: 'Good.' },
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
});
