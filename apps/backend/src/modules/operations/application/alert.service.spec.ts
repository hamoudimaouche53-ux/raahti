import { Alert } from '../domain/entities/alert.entity';
import { AlertRepository } from '../domain/ports/alert.repository';
import { AlertNotFoundException } from './alert-not-found.exception';
import { AlertService } from './alert.service';

function createRepoMock(): jest.Mocked<AlertRepository> {
  return {
    save: jest.fn(),
    findById: jest.fn(),
    findAll: jest.fn(),
    countActiveGroupedByStation: jest.fn(),
  };
}

describe('AlertService', () => {
  describe('list', () => {
    it('delegates to the repository, forwarding the status filter', async () => {
      const repo = createRepoMock();
      repo.findAll.mockResolvedValue([]);
      const service = new AlertService(repo);

      await service.list('open');

      expect(repo.findAll).toHaveBeenCalledWith('open');
    });
  });

  describe('updateStatus', () => {
    it('acknowledges an alert and persists it', async () => {
      const repo = createRepoMock();
      const alert = Alert.raise({ id: 'a1', stationId: 's1', type: 'fire', severity: 'critical' });
      repo.findById.mockResolvedValue(alert);
      const service = new AlertService(repo);

      const result = await service.updateStatus('a1', 'acknowledged', 'operator-1');

      expect(result.status).toBe('acknowledged');
      expect(result.acknowledgedBy).toBe('operator-1');
      expect(repo.save).toHaveBeenCalledWith(alert);
    });

    it('throws AlertNotFoundException when the alert does not exist', async () => {
      const repo = createRepoMock();
      repo.findById.mockResolvedValue(null);
      const service = new AlertService(repo);

      await expect(service.updateStatus('missing', 'acknowledged', 'operator-1')).rejects.toThrow(
        AlertNotFoundException,
      );
    });
  });
});
