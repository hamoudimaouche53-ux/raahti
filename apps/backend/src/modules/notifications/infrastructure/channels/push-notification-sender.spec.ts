import { Notification } from '../../domain/entities/notification.entity';
import { PushNotificationNotConfiguredException, PushNotificationSender } from './push-notification-sender';

describe('PushNotificationSender', () => {
  it('always throws PushNotificationNotConfiguredException (no FCM/APNs credentials, no device-token storage)', async () => {
    const sender = new PushNotificationSender();
    const notification = Notification.queue({ id: 'n1', userId: 'u1', channel: 'push', type: 'availability' });

    await expect(sender.send(notification, { title: 't', body: 'b' })).rejects.toThrow(
      PushNotificationNotConfiguredException,
    );
  });
});
