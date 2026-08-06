import { randomUUID } from 'crypto';
import { Inject, Injectable } from '@nestjs/common';
import { DOMAIN_EVENT_BUS, DomainEventBus, Money } from '../../../shared-kernel';
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
 * `applyEmergencyDiscount` is accepted (`PaymentRequest.applyEmergencyDiscount`
 * per openapi.yaml) but is a **documented V1 no-op**: Mode Urgence
 * eligibility (FR-EMG-03) requires reading the caller's
 * `diabeticVerificationStatus`, which lives on Identity's `User` aggregate —
 * Identity is not a sanctioned read dependency for AccessPaymentModule
 * (module-dependency-diagram.md §3 grants `AccessPay` no edge to `Identity`
 * at all, unlike e.g. `Emergency -.->|read| Identity`). The flag is accepted
 * and silently ignored (never rejected) so a client sending it doesn't get
 * an error, but no discount is ever computed or persisted this pass —
 * flagged here explicitly, not silently dropped.
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

    // applyEmergencyDiscount is intentionally not applied here — see class doc comment.
    let transaction = Transaction.pending({
      id: randomUUID(),
      userId: params.callerId,
      accessSessionId: session.id,
      paymentMethodId: params.paymentMethodId ?? null,
      amount: price,
    });

    const paymentMethodRef = params.paymentMethodId ?? '';
    let authorization;
    try {
      authorization = await this.paymentGateway.authorize(price, paymentMethodRef, params.idempotencyKey);
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
      await this.paymentGateway.refund(capture.captureId, price);
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
