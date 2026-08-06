import { DomainEventBus, Money } from '../../../shared-kernel';
import { UserQueryService } from '../../identity/application/user-query.service';
import { Cabin } from '../../station-network/domain/entities/cabin.entity';
import { CabinUnavailableException as StationCabinUnavailableException } from '../../station-network/application/cabin-unavailable.exception';
import { StationCommandService } from '../../station-network/application/station-command.service';
import { AccessSession } from '../domain/entities/access-session.entity';
import { AccessSessionRepository } from '../domain/ports/access-session.repository';
import { IdempotencyRecord, IdempotencyKeyRepository } from '../domain/ports/idempotency-key.repository';
import { LockControlGateway } from '../domain/ports/lock-control-gateway';
import { PaymentGateway } from '../domain/ports/payment-gateway';
import { TransactionRepository } from '../domain/ports/transaction.repository';
import { AccessSessionForbiddenException } from './access-session-forbidden.exception';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';
import { AuthorizeAndCapturePaymentService } from './authorize-and-capture-payment.service';
import { CabinUnavailableException } from './cabin-unavailable.exception';
import { IdempotencyService } from './idempotency.service';
import { PaymentDeclinedException } from './payment-declined.exception';
import { UnlockFailedRefundedException } from './unlock-failed-refunded.exception';

const CABIN_ID = 'c1';
const CALLER_ID = 'u1';

class InMemoryAccessSessionRepository implements AccessSessionRepository {
  private readonly items = new Map<string, AccessSession>();

  seed(session: AccessSession): void {
    this.items.set(session.id, session);
  }

  async save(session: AccessSession): Promise<AccessSession> {
    this.items.set(session.id, session);
    return session;
  }

  async findById(id: string): Promise<AccessSession | null> {
    return this.items.get(id) ?? null;
  }

  async findActiveByCabinId(): Promise<AccessSession | null> {
    return null;
  }
}

class InMemoryTransactionRepository implements TransactionRepository {
  private readonly items = new Map<string, import('../domain/entities/transaction.entity').Transaction>();

  async save(transaction: import('../domain/entities/transaction.entity').Transaction) {
    this.items.set(transaction.id, transaction);
    return transaction;
  }

  async findById(id: string) {
    return this.items.get(id) ?? null;
  }

  async findByAccessSessionId(accessSessionId: string) {
    return [...this.items.values()].find((t) => t.accessSessionId === accessSessionId) ?? null;
  }

  get all() {
    return [...this.items.values()];
  }
}

class InMemoryIdempotencyKeyRepository implements IdempotencyKeyRepository {
  private readonly items = new Map<string, IdempotencyRecord>();

  async find(userId: string, key: string, endpoint: string): Promise<IdempotencyRecord | null> {
    return this.items.get(`${userId}:${key}:${endpoint}`) ?? null;
  }

  async save(userId: string, key: string, endpoint: string, responseStatus: number, responseBody: unknown): Promise<void> {
    this.items.set(`${userId}:${key}:${endpoint}`, { responseStatus, responseBody });
  }
}

function cabin(overrides: Partial<{ isPaid: boolean; price: Money | null; occupancyStatus: 'free' | 'occupied' | 'out_of_service' }> = {}) {
  return Cabin.restore({
    id: CABIN_ID,
    stationId: 's1',
    code: 'C-01',
    type: 'H',
    occupancyStatus: overrides.occupancyStatus ?? 'free',
    isPaid: overrides.isPaid ?? false,
    price: overrides.price ?? null,
  });
}

function freshSession() {
  return AccessSession.initiate({ id: 'as1', cabinId: CABIN_ID, userId: CALLER_ID, qrCodeScanned: CABIN_ID });
}

