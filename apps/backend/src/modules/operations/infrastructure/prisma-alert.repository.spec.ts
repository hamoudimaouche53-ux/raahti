import { Alert } from '../domain/entities/alert.entity';
import { PrismaAlertRepository } from './prisma-alert.repository';

function createPrismaMock() {
  return {
    alert: { upsert: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), groupBy: jest.fn() },
  } as any;
}

function record(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'a1',
    stationId: 's1',
    type: 'fire',
    severity: 'critical',
    status: 'open',
    acknowledgedBy: null,
    raisedAt: new Date('2026-01-01T00:00:00Z'),
    resolvedAt: null,
    ...overrides,
  };
}

describe('PrismaAlertRepository', () => {
  it('upserts a raised alert', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaAlertRepository(prisma);
    const alert = Alert.raise({ id: 'a1', stationId: 's1', type: 'fire', severity: 'critical' });

    await repo.save(alert);

    expect(prisma.alert.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'a1' },
        create: expect.objectContaining({ id: 'a1', stationId: 's1', status: 'open' }),
        update: expect.objectContaining({ status: 'open', acknowledgedBy: null, resolvedAt: null }),
      }),
    );
  });

  it('maps a found record to a domain Alert', async () => {
    const prisma = createPrismaMock();
    prisma.alert.findUnique.mockResolvedValue(record());
    const repo = new PrismaAlertRepository(prisma);

    const alert = await repo.findById('a1');

    expect(alert?.id).toBe('a1');
    expect(alert?.status).toBe('open');
  });

  it('returns null when not found', async () => {
    const prisma = createPrismaMock();
    prisma.alert.findUnique.mockResolvedValue(null);
    const repo = new PrismaAlertRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('sorts by severity DESC, then raisedAt ASC (FR-OPS-02)', async () => {
    const prisma = createPrismaMock();
    prisma.alert.findMany.mockResolvedValue([
      record({ id: 'low-old', severity: 'low', raisedAt: new Date('2026-01-01T00:00:00Z') }),
      record({ id: 'critical-new', severity: 'critical', raisedAt: new Date('2026-01-02T00:00:00Z') }),
      record({ id: 'critical-old', severity: 'critical', raisedAt: new Date('2026-01-01T00:00:00Z') }),
      record({ id: 'high', severity: 'high', raisedAt: new Date('2026-01-01T00:00:00Z') }),
    ]);
    const repo = new PrismaAlertRepository(prisma);

    const alerts = await repo.findAll();

    expect(alerts.map((a) => a.id)).toEqual(['critical-old', 'critical-new', 'high', 'low-old']);
  });

  it('filters by status when provided', async () => {
    const prisma = createPrismaMock();
    prisma.alert.findMany.mockResolvedValue([]);
    const repo = new PrismaAlertRepository(prisma);

    await repo.findAll('open');

    expect(prisma.alert.findMany).toHaveBeenCalledWith({ where: { status: 'open' } });
  });

  it('groups active alert counts by station, excluding resolved', async () => {
    const prisma = createPrismaMock();
    prisma.alert.groupBy.mockResolvedValue([
      { stationId: 's1', _count: { _all: 3 } },
      { stationId: 's2', _count: { _all: 1 } },
    ]);
    const repo = new PrismaAlertRepository(prisma);

    const counts = await repo.countActiveGroupedByStation();

    expect(prisma.alert.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: { not: 'resolved' } } }),
    );
    expect(counts.get('s1')).toBe(3);
    expect(counts.get('s2')).toBe(1);
  });
});
