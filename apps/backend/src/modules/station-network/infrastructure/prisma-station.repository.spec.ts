import { PrismaStationRepository } from './prisma-station.repository';

function createPrismaMock() {
  return {
    $queryRaw: jest.fn(),
    cabin: { findMany: jest.fn().mockResolvedValue([]) },
    slatokiTent: { findUnique: jest.fn().mockResolvedValue(null), findMany: jest.fn().mockResolvedValue([]) },
  } as any;
}

const STATION_ROW = {
  id: 's1',
  code: 'ST-001',
  configuration: 'fixe',
  status: 'active',
  cabin_capacity: 2,
  tank_capacity_liters: 500,
  installed_at: new Date('2026-01-01'),
  created_at: new Date('2026-01-01'),
  updated_at: new Date('2026-01-01'),
  lat: 36.75,
  lng: 3.05,
};

describe('PrismaStationRepository', () => {
  it('returns null when no station row is found', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([]);
    const repo = new PrismaStationRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('maps a station row + cabins + tent into the aggregate', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([STATION_ROW]);
    prisma.cabin.findMany.mockResolvedValue([
      {
        id: 'c1',
        stationId: 's1',
        code: 'C-01',
        type: 'H',
        occupancyStatus: 'free',
        isPaid: false,
        priceAmount: null,
        priceCurrency: null,
      },
      {
        id: 'c2',
        stationId: 's1',
        code: 'C-02',
        type: 'F',
        occupancyStatus: 'occupied',
        isPaid: true,
        priceAmount: { toString: () => '50.00' },
        priceCurrency: 'DZD',
      },
    ]);
    prisma.slatokiTent.findUnique.mockResolvedValue({
      id: 't1',
      stationId: 's1',
      deploymentStatus: 'deployed',
      matCapacity: 4,
      hasLighting: true,
      hasPrivacyCurtain: true,
    });

    const repo = new PrismaStationRepository(prisma);
    const station = await repo.findById('s1');

    expect(station).not.toBeNull();
    expect(station!.code).toBe('ST-001');
    expect(station!.position.lat).toBe(36.75);
    expect(station!.position.lng).toBe(3.05);
    expect(station!.cabins).toHaveLength(2);
    expect(station!.cabins[1].price?.toDecimalString()).toBe('50.00');
    expect(station!.hasSlatokiTent).toBe(true);
    expect(station!.slatokiTent?.deploymentStatus).toBe('deployed');
  });

  it('maps a station with no cabins and no tent', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([STATION_ROW]);

    const repo = new PrismaStationRepository(prisma);
    const station = await repo.findById('s1');

    expect(station!.cabins).toHaveLength(0);
    expect(station!.hasSlatokiTent).toBe(false);
  });

  describe('findAll', () => {
    it('returns an empty array when there are no stations', async () => {
      const prisma = createPrismaMock();
      prisma.$queryRaw.mockResolvedValue([]);
      const repo = new PrismaStationRepository(prisma);

      expect(await repo.findAll()).toEqual([]);
    });

    it('batch-loads cabins/tents for every station (no N+1)', async () => {
      const prisma = createPrismaMock();
      const otherRow = { ...STATION_ROW, id: 's2', code: 'ST-002' };
      prisma.$queryRaw.mockResolvedValue([STATION_ROW, otherRow]);
      prisma.cabin.findMany.mockResolvedValue([
        { id: 'c1', stationId: 's1', code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, priceAmount: null, priceCurrency: null },
      ]);
      prisma.slatokiTent.findMany.mockResolvedValue([
        { id: 't2', stationId: 's2', deploymentStatus: 'folded', matCapacity: 2, hasLighting: false, hasPrivacyCurtain: false },
      ]);

      const repo = new PrismaStationRepository(prisma);
      const stations = await repo.findAll();

      expect(stations).toHaveLength(2);
      expect(prisma.cabin.findMany).toHaveBeenCalledWith({ where: { stationId: { in: ['s1', 's2'] } } });
      expect(prisma.slatokiTent.findMany).toHaveBeenCalledWith({ where: { stationId: { in: ['s1', 's2'] } } });

      const stationOne = stations.find((s) => s.id === 's1')!;
      const stationTwo = stations.find((s) => s.id === 's2')!;
      expect(stationOne.cabins).toHaveLength(1);
      expect(stationOne.hasSlatokiTent).toBe(false);
      expect(stationTwo.cabins).toHaveLength(0);
      expect(stationTwo.hasSlatokiTent).toBe(true);
    });
  });
});
