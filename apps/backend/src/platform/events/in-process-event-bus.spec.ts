import { DomainEvent } from '../../shared-kernel';
import { InProcessEventBus } from './in-process-event-bus';

interface TestEvent extends DomainEvent {
  eventName: 'TestEvent';
  payload: string;
}

describe('InProcessEventBus', () => {
  it('delivers a published event to a subscribed handler', async () => {
    const bus = new InProcessEventBus();
    const handler = jest.fn().mockResolvedValue(undefined);
    bus.subscribe<TestEvent>('TestEvent', handler);

    const event: TestEvent = { eventName: 'TestEvent', occurredAt: new Date(), payload: 'hello' };
    await bus.publish(event);

    expect(handler).toHaveBeenCalledWith(event);
  });

  it('delivers to multiple subscribers of the same event', async () => {
    const bus = new InProcessEventBus();
    const first = jest.fn().mockResolvedValue(undefined);
    const second = jest.fn().mockResolvedValue(undefined);
    bus.subscribe<TestEvent>('TestEvent', first);
    bus.subscribe<TestEvent>('TestEvent', second);

    const event: TestEvent = { eventName: 'TestEvent', occurredAt: new Date(), payload: 'x' };
    await bus.publish(event);

    expect(first).toHaveBeenCalledTimes(1);
    expect(second).toHaveBeenCalledTimes(1);
  });

  it('does nothing when an event has no subscribers', async () => {
    const bus = new InProcessEventBus();
    await expect(bus.publish({ eventName: 'Unheard', occurredAt: new Date() })).resolves.toBeUndefined();
  });

  it('only delivers to handlers subscribed to the matching eventName', async () => {
    const bus = new InProcessEventBus();
    const handler = jest.fn().mockResolvedValue(undefined);
    bus.subscribe('EventA', handler);

    await bus.publish({ eventName: 'EventB', occurredAt: new Date() });

    expect(handler).not.toHaveBeenCalled();
  });

  it('publishAll publishes every event', async () => {
    const bus = new InProcessEventBus();
    const handler = jest.fn().mockResolvedValue(undefined);
    bus.subscribe<TestEvent>('TestEvent', handler);

    const events: TestEvent[] = [
      { eventName: 'TestEvent', occurredAt: new Date(), payload: 'a' },
      { eventName: 'TestEvent', occurredAt: new Date(), payload: 'b' },
    ];
    await bus.publishAll(events);

    expect(handler).toHaveBeenCalledTimes(2);
  });
});
