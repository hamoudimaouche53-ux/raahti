import { LanguagePreference } from '../../../shared-kernel';
import { User } from '../../identity/domain/entities/user.entity';
import { UserQueryService } from '../../identity/application/user-query.service';
import { Notification } from '../domain/entities/notification.entity';
import { NotificationRepository } from '../domain/ports/notification.repository';
import { NotificationSender } from '../infrastructure/channels/notification-sender.port';
import { NotificationCopyResolver } from './notification-copy-resolver';
import { NotificationDeliveryService } from './notification-delivery.service';

function createSenderMock(): jest.Mocked<NotificationSender> {
  return { send: jest.fn() };
}

function createRepoMock(): jest.Mocked<NotificationRepository> {
  return { save: jest.fn(), findById: jest.fn(), findByUserId: jest.fn() };
}

function createUserQueryServiceMock(language: LanguagePreference = LanguagePreference.FR): jest.Mocked<UserQueryService> {
  const user = User.create({ id: 'u1', email: 'a@example.com', preferredLanguage: language });
  return { findById: jest.fn().mockResolvedValue(user) } as unknown as jest.Mocked<UserQueryService>;
}

const NO_DELAY = jest.fn().mockResolvedValue(undefined);

describe('NotificationDeliveryService', () => {
  beforeEach(() => NO_DELAY.mockClear());

  it('marks the notification sent+delivered when the in-app sender succeeds on the first try', async () => {
    const inAppSender = createSenderMock();
    inAppSender.send.mockResolvedValue(undefined);
    const pushSender = createSenderMock();
    const repo = createRepoMock();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });
    const service = new NotificationDeliveryService(
      inAppSender,
      pushSender,
      repo,
      new NotificationCopyResolver(),
      createUserQueryServiceMock(),
      NO_DELAY,
    );

    await service.deliver(notification);

    expect(notification.status).toBe('delivered');
    expect(repo.save).toHaveBeenCalledWith(notification);
    expect(pushSender.send).not.toHaveBeenCalled();
  });

  it('routes a push-channel notification to the push sender', async () => {
    const inAppSender = createSenderMock();
    const pushSender = createSenderMock();
    pushSender.send.mockRejectedValue(new Error('not configured'));
    const repo = createRepoMock();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'push', type: 'availability' });
    const service = new NotificationDeliveryService(
      inAppSender,
      pushSender,
      repo,
      new NotificationCopyResolver(),
      createUserQueryServiceMock(),
      NO_DELAY,
    );

    await service.deliver(notification);

    expect(pushSender.send).toHaveBeenCalled();
    expect(inAppSender.send).not.toHaveBeenCalled();
  });

  it('retries up to 3 attempts with exponential backoff before marking failed', async () => {
    const inAppSender = createSenderMock();
    inAppSender.send.mockRejectedValue(new Error('transient failure'));
    const pushSender = createSenderMock();
    const repo = createRepoMock();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });
    const service = new NotificationDeliveryService(
      inAppSender,
      pushSender,
      repo,
      new NotificationCopyResolver(),
      createUserQueryServiceMock(),
      NO_DELAY,
    );

    await service.deliver(notification);

    expect(inAppSender.send).toHaveBeenCalledTimes(3);
    expect(notification.status).toBe('failed');
    expect(NO_DELAY).toHaveBeenCalledTimes(2); // between attempts 1->2 and 2->3, not after the final attempt
    expect(NO_DELAY).toHaveBeenNthCalledWith(1, 200);
    expect(NO_DELAY).toHaveBeenNthCalledWith(2, 400);
  });

  it('succeeds on a later attempt without exhausting retries', async () => {
    const inAppSender = createSenderMock();
    inAppSender.send.mockRejectedValueOnce(new Error('flaky')).mockResolvedValueOnce(undefined);
    const pushSender = createSenderMock();
    const repo = createRepoMock();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });
    const service = new NotificationDeliveryService(
      inAppSender,
      pushSender,
      repo,
      new NotificationCopyResolver(),
      createUserQueryServiceMock(),
      NO_DELAY,
    );

    await service.deliver(notification);

    expect(inAppSender.send).toHaveBeenCalledTimes(2);
    expect(notification.status).toBe('delivered');
  });

  it('resolves French copy by default and Arabic when the recipient prefers it', async () => {
    const inAppSender = createSenderMock();
    inAppSender.send.mockResolvedValue(undefined);
    const pushSender = createSenderMock();
    const repo = createRepoMock();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });
    const service = new NotificationDeliveryService(
      inAppSender,
      pushSender,
      repo,
      new NotificationCopyResolver(),
      createUserQueryServiceMock(LanguagePreference.AR),
      NO_DELAY,
    );

    await service.deliver(notification);

    const [, copyArg] = inAppSender.send.mock.calls[0];
    expect(copyArg.body).toBe('تم تأكيد دفعتك.');
  });

  it('falls back to French when the notification has no userId (e.g. a role-targeted operator alert)', async () => {
    const inAppSender = createSenderMock();
    inAppSender.send.mockResolvedValue(undefined);
    const pushSender = createSenderMock();
    const repo = createRepoMock();
    const userQueryService = createUserQueryServiceMock();
    const notification = Notification.queue({ id: 'n1', userId: null, channel: 'in_app', type: 'operator_alert' });
    const service = new NotificationDeliveryService(
      inAppSender,
      pushSender,
      repo,
      new NotificationCopyResolver(),
      userQueryService,
      NO_DELAY,
    );

    await service.deliver(notification);

    expect(userQueryService.findById).not.toHaveBeenCalled();
    const [, copyArg] = inAppSender.send.mock.calls[0];
    expect(copyArg.body).toBe('Nouvelle alerte sur votre site.');
  });
});
