import { Module } from '@nestjs/common';
import { IdentityModule } from '../identity/identity.module';
import { StationNetworkModule } from '../station-network/station-network.module';
import { AccessSessionQueryService } from './application/access-session-query.service';
import { AuthorizeAndCapturePaymentService } from './application/authorize-and-capture-payment.service';
import { CompleteAccessSessionService } from './application/complete-access-session.service';
import { IdempotencyService } from './application/idempotency.service';
import { InitiateAccessSessionService } from './application/initiate-access-session.service';
import { VisitHistoryQueryService } from './application/visit-history-query.service';
import { ACCESS_SESSION_REPOSITORY } from './domain/ports/access-session.repository';
import { IDEMPOTENCY_KEY_REPOSITORY } from './domain/ports/idempotency-key.repository';
import { LOCK_CONTROL_GATEWAY } from './domain/ports/lock-control-gateway';
import { PAYMENT_GATEWAY } from './domain/ports/payment-gateway';
import { TRANSACTION_REPOSITORY } from './domain/ports/transaction.repository';
import { MockLockControlAdapter } from './infrastructure/gateways/mock-lock-control.adapter';
import { MockPaymentGatewayAdapter } from './infrastructure/gateways/mock-payment-gateway.adapter';
import { PrismaAccessSessionRepository } from './infrastructure/persistence/prisma-access-session.repository';
import { PrismaIdempotencyKeyRepository } from './infrastructure/persistence/prisma-idempotency-key.repository';
import { PrismaTransactionRepository } from './infrastructure/persistence/prisma-transaction.repository';
import { AccessSessionsController } from './interface/controllers/access-sessions.controller';
import { VisitHistoryController } from './interface/controllers/visit-history.controller';

/**
 * Access & Payment bounded context (Domain Model §6) — "owns the QR-scan-
 * to-unlock journey and the transactional record of payment" (EPIC-04,
 * V1-critical). Imports StationNetworkModule only to reach its exported
 * StationCommandService — the sanctioned `AccessPay -> StationNet` COMMAND
 * edge (module-dependency-diagram.md §3, distinct from the read-only
 * `✔(read)` edges other modules get): cabin availability is checked
 * synchronously before payment, and occupancy is written synchronously
 * around the unlock/complete flow. `PaymentGateway` (ADR-0014) and
 * `LockControlGateway` (ADR-0030) are both wired to their deterministic
 * mock adapters — no real payment provider or IoT ingestion service exists
 * yet; swapping either for a real adapter later touches only this module's
 * provider list, never the application/domain layers (both ADRs' explicit
 * intent). Also imports IdentityModule to reach its exported UserQueryService
 * — the `AccessPay -.->|read| Identity` edge added by ADR-0031 so
 * AuthorizeAndCapturePaymentService can independently re-verify the caller's
 * `diabeticVerificationStatus` server-side (FR-EMG-03) rather than trusting
 * `applyEmergencyDiscount` unchecked.
 */
@Module({
  imports: [StationNetworkModule, IdentityModule],
  controllers: [AccessSessionsController, VisitHistoryController],
  providers: [
    { provide: ACCESS_SESSION_REPOSITORY, useClass: PrismaAccessSessionRepository },
    { provide: TRANSACTION_REPOSITORY, useClass: PrismaTransactionRepository },
    { provide: IDEMPOTENCY_KEY_REPOSITORY, useClass: PrismaIdempotencyKeyRepository },
    { provide: PAYMENT_GATEWAY, useClass: MockPaymentGatewayAdapter },
    { provide: LOCK_CONTROL_GATEWAY, useClass: MockLockControlAdapter },
    IdempotencyService,
    InitiateAccessSessionService,
    AuthorizeAndCapturePaymentService,
    AccessSessionQueryService,
    CompleteAccessSessionService,
    VisitHistoryQueryService,
  ],
})
export class AccessPaymentModule {}
