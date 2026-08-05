import { PrismaStationRepository } from './prisma-station.repository';
import { encodeSearchCursor } from './search-cursor';
import { GeoPosition } from '../../../shared-kernel';

function createPrismaMock() {
  return { $queryRaw: jest.fn() } as any;
}

function row(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 's1',
    code: 'ST-001',
    configuration: 'fixe',
    status: 'active',
    lat: 36.75,
    lng: 3.05,
    distance_meters: 100,
    has_slatoki_tent: false,
    cabin_count: 2,
    all_free: true,
    all_paid: false,
    average_rating: null,
    review_count: 0,
    ...overrides,
  };
}

describe('PrismaStationRepository.searchNearby', () => {
  it('maps rows into search results and reports no next cursor when the page is not full', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ id: 's1' }), row({ id: 's2' })]);
    const repo = new PrismaStationRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 30,
    });

    expect(page.data).toHaveLength(2);
    expect(page.data[0]).toEqual(
      expect.objectContaining({ id: 's1', cabinPricingMix: 'all_free', hasSlatokiTent: false }),
    );
    expect(page.nextCursor).toBeNull();
  });

  it('returns a next cursor and trims to the limit when more rows exist', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ id: 's1', distance_meters: 10 }), row({ id: 's2', distance_meters: 20 }), row({ id: 's3', distance_meters: 30 })]);
    const repo = new PrismaStationRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 2,
    });

    expect(page.data).toHaveLength(2);
    expect(page.nextCursor).not.toBeNull();
  });

  it('reports no_cabins when cabin_count is zero, not mixed', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ cabin_count: 0, all_free: false, all_paid: false })]);
    const repo = new PrismaStationRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 30,
    });

    expect(page.data[0].cabinPricingMix).toBe('no_cabins');
  });

  it('maps average_rating/review_count through from the query', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ average_rating: 4.5, review_count: 8 })]);
    const repo = new PrismaStationRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 30,
    });

    expect(page.data[0]).toEqual(expect.objectContaining({ averageRating: 4.5, reviewCount: 8 }));
  });

  it('passes a decoded cursor and type/query criteria into the query without throwing', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([]);
    const repo = new PrismaStationRepository(prisma);
    const cursor = encodeSearchCursor({ distanceMeters: 50, id: 's0' });

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: ['free_wc', 'slatoki'],
      query: 'ST-0',
      cursor,
      limit: 30,
    });

    expect(page.data).toEqual([]);
    expect(prisma.$queryRaw).toHaveBeenCalled();
  });
});
