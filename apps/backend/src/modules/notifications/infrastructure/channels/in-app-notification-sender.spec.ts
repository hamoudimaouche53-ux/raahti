import { Notification } from '../../domain/entities/notification.entity';
import { InAppNotificationSender } from './in-app-notification-sender';

describe('InAppNotificationSender', () => {
  it('always succeeds (the persisted row is the delivery)', async () => {
    const sender = new InAppNotificationSender();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'availability' });

    await expect(sender.send(notification, { title: 't', body: 'b' })).resolves.toBeUndefined();
  });
});
