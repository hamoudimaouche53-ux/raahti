import { randomUUID } from 'crypto';
import { Injectable, Optional } from '@nestjs/common';
import { Money } from '../../../../shared-kernel';
import {
  PaymentAuthorizationResult,
  PaymentCaptureResult,
  PaymentGateway,
  PaymentRefundResult,
  TokenizedPaymentMethod,
} from '../../domain/ports/payment-gateway';

export interface MockPaymentGatewayConfig {
  /** Forces authorize()/capture() to throw, for deterministically exercising the 402 path in tests. Default false. */
  alwaysDecline?: boolean;
}

/**
 * ADR-0014 — deterministic, in-memory `PaymentGateway` implementation used
 * "for all Phase 1-era development, testing, and demo environments until a
 * provider is approved". `@Optional()` on the config param so NestJS's
 * `useClass: MockPaymentGatewayAdapter` wiring (no config provider
 * registered) resolves it to `undefined`, falling through to the default
 * `{}` — direct `new MockPaymentGatewayAdapter({ alwaysDecline: true })`
 * construction in tests bypasses DI entirely and is unaffected.
 */
@Injectable()
export class MockPaymentGatewayAdapter implements PaymentGateway {
  constructor(@Optional() private readonly config: MockPaymentGatewayConfig = {}) {}

  async authorize(_amount: Money, _paymentMethodRef: string, _idempotencyKey: string): Promise<PaymentAuthorizationResult> {
    if (this.config.alwaysDecline) {
      throw new Error('MockPaymentGatewayAdapter: authorize() declined (alwaysDecline=true).');
    }
    return { authorizationId: `mock-auth-${randomUUID()}`, providerRef: `mock-prov-${randomUUID()}` };
  }

  async capture(_authorizationId: string): Promise<PaymentCaptureResult> {
    if (this.config.alwaysDecline) {
      throw new Error('MockPaymentGatewayAdapter: capture() declined (alwaysDecline=true).');
    }
    return { captureId: `mock-cap-${randomUUID()}`, providerRef: `mock-prov-${randomUUID()}` };
  }

  async refund(_captureId: string, _amount: Money): Promise<PaymentRefundResult> {
    return { refundId: `mock-ref-${randomUUID()}` };
  }

  async tokenizePaymentMethod(_rawMethodToken: string): Promise<TokenizedPaymentMethod> {
    return { providerRef: `mock-token-${randomUUID()}` };
  }
}
