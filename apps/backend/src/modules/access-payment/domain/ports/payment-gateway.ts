import { Money } from '../../../../shared-kernel';

export const PAYMENT_GATEWAY = Symbol('PAYMENT_GATEWAY');

export interface PaymentAuthorizationResult {
  authorizationId: string;
  providerRef: string;
}

export interface PaymentCaptureResult {
  captureId: string;
  providerRef: string;
}

export interface PaymentRefundResult {
  refundId: string;
}

export interface TokenizedPaymentMethod {
  providerRef: string;
}

/**
 * ADR-0014 — provider-agnostic payment Anti-Corruption Layer. `amount` is
 * the codebase's shared-kernel `Money` VO (carries amount + currency
 * together) rather than separate amount/currency primitives — the same
 * convention every other money-shaped value in this codebase already uses
 * (`Cabin.price`, `MoneyDto`), and matches ADR-0014's own `authorize(amount:
 * Money, ...)` signature exactly.
 */
export interface PaymentGateway {
  authorize(amount: Money, paymentMethodRef: string, idempotencyKey: string): Promise<PaymentAuthorizationResult>;
  capture(authorizationId: string): Promise<PaymentCaptureResult>;
  refund(captureId: string, amount: Money): Promise<PaymentRefundResult>;
  tokenizePaymentMethod(rawMethodToken: string): Promise<TokenizedPaymentMethod>;
}
