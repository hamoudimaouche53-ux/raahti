import { randomUUID } from 'crypto';
import { Inject, Injectable } from '@nestjs/common';
import { DOMAIN_EVENT_BUS, DomainEventBus, Money } from '../../../shared-kernel';
import { UserQueryService } from '../../identity/application/user-query.service';
import { CabinNotFoundException as StationCabinNotFoundException } from '../../station-network/application/cabin-not-found.exception';
import { CabinUnavailableException as StationCabinUnavailableException } from '../../station-network/application/cabin-unavailable.exception';
import { StationCommandService } from '../../station-network/application/station-command.service';
import { AccessSession } from '../domain/entities/access-session.entity';
import { Transaction } from '../domain/entities/transaction.entity';
import { PaymentCapturedEvent } from '../domain/events/payment-captured.event';
import { ACCESS_SESSION_REPOSITORY, AccessSessionRepository } from '../domain/ports/access-session.repository';
import { LOCK_CONTROL_GATEWAY, LockControlGateway } from '../domain/ports/lock-control-gateway';
import { PAYMENT_GATEWAY, PaymentGateway } from '../domain/ports/payment-gateway';
import { TRANSACTION_REPOSITORY, TransactionRepository } from '../domain/ports/transaction.repository';
import { AccessSessionForbiddenException } from './access-session-forbidden.exception';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';
import { CabinUnavailableException } from './cabin-unavailable.exception';
import { IdempotencyService } from './idempotency.service';
import { PaymentDeclinedException } from './payment-declined.exception';
import { UnlockFailedRefundedException } from './unlock-failed-refunded.exception';

const ENDPOINT = 'POST /access-sessions/:id/payments';

/**
 * FR-EMG-03 — Mode Urgence 50% discount. Duplicated here rather than
 * importing `EmergencyModule`'s `EmergencyDiscountPolicy` (ADR-0031): the
 * module-dependency-diagram.md §3 matrix grants `EmergencyModule` no
 * sanctioned incoming edge from any module (enforced by an eslint
 * `import/no-restricted-paths` zone — "no module may depend on emergency/"),
 * so AccessPaymentModule independently re-implements the same one-line
 * `diabeticVerificationStatus === 'verified'` check against Identity's data
 * instead. See ADR-0031 for why this is a deliberate two-independent-checks
 * design, not an oversight.
 */
const EMERGENCY_DISCOUNT_PERCENTAGE = 50;

export interface AuthorizeAndCapturePaymentParams {
  accessSessionId: string;
  callerId: string;
  paymentMethodId?: string | null;
  applyEmergencyDiscount?: boolean;
  idempotencyKey: string;
}

export interface AuthorizeAndCapturePaymentResult {
  session: AccessSession;
  transaction: Transaction | null;
}

/**
 * FR-PAY-03/04 — POST /access-sessions/{id}/payments. Implements the
 * Sequence Diagrams §1 "QR Scan -> Payment -> Unlock" flow, including its
 * failure/refund branch (Risk R-11/R-12, ADR-0014).
 *
 * `applyEmergencyDiscount` (`PaymentRequest.applyEmergencyDiscount` per
 * openapi.yaml) is implemented (ADR-0031) — previously a documented V1
 * no-op because Identity was not a sanctioned read dependency for this
 * module; that gap is now closed by a dedicated `AccessPay -.->|read|
 * Identity` edge (module-dependency-diagram.md §3). The caller's
 * `diabeticVerificationStatus` is re-verified server-side against Identity's
 * data — the client's boolean flag alone is never trusted for a real
 * monetary discount (Risk R-01). An ineligible caller who still sends
 * `applyEmergencyDiscount: true` is silently charged full price, never
 * rejected — this endpoint's contract is "apply the discount if eligible,"
 * not "validate eligibility as a precondition."
 */
@Injectable()
export class AuthorizeAndCapturePaymentService {
  constructor(
    @Inject(ACCESS_SESSION_REPOSITORY) private readonly accessSessionRepository: AccessSessionRepository,
    @Inject(TRANSACTION_REPOSITORY) private readonly transactionRepository: TransactionRepository,
    @Inject(PAYMENT_GATEWAY) private readonly paymentGateway: PaymentGateway,
    @Inject(LOCK_CONTROL_GATEWAY) private readonly lockControlGateway: LockControlGateway,
    @Inject(DOMAIN_EVENT_BUS) private readonly eventBus: DomainEventBus,
    private readonly stationCommandService: StationCommandService,
    private readonly idempotencyService: IdempotencyService,
    private readonly userQueryService: UserQueryService,
  ) {}

  async execute(params: AuthorizeAndCapturePaymentParams): Promise<AuthorizeAndCapturePaymentResult> {
    return this.idempotencyService.run<AuthorizeAndCapturePaymentResult>(
      { userId: params.callerId, key: params.idempotencyKey, endpoint: ENDPOINT },
      200,
      async () => {
        const result = await this.doExecute(params);
        return { cacheable: { accessSessionId: result.session.id }, result };
      },
      async (cached) => {
        const { accessSessionId } = cached as { accessSessionId: string };
        const session = await this.accessSessionRepository.findById(accessSessionId);
        if (!session) {
          throw new AccessSessionNotFoundException(accessSessionId);
        }
        const transaction = await this.transactionRepository.findByAccessSessionId(accessSessionId);
        return { session, transaction };
      },
    );
  }

