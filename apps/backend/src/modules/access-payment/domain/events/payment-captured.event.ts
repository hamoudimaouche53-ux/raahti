import { DomainEvent } from '../../../../shared-kernel';

/**
 * Domain Model §6 lists six domain events (AccessSessionInitiated,
 * PaymentAuthorized, PaymentCaptured, PaymentFailed, UnlockOrderIssued,
 * CabinAccessCompleted) — only `PaymentCaptured` is actually published this
 * pass (module-dependency-diagram.md §4: `AP -.->|event: PaymentCaptured| NT`,
 * consumed by `NotificationEventSubscriber`). Declared independently here
 * rather than importing notifications/domain/events/payment-captured.event.ts
 * — no module may depend on notifications/ (module-dependency-diagram.md §3
 * grants it no incoming edges at all); the publisher and subscriber sides of
 * an event-based contract each own their side of the shape. Kept identical
 * in structure to the consumer's definition by convention, not by import.
 */
export interface PaymentCapturedEvent extends DomainEvent {
  eventName: 'PaymentCaptured';
  userId: string;
  transactionId: string;
}
