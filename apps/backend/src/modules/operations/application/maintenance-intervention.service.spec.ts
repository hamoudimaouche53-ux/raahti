import { MaintenanceInterventionRepository } from '../domain/ports/maintenance-intervention.repository';
import { MaintenanceInterventionService } from './maintenance-intervention.service';

function createRepoMock(): jest.Mocked<MaintenanceInterventionRepository> {
  return { save: jest.fn(), findAll: jest.fn() };
}

describe('MaintenanceInterventionService', () => {
  describe('list', () => {
    it('delegates to the repository', async () => {
      const repo = createRepoMock();
      repo.findAll.mockResolvedValue([]);
      const service = new MaintenanceInterventionService(repo);

      await service.list();

      expect(repo.findAll).toHaveBeenCalled();
    });
  });

  describe('schedule', () => {
    it('assigns to the requested operator when provided', async () => {
      const repo = createRepoMock();
      const service = new MaintenanceInterventionService(repo);

      const intervention = await service.schedule(
        { stationId: 's1', interventionType: 'refill', scheduledAt: new Date('2026-08-10'), assignedTo: 'operator-2' },
        'operator-1',
      );

      expect(intervention.assignedTo).toBe('operator-2');
      expect(intervention.stationId).toBe('s1');
      expect(intervention.alertId).toBeNull();
      expect(repo.save).toHaveBeenCalledWith(intervention);
    });

    it('defaults assignedTo to the scheduling operator when omitted (assignedTo is optional in the contract, NOT NULL in the ERD)', async () => {
      const repo = createRepoMock();
      const service = new MaintenanceInterventionService(repo);

      const intervention = await service.schedule(
        { stationId: 's1', interventionType: 'repair', scheduledAt: new Date('2026-08-10') },
        'operator-1',
      );

      expect(intervention.assignedTo).toBe('operator-1');
    });

    it('carries an alertId when the intervention is triggered by an alert', async () => {
      const repo = createRepoMock();
      const service = new MaintenanceInterventionService(repo);

      const intervention = await service.schedule(
        { stationId: 's1', alertId: 'a1', interventionType: 'repair', scheduledAt: new Date('2026-08-10') },
        'operator-1',
      );

      expect(intervention.alertId).toBe('a1');
    });
  });
});
