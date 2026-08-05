import { MaintenanceIntervention } from '../domain/entities/maintenance-intervention.entity';
import { PrismaMaintenanceInterventionRepository } from './prisma-maintenance-intervention.repository';

function createPrismaMock() {
  return { maintenanceIntervention: { upsert: jest.fn(), findMany: jest.fn() } } as any;
}

function record(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'mi1',
    stationId: 's1',
    alertId: null,
    interventionType: 'refill',
    status: 'scheduled',
    assignedTo: 'operator-1',
    scheduledAt: new Date('2026-08-10T09:00:00Z'),
    completedAt: null,
    ...overrides,
  };
}

describe('PrismaMaintenanceInterventionRepository', () => {
  it('upserts a scheduled intervention', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaMaintenanceInterventionRepository(prisma);
    const intervention = MaintenanceIntervention.schedule({
      id: 'mi1',
      stationId: 's1',
      interventionType: 'refill',
      assignedTo: 'operator-1',
      scheduledAt: new Date('2026-08-10T09:00:00Z'),
    });

    await repo.save(intervention);

    expect(prisma.maintenanceIntervention.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'mi1' },
        create: expect.objectContaining({ id: 'mi1', stationId: 's1', status: 'scheduled', alertId: null }),
      }),
    );
  });

  it('lists interventions ordered by scheduledAt', async () => {
    const prisma = createPrismaMock();
    prisma.maintenanceIntervention.findMany.mockResolvedValue([record({ id: 'mi1' }), record({ id: 'mi2' })]);
    const repo = new PrismaMaintenanceInterventionRepository(prisma);

    const interventions = await repo.findAll();

    expect(interventions).toHaveLength(2);
    expect(prisma.maintenanceIntervention.findMany).toHaveBeenCalledWith({ orderBy: { scheduledAt: 'asc' } });
  });
});
