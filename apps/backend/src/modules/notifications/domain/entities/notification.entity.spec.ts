import {
  InconsistentReadStateException,
  InvalidNotificationStatusTransitionException,
  Notification,
} from './notification.entity';

function queueNotification() {
  return Notification.queue({ id: 'n1', userId: 'u1', channel: 'in_app', type: 'payment_confirmation' });
}

describe('Notification', () => {
  it('starts queued, unread, with no read timestamp', () => {
    const notification = queueNotification();
    expect(notification.status).toBe('queued');
    expect(notification.isRead).toBe(false);
    expect(notification.readAt).toBeNull();
  });

  describe('markAsRead', () => {
    it('sets isRead and readAt on first call', () => {
      const notification = queueNotification();
      notification.markAsRead();
      expect(notification.isRead).toBe(true);
      expect(notification.readAt).not.toBeNull();
    });

    it('is idempotent — readAt never advances on repeat calls', () => {
      const notification = queueNotification();
      notification.markAsRead();
      const firstReadAt = notification.readAt;

      notification.markAsRead();
      notification.markAsRead();

      expect(notification.readAt).toEqual(firstReadAt);
    });
  });

  describe('status transitions', () => {
    it('allows queued -> sent -> delivered', () => {
      const notification = queueNotification();
      notification.markSent();
      expect(notification.status).toBe('sent');
      notification.markDelivered();
      expect(notification.status).toBe('delivered');
    });

    it('allows queued -> sent -> failed', () => {
      const notification = queueNotification();
      notification.markSent();
      notification.markFailed();
      expect(notification.status).toBe('failed');
    });

    it('allows queued -> failed directly (e.g. sender rejects before dispatch)', () => {
      const notification = queueNotification();
      notification.markFailed();
      expect(notification.status).toBe('failed');
    });

    it('rejects delivered before sent', () => {
      const notification = queueNotification();
      expect(() => notification.markDelivered()).toThrow(InvalidNotificationStatusTransitionException);
    });

    it('rejects any transition once delivered', () => {
      const notification = queueNotification();
      notification.markSent();
      notification.markDelivered();
      expect(() => notification.markSent()).toThrow(InvalidNotificationStatusTransitionException);
      expect(() => notification.markFailed()).toThrow(InvalidNotificationStatusTransitionException);
    });

    it('rejects any transition once failed', () => {
      const notification = queueNotification();
      notification.markFailed();
      expect(() => notification.markSent()).toThrow(InvalidNotificationStatusTransitionException);
    });
  });

  describe('restore', () => {
    it('accepts a consistent unread record', () => {
      expect(() =>
        Notification.restore({
          id: 'n1',
          userId: 'u1',
          channel: 'in_app',
          type: 'availability',
          relatedAlertId: null,
          relatedTransactionId: null,
          status: 'queued',
          isRead: false,
          readAt: null,
          createdAt: new Date(),
        }),
      ).not.toThrow();
    });

    it('accepts a consistent read record', () => {
      expect(() =>
        Notification.restore({
          id: 'n1',
          userId: 'u1',
          channel: 'in_app',
          type: 'availability',
          relatedAlertId: null,
          relatedTransactionId: null,
          status: 'delivered',
          isRead: true,
          readAt: new Date(),
          createdAt: new Date(),
        }),
      ).not.toThrow();
    });

    it('rejects isRead=true with readAt=null', () => {
      expect(() =>
        Notification.restore({
          id: 'n1',
          userId: 'u1',
          channel: 'in_app',
          type: 'availability',
          relatedAlertId: null,
          relatedTransactionId: null,
          status: 'delivered',
          isRead: true,
          readAt: null,
          createdAt: new Date(),
        }),
      ).toThrow(InconsistentReadStateException);
    });

    it('rejects isRead=false with readAt set', () => {
      expect(() =>
        Notification.restore({
          id: 'n1',
          userId: 'u1',
          channel: 'in_app',
          type: 'availability',
          relatedAlertId: null,
          relatedTransactionId: null,
          status: 'queued',
          isRead: false,
          readAt: new Date(),
          createdAt: new Date(),
        }),
      ).toThrow(InconsistentReadStateException);
    });
  });
});
