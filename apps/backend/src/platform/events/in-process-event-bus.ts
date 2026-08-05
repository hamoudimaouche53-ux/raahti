import { Injectable } from '@nestjs/common';
import { DomainEvent, DomainEventBus } from '../../shared-kernel';

type Handler<T extends DomainEvent = DomainEvent> = (event: T) => Promise<void>;

/**
 * Concrete implementation of shared-kernel's DomainEventBus contract — the
 * contract existed since Phase 4 bootstrap but nothing implemented it until
 * NotificationsModule needed a real subscriber. In-process only (a plain
 * in-memory pub/sub registry, no external message broker) — matches "do not
 * introduce infrastructure beyond current project scope" for a modular
 * monolith (ADR-0003) at V1 scale; module-dependency-diagram.md's event-based
 * cross-module communication rule doesn't mandate a distributed broker, only
 * that it be event-based rather than a synchronous call.
 */
@Injectable()
export class InProcessEventBus implements DomainEventBus {
  private readonly handlers = new Map<string, Handler[]>();

  async publish(event: DomainEvent): Promise<void> {
    const handlers = this.handlers.get(event.eventName) ?? [];
    await Promise.all(handlers.map((handler) => handler(event)));
  }

  async publishAll(events: readonly DomainEvent[]): Promise<void> {
    await Promise.all(events.map((event) => this.publish(event)));
  }

  subscribe<T extends DomainEvent>(eventName: string, handler: (event: T) => Promise<void>): void {
    const existing = this.handlers.get(eventName) ?? [];
    existing.push(handler as Handler);
    this.handlers.set(eventName, existing);
  }
}
