import { GeoPosition } from '../../../shared-kernel';
import { PrismaThirdPartyPlaceRepository } from './prisma-third-party-place.repository';
import { encodeSearchCursor } from './search-cursor';

function createPrismaMock() {
  return {
    $queryRaw: jest.fn(),
    thirdPartyPlaceTag: { findMany: jest.fn().mockResolvedValue([]) },
  } as any;
}

function row(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'p1',
    name_fr: 'Mosquée Al-Fath',
    name_ar: 'مسجد الفتح',
    place_type: 'mosque',
    is_free: true,
    declared_status: 'open',
    status_source: 'community',
    lat: 36.75,
    lng: 3.05,
    distance_meters: 200,
    average_rating: null,
    review_count: 0,
    ...overrides,
  };
}

describe('PrismaThirdPartyPlaceRepository.searchNearby', () => {
  it('maps rows into search results with tags fetched in a batch', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ id: 'p1' }), row({ id: 'p2' })]);
    prisma.thirdPartyPlaceTag.findMany.mockResolvedValue([
      { thirdPartyPlaceId: 'p1', tag: { code: 'women_confirmed' } },
      { thirdPartyPlaceId: 'p2', tag: { code: 'wudu' } },
    ]);
    const repo = new PrismaThirdPartyPlaceRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 30,
    });

    expect(page.data).toHaveLength(2);
    expect(page.data[0].tags).toEqual(['women_confirmed']);
    expect(page.data[1].tags).toEqual(['wudu']);
    expect(prisma.thirdPartyPlaceTag.findMany).toHaveBeenCalledTimes(1); // batched, not N+1
  });

  it('returns an empty tags array for a place with no tags, without querying', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([]);
    const repo = new PrismaThirdPartyPlaceRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 30,
    });

    expect(page.data).toEqual([]);
    expect(prisma.thirdPartyPlaceTag.findMany).not.toHaveBeenCalled();
  });

  it('maps average_rating/review_count through from the query', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ average_rating: 3.2, review_count: 6 })]);
    const repo = new PrismaThirdPartyPlaceRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 30,
    });

    expect(page.data[0]).toEqual(expect.objectContaining({ averageRating: 3.2, reviewCount: 6 }));
  });

  it('returns a next cursor when more rows exist beyond the limit', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row({ id: 'p1' }), row({ id: 'p2' }), row({ id: 'p3' })]);
    const repo = new PrismaThirdPartyPlaceRepository(prisma);

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: [],
      limit: 2,
    });

    expect(page.data).toHaveLength(2);
    expect(page.nextCursor).not.toBeNull();
  });

  it('accepts a decoded cursor and type/query criteria without throwing', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([]);
    const repo = new PrismaThirdPartyPlaceRepository(prisma);
    const cursor = encodeSearchCursor({ distanceMeters: 50, id: 'p0' });

    const page = await repo.searchNearby({
      position: GeoPosition.of(36.75, 3.05),
      radiusMeters: 2000,
      types: ['free_wc', 'slatoki'],
      query: 'Mosquée',
      cursor,
      limit: 30,
    });

    expect(page.data).toEqual([]);
  });
});
