import { Notification } from '../domain/entities/notification.entity';
import { NotificationRepository } from '../domain/ports/notification.repository';
import { NotificationNotFoundException } from './notification-not-found.exception';
import { NotificationService } from './notification.service';

function createRepoMock(): jest.Mocked<NotificationRepository> {
  return { save: jest.fn(), findById: jest.fn(), findByUserId: jest.fn() };
}

describe('NotificationService', () => {
  it('queues a new notification and persists it', async () => {
    const repo = createRepoMock();
    const service = new NotificationService(repo);

    const notification = await service.queue({ userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });

    expect(notification.status).toBe('queued');
    expect(repo.save).toHaveBeenCalledWith(notification);
  });

  it('lists notifications for a user', async () => {
    const repo = createRepoMock();
    repo.findByUserId.mockResolvedValue([]);
    const service = new NotificationService(repo);

    await service.listForUser('u1');

    expect(repo.findByUserId).toHaveBeenCalledWith('u1');
  });

  describe('markAsRead', () => {
    it('marks the owner\'s notification as read and persists it', async () => {
      const repo = createRepoMock();
      const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'availability' });
      repo.findById.mockResolvedValue(notification);
      const service = new NotificationService(repo);

      const result = await service.markAsRead('u1', 'n1');

      expect(result.isRead).toBe(true);
      expect(repo.save).toHaveBeenCalledWith(notification);
    });

    it('throws NotificationNotFoundException when the notification does not exist', async () => {
      const repo = createRepoMock();
      repo.findById.mockResolvedValue(null);
      const service = new NotificationService(repo);

      await expect(service.markAsRead('u1', 'missing')).rejects.toThrow(NotificationNotFoundException);
    });

    it('throws NotificationNotFoundException when the notification belongs to a different user (no existence leak)', async () => {
      const repo = createRepoMock();
      const notification = Notification.queue({ id: 'n1', userId: 'someone-else', channel: 'in_app', type: 'availability' });
      repo.findById.mockResolvedValue(notification);
      const service = new NotificationService(repo);

      await expect(service.markAsRead('u1', 'n1')).rejects.toThrow(NotificationNotFoundException);
      expect(repo.save).not.toHaveBeenCalled();
    });

    it('is idempotent at the service level too (repeat calls do not throw or change readAt)', async () => {
      const repo = createRepoMock();
      const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'availability' });
      repo.findById.mockResolvedValue(notification);
      const service = new NotificationService(repo);

      await service.markAsRead('u1', 'n1');
      const firstReadAt = notification.readAt;
      await service.markAsRead('u1', 'n1');

      expect(notification.readAt).toEqual(firstReadAt);
    });
  });
});