describe('AuthorizeAndCapturePaymentService', () => {
  let accessSessionRepository: InMemoryAccessSessionRepository;
  let transactionRepository: InMemoryTransactionRepository;
  let paymentGateway: jest.Mocked<PaymentGateway>;
  let lockControlGateway: jest.Mocked<LockControlGateway>;
  let eventBus: jest.Mocked<DomainEventBus>;
  let stationCommandService: jest.Mocked<StationCommandService>;
  let idempotencyService: IdempotencyService;
  let userQueryService: jest.Mocked<UserQueryService>;
  let service: AuthorizeAndCapturePaymentService;

  beforeEach(() => {
    accessSessionRepository = new InMemoryAccessSessionRepository();
    transactionRepository = new InMemoryTransactionRepository();
    paymentGateway = {
      authorize: jest.fn().mockResolvedValue({ authorizationId: 'auth1', providerRef: 'prov-auth-1' }),
      capture: jest.fn().mockResolvedValue({ captureId: 'cap1', providerRef: 'prov-cap-1' }),
      refund: jest.fn().mockResolvedValue({ refundId: 'ref1' }),
      tokenizePaymentMethod: jest.fn(),
    };
    lockControlGateway = {
      issueUnlockOrder: jest.fn().mockResolvedValue({ result: 'unlocked', acknowledgedAt: new Date() }),
    };
    eventBus = { publish: jest.fn(), publishAll: jest.fn(), subscribe: jest.fn() };
    stationCommandService = {
      checkCabinAvailability: jest.fn().mockResolvedValue(cabin()),
      setCabinOccupancy: jest.fn(),
    } as unknown as jest.Mocked<StationCommandService>;
    idempotencyService = new IdempotencyService(new InMemoryIdempotencyKeyRepository());
    userQueryService = { findById: jest.fn().mockResolvedValue(null) } as unknown as jest.Mocked<UserQueryService>;
    service = new AuthorizeAndCapturePaymentService(
      accessSessionRepository,
      transactionRepository,
      paymentGateway,
      lockControlGateway,
      eventBus,
      stationCommandService,
      idempotencyService,
      userQueryService,
    );
  });

  function seedSession() {
    const session = freshSession();
    accessSessionRepository.seed(session);
    return session;
  }

  it('free cabin: skips the payment gateway entirely and unlocks', async () => {
    seedSession();
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: false }));

    const result = await service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, idempotencyKey: 'k1' });

    expect(result.transaction).toBeNull();
    expect(result.session.status).toBe('unlocked');
    expect(paymentGateway.authorize).not.toHaveBeenCalled();
    expect(stationCommandService.setCabinOccupancy).toHaveBeenCalledWith(CABIN_ID, 'occupied');
    expect(eventBus.publish).not.toHaveBeenCalled();
  });

  it('paid cabin: authorizes, captures, unlocks, and publishes PaymentCaptured', async () => {
    seedSession();
    const price = Money.fromDecimalString('50.00', 'DZD');
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));

    const result = await service.execute({
      accessSessionId: 'as1',
      callerId: CALLER_ID,
      paymentMethodId: 'pm1',
      idempotencyKey: 'k1',
    });

    expect(result.transaction?.status).toBe('captured');
    expect(result.session.status).toBe('unlocked');
    expect(paymentGateway.authorize).toHaveBeenCalledWith(price, 'pm1', 'k1');
    expect(paymentGateway.capture).toHaveBeenCalledWith('auth1');
    expect(stationCommandService.setCabinOccupancy).toHaveBeenCalledWith(CABIN_ID, 'occupied');
    expect(eventBus.publish).toHaveBeenCalledWith(
      expect.objectContaining({ eventName: 'PaymentCaptured', userId: CALLER_ID, transactionId: result.transaction!.id }),
    );
  });

  describe('applyEmergencyDiscount (FR-EMG-03, ADR-0031)', () => {
    it('verified caller + applyEmergencyDiscount: true halves the charged/refunded amount and sets discountApplied: 50', async () => {
      seedSession();
      const price = Money.fromDecimalString('50.00', 'DZD');
      stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));
      userQueryService.findById.mockResolvedValue({ diabeticVerificationStatus: 'verified' } as any);

      const result = await service.execute({
        accessSessionId: 'as1',
        callerId: CALLER_ID,
        paymentMethodId: 'pm1',
        applyEmergencyDiscount: true,
        idempotencyKey: 'k1',
      });

      expect(result.transaction?.amount.toDecimalString()).toBe('25.00');
      expect(result.transaction?.discountApplied).toBe(50);
      const authorizedAmount = paymentGateway.authorize.mock.calls[0][0] as Money;
      expect(authorizedAmount.toDecimalString()).toBe('25.00');
      expect(userQueryService.findById).toHaveBeenCalledWith(CALLER_ID);
    });

    it('unverified (none) caller + applyEmergencyDiscount: true charges full price, discountApplied: null, no error thrown', async () => {
      seedSession();
      const price = Money.fromDecimalString('50.00', 'DZD');
      stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));
      userQueryService.findById.mockResolvedValue({ diabeticVerificationStatus: 'none' } as any);

      const result = await service.execute({
        accessSessionId: 'as1',
        callerId: CALLER_ID,
        paymentMethodId: 'pm1',
        applyEmergencyDiscount: true,
        idempotencyKey: 'k1',
      });

      expect(result.transaction?.amount.toDecimalString()).toBe('50.00');
      expect(result.transaction?.discountApplied).toBeNull();
      expect(paymentGateway.authorize).toHaveBeenCalledWith(price, 'pm1', 'k1');
    });

    it('missing user + applyEmergencyDiscount: true charges full price, discountApplied: null, no error thrown', async () => {
      seedSession();
      const price = Money.fromDecimalString('50.00', 'DZD');
      stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));
      userQueryService.findById.mockResolvedValue(null);

      const result = await service.execute({
        accessSessionId: 'as1',
        callerId: CALLER_ID,
        paymentMethodId: 'pm1',
        applyEmergencyDiscount: true,
        idempotencyKey: 'k1',
      });

      expect(result.transaction?.amount.toDecimalString()).toBe('50.00');
      expect(result.transaction?.discountApplied).toBeNull();
    });

    it('flag omitted: behaves exactly as before, no discount, userQueryService not consulted', async () => {
      seedSession();
      const price = Money.fromDecimalString('50.00', 'DZD');
      stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));

      const result = await service.execute({
        accessSessionId: 'as1',
        callerId: CALLER_ID,
        paymentMethodId: 'pm1',
        idempotencyKey: 'k1',
      });

      expect(result.transaction?.amount.toDecimalString()).toBe('50.00');
      expect(result.transaction?.discountApplied).toBeNull();
      expect(userQueryService.findById).not.toHaveBeenCalled();
    });

    it('flag explicitly false: behaves exactly as before, no discount', async () => {
      seedSession();
      const price = Money.fromDecimalString('50.00', 'DZD');
      stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));

      const result = await service.execute({
        accessSessionId: 'as1',
        callerId: CALLER_ID,
        paymentMethodId: 'pm1',
        applyEmergencyDiscount: false,
        idempotencyKey: 'k1',
      });

      expect(result.transaction?.amount.toDecimalString()).toBe('50.00');
      expect(result.transaction?.discountApplied).toBeNull();
    });
  });

  it('throws AccessSessionNotFoundException when the session does not exist', async () => {
    await expect(
      service.execute({ accessSessionId: 'missing', callerId: CALLER_ID, idempotencyKey: 'k1' }),
    ).rejects.toThrow(AccessSessionNotFoundException);
  });

  it('throws AccessSessionForbiddenException when the caller is not the session owner', async () => {
    const session = AccessSession.initiate({ id: 'as1', cabinId: CABIN_ID, userId: 'someone-else', qrCodeScanned: CABIN_ID });
    accessSessionRepository.seed(session);

    await expect(
      service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, idempotencyKey: 'k1' }),
    ).rejects.toThrow(AccessSessionForbiddenException);
  });

  it('throws CabinUnavailableException (409) when the cabin is no longer available', async () => {
    seedSession();
    stationCommandService.checkCabinAvailability.mockRejectedValue(new StationCabinUnavailableException(CABIN_ID, 'occupied'));

    await expect(
      service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, idempotencyKey: 'k1' }),
    ).rejects.toThrow(CabinUnavailableException);
  });

  it('402: marks the transaction failed when authorize is declined', async () => {
    seedSession();
    const price = Money.fromDecimalString('50.00', 'DZD');
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));
    paymentGateway.authorize.mockRejectedValue(new Error('declined'));

    await expect(
      service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, paymentMethodId: 'pm1', idempotencyKey: 'k1' }),
    ).rejects.toThrow(PaymentDeclinedException);

    expect(transactionRepository.all).toHaveLength(1);
    expect(transactionRepository.all[0].status).toBe('failed');
    expect(paymentGateway.capture).not.toHaveBeenCalled();
  });

  it('402: marks the transaction failed when capture is declined', async () => {
    seedSession();
    const price = Money.fromDecimalString('50.00', 'DZD');
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));
    paymentGateway.capture.mockRejectedValue(new Error('declined'));

    await expect(
      service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, paymentMethodId: 'pm1', idempotencyKey: 'k1' }),
    ).rejects.toThrow(PaymentDeclinedException);

    expect(transactionRepository.all[0].status).toBe('failed');
  });

  it('502: refunds and marks the transaction refunded (not captured) when unlock fails after capture — Risk R-12', async () => {
    seedSession();
    const price = Money.fromDecimalString('50.00', 'DZD');
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));
    lockControlGateway.issueUnlockOrder.mockResolvedValue({ result: 'failed', acknowledgedAt: null });

    await expect(
      service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, paymentMethodId: 'pm1', idempotencyKey: 'k1' }),
    ).rejects.toThrow(UnlockFailedRefundedException);

    expect(paymentGateway.refund).toHaveBeenCalledWith('cap1', price);
    expect(transactionRepository.all[0].status).toBe('refunded');
    expect(transactionRepository.all[0].status).not.toBe('captured');
    expect(stationCommandService.setCabinOccupancy).not.toHaveBeenCalledWith(CABIN_ID, 'occupied');
    expect(eventBus.publish).not.toHaveBeenCalled();
  });

  it('502: free cabin unlock failure — no transaction to refund, still throws UnlockFailedRefundedException', async () => {
    seedSession();
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: false }));
    lockControlGateway.issueUnlockOrder.mockResolvedValue({ result: 'failed', acknowledgedAt: null });

    await expect(
      service.execute({ accessSessionId: 'as1', callerId: CALLER_ID, idempotencyKey: 'k1' }),
    ).rejects.toThrow(UnlockFailedRefundedException);

    expect(paymentGateway.refund).not.toHaveBeenCalled();
    expect(transactionRepository.all).toHaveLength(0);
  });

  it('idempotency replay: a second call with the same key does not call the payment gateway again', async () => {
    seedSession();
    const price = Money.fromDecimalString('50.00', 'DZD');
    stationCommandService.checkCabinAvailability.mockResolvedValue(cabin({ isPaid: true, price }));

    const first = await service.execute({
      accessSessionId: 'as1',
      callerId: CALLER_ID,
      paymentMethodId: 'pm1',
      idempotencyKey: 'k1',
    });
    const second = await service.execute({
      accessSessionId: 'as1',
      callerId: CALLER_ID,
      paymentMethodId: 'pm1',
      idempotencyKey: 'k1',
    });

    expect(second.transaction?.id).toBe(first.transaction?.id);
    expect(paymentGateway.authorize).toHaveBeenCalledTimes(1);
    expect(paymentGateway.capture).toHaveBeenCalledTimes(1);
  });
});