  private async doExecute(params: AuthorizeAndCapturePaymentParams): Promise<AuthorizeAndCapturePaymentResult> {
    const session = await this.accessSessionRepository.findById(params.accessSessionId);
    if (!session) {
      throw new AccessSessionNotFoundException(params.accessSessionId);
    }
    if (session.userId !== params.callerId) {
      throw new AccessSessionForbiddenException(params.accessSessionId);
    }

    let cabin;
    try {
      cabin = await this.stationCommandService.checkCabinAvailability(session.cabinId);
    } catch (error) {
      if (error instanceof StationCabinNotFoundException || error instanceof StationCabinUnavailableException) {
        throw new CabinUnavailableException(session.cabinId);
      }
      throw error;
    }

    if (!cabin.isPaid) {
      return this.handleFreeCabin(session);
    }
    if (!cabin.price) {
      // Invariant violation — Cabin.restore() guarantees isPaid implies price is set. Defensive only.
      throw new CabinUnavailableException(session.cabinId);
    }
    return this.handlePaidCabin(session, cabin.price, params);
  }

  /**
   * FR-EMG-03 — re-verifies the caller's `diabeticVerificationStatus`
   * server-side (never trusts `applyEmergencyDiscount` alone, Risk R-01).
   * Ineligible/missing-user is a silent full-price fallback, not an error —
   * see class doc comment.
   */
  private async resolveEmergencyDiscount(
    price: Money,
    params: AuthorizeAndCapturePaymentParams,
  ): Promise<{ finalPrice: Money; discountApplied: number | null }> {
    if (!params.applyEmergencyDiscount) {
      return { finalPrice: price, discountApplied: null };
    }
    const user = await this.userQueryService.findById(params.callerId);
    if (!user || user.diabeticVerificationStatus !== 'verified') {
      return { finalPrice: price, discountApplied: null };
    }
    return {
      finalPrice: price.applyDiscountPercentage(EMERGENCY_DISCOUNT_PERCENTAGE),
      discountApplied: EMERGENCY_DISCOUNT_PERCENTAGE,
    };
  }

  private async handleFreeCabin(session: AccessSession): Promise<AuthorizeAndCapturePaymentResult> {
    const unlock = await this.lockControlGateway.issueUnlockOrder({ cabinId: session.cabinId, accessSessionId: session.id });
    if (unlock.result !== 'unlocked') {
      throw new UnlockFailedRefundedException(session.id);
    }

    session.markUnlocked();
    await this.stationCommandService.setCabinOccupancy(session.cabinId, 'occupied');
    await this.accessSessionRepository.save(session);
    return { session, transaction: null };
  }

  private async handlePaidCabin(
    session: AccessSession,
    price: Money,
    params: AuthorizeAndCapturePaymentParams,
  ): Promise<AuthorizeAndCapturePaymentResult> {
    session.markPaymentPending();
    await this.accessSessionRepository.save(session);

    const { finalPrice, discountApplied } = await this.resolveEmergencyDiscount(price, params);

    let transaction = Transaction.pending({
      id: randomUUID(),
      userId: params.callerId,
      accessSessionId: session.id,
      paymentMethodId: params.paymentMethodId ?? null,
      amount: finalPrice,
      discountApplied,
    });

    const paymentMethodRef = params.paymentMethodId ?? '';
    let authorization;
    try {
      authorization = await this.paymentGateway.authorize(finalPrice, paymentMethodRef, params.idempotencyKey);
    } catch {
      transaction.fail();
      await this.transactionRepository.save(transaction);
      throw new PaymentDeclinedException(session.id);
    }
    transaction.authorize(authorization.providerRef);

    let capture;
    try {
      capture = await this.paymentGateway.capture(authorization.authorizationId);
    } catch {
      transaction.fail();
      await this.transactionRepository.save(transaction);
      throw new PaymentDeclinedException(session.id);
    }
    transaction.capture();
    transaction = await this.transactionRepository.save(transaction);

    const unlock = await this.lockControlGateway.issueUnlockOrder({ cabinId: session.cabinId, accessSessionId: session.id });
    if (unlock.result !== 'unlocked') {
      await this.paymentGateway.refund(capture.captureId, finalPrice);
      transaction.refund();
      await this.transactionRepository.save(transaction);
      throw new UnlockFailedRefundedException(session.id);
    }

    session.markUnlocked();
    await this.stationCommandService.setCabinOccupancy(session.cabinId, 'occupied');

    const event: PaymentCapturedEvent = {
      eventName: 'PaymentCaptured',
      occurredAt: new Date(),
      userId: params.callerId,
      transactionId: transaction.id,
    };
    await this.eventBus.publish(event);

    await this.accessSessionRepository.save(session);

    return { session, transaction };
  }
}
