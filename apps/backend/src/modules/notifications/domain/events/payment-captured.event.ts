import { DomainEvent } from '../../../../shared-kernel';

/**
 * Consumer-defined event contract (domain-model.md §8: Notifications
 * "Subscribes to... PaymentCaptured (Access & Payment)"). AccessPaymentModule
 * doesn't exist yet (out of scope for this pass — see Phase 4 Implementation
 * Plan §4/§6), so there is no publisher to match this shape against; defined
 * here, by the consumer, so the subscriber wiring is real and testable now,
 * and ready to receive a matching event the moment AccessPaymentModule is
 * built and publishes one.
 */
export interface PaymentCapturedEvent extends DomainEvent {
  eventName: 'PaymentCaptured';
  userId: string;
  transactionId: string;
}
