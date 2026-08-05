/**
 * Domain-event bus contract used by every module's application/ layer
 * (module-dependency-diagram.md §5 rule 4 — cross-module side effects are
 * event-based, not synchronous, except the two documented command dependencies).
 */
export interface DomainEvent {
  readonly eventName: string;
  readonly occurredAt: Date;
}

export interface DomainEventBus {
  publish(event: DomainEvent): Promise<void>;
  publishAll(events: readonly DomainEvent[]): Promise<void>;
}
