/**
 * Domain-event bus contract used by every module's application/ layer
 * (module-dependency-diagram.md §5 rule 4 — cross-module side effects are
 * event-based, not synchronous, except the two documented command dependencies).
 * `subscribe` was missing from the original Pass 1 bootstrap version of this
 * contract even though shared-kernel's own README already described it as a
 * "publish/subscribe interface" — added when NotificationsModule became the
 * first real subscriber (Notifications Pass 4), not a new architecture decision.
 */
export interface DomainEvent {
  readonly eventName: string;
  readonly occurredAt: Date;
}

export interface DomainEventBus {
  publish(event: DomainEvent): Promise<void>;
  publishAll(events: readonly DomainEvent[]): Promise<void>;
  subscribe<T extends DomainEvent>(eventName: string, handler: (event: T) => Promise<void>): void;
}

export const DOMAIN_EVENT_BUS = Symbol('DOMAIN_EVENT_BUS');
