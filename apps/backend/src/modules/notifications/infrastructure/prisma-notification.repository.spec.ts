import { Notification } from '../domain/entities/notification.entity';
import { PrismaNotificationRepository } from './prisma-notification.repository';

function createPrismaMock() {
  return { notification: { upsert: jest.fn(), findUnique: jest.fn(), findMany: jest.fn() } } as any;
}

function record(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'n1',
    userId: 'u1',
    channel: 'in_app',
    type: 'payment_confirmation',
    relatedAlertId: null,
    relatedTransactionId: null,
    status: 'queued',
    isRead: false,
    readAt: null,
    createdAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('PrismaNotificationRepository', () => {
  it('upserts a queued notification', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaNotificationRepository(prisma);
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });

    await repo.save(notification);

    expect(prisma.notification.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'n1' },
        create: expect.objectContaining({ id: 'n1', userId: 'u1', status: 'queued', isRead: false, readAt: null }),
        update: expect.objectContaining({ status: 'queued', isRead: false, readAt: null }),
      }),
    );
  });

  it('persists markAsRead state through save', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaNotificationRepository(prisma);
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });
    notification.markAsRead();

    await repo.save(notification);

    expect(prisma.notification.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ update: expect.objectContaining({ isRead: true, readAt: expect.any(Date) }) }),
    );
  });

  it('maps a found record to a domain Notification', async () => {
    const prisma = createPrismaMock();
    prisma.notification.findUnique.mockResolvedValue(record());
    const repo = new PrismaNotificationRepository(prisma);

    const notification = await repo.findById('n1');

    expect(notification?.id).toBe('n1');
    expect(notification?.status).toBe('queued');
  });

  it('returns null when not found', async () => {
    const prisma = createPrismaMock();
    prisma.notification.findUnique.mockResolvedValue(null);
    const repo = new PrismaNotificationRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('lists notifications for a user, newest first', async () => {
    const prisma = createPrismaMock();
    prisma.notification.findMany.mockResolvedValue([record({ id: 'n1' }), record({ id: 'n2' })]);
    const repo = new PrismaNotificationRepository(prisma);

    const notifications = await repo.findByUserId('u1');

    expect(notifications).toHaveLength(2);
    expect(prisma.notification.findMany).toHaveBeenCalledWith({ where: { userId: 'u1' }, orderBy: { createdAt: 'desc' } });
  });
});
