import { PrismaTelemetryReadingRepository } from './prisma-telemetry-reading.repository';

function createPrismaMock() {
  return { telemetryReading: { findFirst: jest.fn(), findMany: jest.fn() } } as any;
}

describe('PrismaTelemetryReadingRepository', () => {
  it('returns the latest station-level value for a metric', async () => {
    const prisma = createPrismaMock();
    prisma.telemetryReading.findFirst.mockResolvedValue({
      id: 't1',
      stationId: 's1',
      cabinId: null,
      metric: 'battery_level',
      value: { toString: () => '72.50' } as unknown as number,
      recordedAt: new Date('2026-08-01T00:00:00Z'),
    });
    const repo = new PrismaTelemetryReadingRepository(prisma);

    const value = await repo.findLatestValue('s1', 'battery_level');

    expect(value).toBe(72.5);
    expect(prisma.telemetryReading.findFirst).toHaveBeenCalledWith({
      where: { stationId: 's1', metric: 'battery_level', cabinId: null },
      orderBy: { recordedAt: 'desc' },
    });
  });

  it('returns null when no reading exists', async () => {
    const prisma = createPrismaMock();
    prisma.telemetryReading.findFirst.mockResolvedValue(null);
    const repo = new PrismaTelemetryReadingRepository(prisma);

    expect(await repo.findLatestValue('s1', 'water_level')).toBeNull();
  });

  it('returns a time-bounded series ordered ascending', async () => {
    const prisma = createPrismaMock();
    const from = new Date('2026-08-01T00:00:00Z');
    const to = new Date('2026-08-02T00:00:00Z');
    prisma.telemetryReading.findMany.mockResolvedValue([
      { recordedAt: new Date('2026-08-01T06:00:00Z'), value: 3 },
      { recordedAt: new Date('2026-08-01T18:00:00Z'), value: 5 },
    ]);
    const repo = new PrismaTelemetryReadingRepository(prisma);

    const series = await repo.findSeries('s1', 'occupancy', from, to);

    expect(series).toEqual([
      { recordedAt: new Date('2026-08-01T06:00:00Z'), value: 3 },
      { recordedAt: new Date('2026-08-01T18:00:00Z'), value: 5 },
    ]);
    expect(prisma.telemetryReading.findMany).toHaveBeenCalledWith({
      where: { stationId: 's1', metric: 'occupancy', recordedAt: { gte: from, lte: to } },
      orderBy: { recordedAt: 'asc' },
    });
  });
});
