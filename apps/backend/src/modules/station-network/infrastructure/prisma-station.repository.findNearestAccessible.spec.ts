import { PrismaStationRepository } from './prisma-station.repository';
import { GeoPosition } from '../../../shared-kernel';

function createPrismaMock() {
  return {
    $queryRaw: jest.fn(),
    cabin: { findMany: jest.fn().mockResolvedValue([]) },
  } as any;
}

function row(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 's1',
    code: 'ST-001',
    configuration: 'fixe',
    status: 'active',
    lat: 36.75,
    lng: 3.05,
    distance_meters: 500,
    has_slatoki_tent: false,
    cabin_count: 2,
    all_free: false,
    all_paid: true,
    average_rating: null,
    review_count: 0,
    ...overrides,
  };
}

function cabin(overrides: Partial<{ id: string; occupancyStatus: string }> = {}) {
  return { id: 'c1', occupancyStatus: 'free', ...overrides };
}

describe('PrismaStationRepository.findNearestAccessible', () => {
  it('returns null when no active station is within the given radius', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([]);
    const repo = new PrismaStationRepository(prisma);

    const result = await repo.findNearestAccessible(GeoPosition.of(36.75, 3.05), 20_000);

    expect(result).toBeNull();
  });

  it('maps the winning row into the search-result projection', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row()]);
    prisma.cabin.findMany.mockResolvedValue([cabin({ id: 'c1', occupancyStatus: 'free' })]);
    const repo = new PrismaStationRepository(prisma);

    const result = await repo.findNearestAccessible(GeoPosition.of(36.75, 3.05), 20_000);

    expect(result?.station).toEqual(
      expect.objectContaining({ id: 's1', code: 'ST-001', cabinPricingMix: 'all_paid', distanceMeters: 500 }),
    );
  });

  it('prefers a free cabin as the nearest accessible cabin', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row()]);
    prisma.cabin.findMany.mockResolvedValue([
      cabin({ id: 'c1', occupancyStatus: 'occupied' }),
      cabin({ id: 'c2', occupancyStatus: 'free' }),
    ]);
    const repo = new PrismaStationRepository(prisma);

    const result = await repo.findNearestAccessible(GeoPosition.of(36.75, 3.05), 20_000);

    expect(result?.nearestCabinId).toBe('c2');
  });

  it('falls back to any non-out_of_service cabin when none are free', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row()]);
    prisma.cabin.findMany.mockResolvedValue([
      cabin({ id: 'c1', occupancyStatus: 'out_of_service' }),
      cabin({ id: 'c2', occupancyStatus: 'occupied' }),
    ]);
    const repo = new PrismaStationRepository(prisma);

    const result = await repo.findNearestAccessible(GeoPosition.of(36.75, 3.05), 20_000);

    expect(result?.nearestCabinId).toBe('c2');
  });

  it('returns null nearestCabinId when every cabin is out_of_service', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row()]);
    prisma.cabin.findMany.mockResolvedValue([cabin({ id: 'c1', occupancyStatus: 'out_of_service' })]);
    const repo = new PrismaStationRepository(prisma);

    const result = await repo.findNearestAccessible(GeoPosition.of(36.75, 3.05), 20_000);

    expect(result?.nearestCabinId).toBeNull();
  });

  it('returns null nearestCabinId when the station has no cabins at all', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([row()]);
    prisma.cabin.findMany.mockResolvedValue([]);
    const repo = new PrismaStationRepository(prisma);

    const result = await repo.findNearestAccessible(GeoPosition.of(36.75, 3.05), 20_000);

    expect(result?.nearestCabinId).toBeNull();
  });
});
