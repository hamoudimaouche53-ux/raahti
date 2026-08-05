import { DomainEventBus } from '../../../shared-kernel';
import { PaymentCapturedEvent } from '../domain/events/payment-captured.event';
import { NotificationEventSubscriber } from './notification-event-subscriber';
import { NotificationService } from './notification.service';

describe('NotificationEventSubscriber', () => {
  it('subscribes to PaymentCaptured on module init', () => {
    const eventBus = { subscribe: jest.fn(), publish: jest.fn(), publishAll: jest.fn() } as unknown as jest.Mocked<DomainEventBus>;
    const notificationService = { queue: jest.fn() } as unknown as jest.Mocked<NotificationService>;
    const subscriber = new NotificationEventSubscriber(eventBus, notificationService);

    subscriber.onModuleInit();

    expect(eventBus.subscribe).toHaveBeenCalledWith('PaymentCaptured', expect.any(Function));
  });

  it('queues a payment_confirmation notification when a PaymentCaptured event is delivered', async () => {
    let capturedHandler: ((event: PaymentCapturedEvent) => Promise<void>) | undefined;
    const eventBus = {
      subscribe: jest.fn((_name: string, handler: (event: PaymentCapturedEvent) => Promise<void>) => {
        capturedHandler = handler;
      }),
      publish: jest.fn(),
      publishAll: jest.fn(),
    } as unknown as jest.Mocked<DomainEventBus>;
    const notificationService = { queue: jest.fn().mockResolvedValue(undefined) } as unknown as jest.Mocked<NotificationService>;
    const subscriber = new NotificationEventSubscriber(eventBus, notificationService);
    subscriber.onModuleInit();

    await capturedHandler!({ eventName: 'PaymentCaptured', occurredAt: new Date(), userId: 'u1', transactionId: 't1' });

    expect(notificationService.queue).toHaveBeenCalledWith({
      userId: 'u1',
      channel: 'in_app',
      type: 'payment_confirmation',
      relatedTransactionId: 't1',
    });
  });
});
