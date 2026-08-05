import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { NotificationService } from '../src/modules/notifications/application/notification.service';
import { Notification } from '../src/modules/notifications/domain/entities/notification.entity';
import { NOTIFICATION_REPOSITORY, NotificationRepository } from '../src/modules/notifications/domain/ports/notification.repository';
import { NotificationsController } from '../src/modules/notifications/interface/controllers/notifications.controller';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';

const CURRENT_USER_ID = 'u1';
const NOTIFICATION_1 = '550e8400-e29b-41d4-a716-446655440000';
const NOTIFICATION_2 = '6ba7b810-9dad-41d4-80b4-00c04fd430c8';
const OTHER_USER_NOTIFICATION = '16fd2706-8baf-433b-82eb-8c7fada847da';
const UNKNOWN_NOTIFICATION = '6ba7b810-9dad-41d4-80b4-00c04fd430c9';

class InMemoryNotificationRepository implements NotificationRepository {
  private readonly items = new Map<string, Notification>();

  seed(notification: Notification): void {
    this.items.set(notification.id, notification);
  }

  async save(notification: Notification): Promise<void> {
    this.items.set(notification.id, notification);
  }

  async findById(id: string): Promise<Notification | null> {
    return this.items.get(id) ?? null;
  }

  async findByUserId(userId: string): Promise<Notification[]> {
    return [...this.items.values()].filter((n) => n.userId === userId);
  }
}

describe('Notifications endpoints (e2e)', () => {
  let app: INestApplication;
  let repo: InMemoryNotificationRepository;

  beforeAll(async () => {
    repo = new InMemoryNotificationRepository();
    repo.seed(
      Notification.queue({ id: NOTIFICATION_1, userId: CURRENT_USER_ID, channel: 'in_app', type: 'payment_confirmation' }),
    );
    repo.seed(Notification.queue({ id: NOTIFICATION_2, userId: CURRENT_USER_ID, channel: 'push', type: 'availability' }));
    repo.seed(
      Notification.queue({ id: OTHER_USER_NOTIFICATION, userId: 'someone-else', channel: 'in_app', type: 'operator_alert' }),
    );

    const moduleRef = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [NotificationService, { provide: NOTIFICATION_REPOSITORY, useValue: repo }],
    }).compile();

    app = moduleRef.createNestApplication();
    app.use((req: { user?: unknown }, _res: unknown, next: () => void) => {
      req.user = { sub: CURRENT_USER_ID, exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it("lists only the current user's notifications, each with isRead/readAt", async () => {
    const res = await request(app.getHttpServer()).get('/users/me/notifications').expect(200);

    const ids = res.body.data.map((n: { id: string }) => n.id);
    expect(ids.sort()).toEqual([NOTIFICATION_1, NOTIFICATION_2].sort());
    expect(res.body.data[0]).toEqual(expect.objectContaining({ isRead: false, readAt: null, status: 'queued' }));
  });

  it('marks a notification as read', async () => {
    const res = await request(app.getHttpServer()).patch(`/users/me/notifications/${NOTIFICATION_1}`).expect(200);

    expect(res.body.isRead).toBe(true);
    expect(res.body.readAt).not.toBeNull();
  });

  it('is idempotent — marking an already-read notification again keeps the same readAt', async () => {
    const first = await request(app.getHttpServer()).patch(`/users/me/notifications/${NOTIFICATION_2}`).expect(200);
    const second = await request(app.getHttpServer()).patch(`/users/me/notifications/${NOTIFICATION_2}`).expect(200);

    expect(second.body.readAt).toBe(first.body.readAt);
  });

  it('returns 404 for a notification belonging to a different user (no existence leak)', async () => {
    await request(app.getHttpServer()).patch(`/users/me/notifications/${OTHER_USER_NOTIFICATION}`).expect(404);
  });

  it('returns 404 for an unknown notification id', async () => {
    await request(app.getHttpServer()).patch(`/users/me/notifications/${UNKNOWN_NOTIFICATION}`).expect(404);
  });

  it('rejects a malformed notification id with 400', async () => {
    await request(app.getHttpServer()).patch('/users/me/notifications/not-a-uuid').expect(400);
  });
});
