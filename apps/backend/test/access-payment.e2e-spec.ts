import { randomUUID } from 'crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AccessSessionQueryService } from '../src/modules/access-payment/application/access-session-query.service';
import { AuthorizeAndCapturePaymentService } from '../src/modules/access-payment/application/authorize-and-capture-payment.service';
import { CompleteAccessSessionService } from '../src/modules/access-payment/application/complete-access-session.service';
import { IdempotencyService } from '../src/modules/access-payment/application/idempotency.service';
import { InitiateAccessSessionService } from '../src/modules/access-payment/application/initiate-access-session.service';
import { AccessSession } from '../src/modules/access-payment/domain/entities/access-session.entity';
import { Transaction } from '../src/modules/access-payment/domain/entities/transaction.entity';
import {
  ACCESS_SESSION_REPOSITORY,
  AccessSessionRepository,
  VisitHistoryPage,
} from '../src/modules/access-payment/domain/ports/access-session.repository';
import { IDEMPOTENCY_KEY_REPOSITORY, IdempotencyKeyRepository, IdempotencyRecord } from '../src/modules/access-payment/domain/ports/idempotency-key.repository';
import { LOCK_CONTROL_GATEWAY, LockControlGateway, UnlockOrderResult } from '../src/modules/access-payment/domain/ports/lock-control-gateway';
import {
  PAYMENT_GATEWAY,
  PaymentAuthorizationResult,
  PaymentCaptureResult,
  PaymentGateway,
  PaymentRefundResult,
  TokenizedPaymentMethod,
} from '../src/modules/access-payment/domain/ports/payment-gateway';
import { TRANSACTION_REPOSITORY, TransactionRepository } from '../src/modules/access-payment/domain/ports/transaction.repository';
import { AccessSessionsController } from '../src/modules/access-payment/interface/controllers/access-sessions.controller';
import { UserQueryService } from '../src/modules/identity/application/user-query.service';
import { User } from '../src/modules/identity/domain/entities/user.entity';
import { USER_REPOSITORY, UserRepository } from '../src/modules/identity/domain/ports/user.repository';
import { StationCommandService } from '../src/modules/station-network/application/station-command.service';
import { Cabin } from '../src/modules/station-network/domain/entities/cabin.entity';
import { Station } from '../src/modules/station-network/domain/entities/station.entity';
import {
  STATION_REPOSITORY,
  StationRepository,
  StationSearchPage,
} from '../src/modules/station-network/domain/ports/station.repository';
import { OccupancyStatus } from '../src/modules/station-network/domain/value-objects/occupancy-status.vo';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { RateLimitGuard } from '../src/platform/http/rate-limit.guard';
import { DOMAIN_EVENT_BUS, DomainEvent, DomainEventBus, Money } from '../src/shared-kernel';

class NoopEventBus implements DomainEventBus {
  async publish(_event: DomainEvent): Promise<void> {}
  async publishAll(_events: readonly DomainEvent[]): Promise<void> {}
  subscribe<T extends DomainEvent>(_eventName: string, _handler: (event: T) => Promise<void>): void {}
}

const CALLER_ID = 'caller-1';
const OTHER_USER_ID = 'other-user';
const CABIN_FREE = '550e8400-e29b-41d4-a716-446655440001';
const CABIN_PAID = '550e8400-e29b-41d4-a716-446655440002';
const CABIN_OCCUPIED = '550e8400-e29b-41d4-a716-446655440003';
/** Dedicated to the "complete" tests so it's unaffected by the payments describe block leaving CABIN_FREE occupied. */
const CABIN_FREE_2 = '550e8400-e29b-41d4-a716-446655440004';
// Each payments-flow test that actually reaches a successful/failed unlock mutates its
// cabin's occupancy — a shared CABIN_PAID across those tests would make later tests in
// the block see it as no-longer-free (409 on initiate) depending on execution order, so
// each gets its own paid cabin instead.
const CABIN_PAID_SUCCESS = '550e8400-e29b-41d4-a716-446655440005';
const CABIN_PAID_DECLINE = '550e8400-e29b-41d4-a716-446655440006';
const CABIN_PAID_UNLOCK_FAIL = '550e8400-e29b-41d4-a716-446655440007';
const UNKNOWN_CABIN = '550e8400-e29b-41d4-a716-446655440099';
const UNKNOWN_SESSION = '550e8400-e29b-41d4-a716-446655440098';

class FakeStationRepository implements StationRepository {
  private readonly occupancy = new Map<string, OccupancyStatus>([
    [CABIN_FREE, 'free'],
    [CABIN_PAID, 'free'],
    [CABIN_OCCUPIED, 'occupied'],
    [CABIN_FREE_2, 'free'],
    [CABIN_PAID_SUCCESS, 'free'],
    [CABIN_PAID_DECLINE, 'free'],
    [CABIN_PAID_UNLOCK_FAIL, 'free'],
  ]);

  private readonly paidCabins = new Set([CABIN_PAID, CABIN_PAID_SUCCESS, CABIN_PAID_DECLINE, CABIN_PAID_UNLOCK_FAIL]);

  async findById(): Promise<Station | null> {
    return null;
  }

  async findAll(): Promise<Station[]> {
    return [];
  }

  async searchNearby(): Promise<StationSearchPage> {
    return { data: [], nextCursor: null };
  }

  async findCabinById(cabinId: string): Promise<Cabin | null> {
    const status = this.occupancy.get(cabinId);
    if (!status) return null;
    if (this.paidCabins.has(cabinId)) {
      return Cabin.restore({
        id: cabinId,
        stationId: 's1',
        code: 'C-PAID',
        type: 'H',
        occupancyStatus: status,
        isPaid: true,
        price: Money.fromDecimalString('50.00', 'DZD'),
      });
    }
    return Cabin.restore({
      id: cabinId,
      stationId: 's1',
      code: 'C-FREE',
      type: 'H',
      occupancyStatus: status,
      isPaid: false,
      price: null,
    });
  }

  async updateCabinOccupancy(cabinId: string, status: OccupancyStatus): Promise<void> {
    this.occupancy.set(cabinId, status);
  }

  async findNearestAccessible() {
    return null;
  }

  async findStationCodesByCabinIds(): Promise<Map<string, string>> {
    return new Map();
  }

  getOccupancy(cabinId: string): OccupancyStatus | undefined {
    return this.occupancy.get(cabinId);
  }
}

class FakeUserRepository implements UserRepository {
  private readonly items = new Map<string, User>();

  seed(user: User): void {
    this.items.set(user.id, user);
  }

  async findById(id: string): Promise<User | null> {
    return this.items.get(id) ?? null;
  }

  async save(): Promise<void> {}

  async findByEmail(): Promise<User | null> {
    return null;
  }

  async findByPhone(): Promise<User | null> {
    return null;
  }

  async findOrCreate(candidate: User): Promise<User> {
    return candidate;
  }
}

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

  async listVisitHistoryForUser(): Promise<VisitHistoryPage> {
    return { data: [], nextCursor: null };
  }

  get size(): number {
    return this.items.size;
  }
}

class InMemoryTransactionRepository implements TransactionRepository {
  private readonly items = new Map<string, Transaction>();

  async save(transaction: Transaction): Promise<Transaction> {
    this.items.set(transaction.id, transaction);
    return transaction;
  }

  async findById(id: string): Promise<Transaction | null> {
    return this.items.get(id) ?? null;
  }

  async findByAccessSessionId(accessSessionId: string): Promise<Transaction | null> {
    return [...this.items.values()].find((t) => t.accessSessionId === accessSessionId) ?? null;
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

/** Configurable in-memory PaymentGateway — tests flip `.alwaysDecline` directly on the shared instance. */
class ConfigurablePaymentGateway implements PaymentGateway {
  alwaysDecline = false;
  authorizeCallCount = 0;

  async authorize(_amount: Money, _paymentMethodRef: string, idempotencyKey: string): Promise<PaymentAuthorizationResult> {
    this.authorizeCallCount += 1;
    if (this.alwaysDecline) {
      throw new Error('declined');
    }
    return { authorizationId: `auth-${idempotencyKey}`, providerRef: 'prov-auth' };
  }

  async capture(authorizationId: string): Promise<PaymentCaptureResult> {
    if (this.alwaysDecline) {
      throw new Error('declined');
    }
    return { captureId: `cap-${authorizationId}`, providerRef: 'prov-cap' };
  }

  async refund(captureId: string): Promise<PaymentRefundResult> {
    return { refundId: `ref-${captureId}` };
  }

  async tokenizePaymentMethod(): Promise<TokenizedPaymentMethod> {
    return { providerRef: 'tok' };
  }
}

/** Configurable in-memory LockControlGateway — tests flip `.outcome` directly on the shared instance. */
class ConfigurableLockControlGateway implements LockControlGateway {
  outcome: 'unlocked' | 'failed' = 'unlocked';

  async issueUnlockOrder(): Promise<UnlockOrderResult> {
    return { result: this.outcome, acknowledgedAt: this.outcome === 'unlocked' ? new Date() : null };
  }
}

function authHeader() {
  return { Authorization: 'Bearer test' };
}

describe('Access & Payment endpoints (e2e)', () => {
  let app: INestApplication;
  let stationRepository: FakeStationRepository;
  let accessSessionRepository: InMemoryAccessSessionRepository;
  let paymentGateway: ConfigurablePaymentGateway;
  let lockControlGateway: ConfigurableLockControlGateway;

  beforeAll(async () => {
    stationRepository = new FakeStationRepository();
    accessSessionRepository = new InMemoryAccessSessionRepository();
    const transactionRepository = new InMemoryTransactionRepository();
    paymentGateway = new ConfigurablePaymentGateway();
    lockControlGateway = new ConfigurableLockControlGateway();

    const moduleRef = await Test.createTestingModule({
      controllers: [AccessSessionsController],
      providers: [
        InitiateAccessSessionService,
        AuthorizeAndCapturePaymentService,
        AccessSessionQueryService,
        CompleteAccessSessionService,
        IdempotencyService,
        StationCommandService,
        UserQueryService,
        { provide: STATION_REPOSITORY, useValue: stationRepository },
        { provide: ACCESS_SESSION_REPOSITORY, useValue: accessSessionRepository },
        { provide: TRANSACTION_REPOSITORY, useValue: transactionRepository },
        { provide: IDEMPOTENCY_KEY_REPOSITORY, useClass: InMemoryIdempotencyKeyRepository },
        { provide: PAYMENT_GATEWAY, useValue: paymentGateway },
        { provide: LOCK_CONTROL_GATEWAY, useValue: lockControlGateway },
        { provide: DOMAIN_EVENT_BUS, useClass: NoopEventBus },
        // Emergency-discount scenarios get their own dedicated describe block below
        // (with seeded verified/unverified users) — this block never sends
        // applyEmergencyDiscount: true, so an empty FakeUserRepository is enough.
        { provide: USER_REPOSITORY, useClass: FakeUserRepository },
        // This describe block exercises functional behavior, not rate limiting (that has
        // its own dedicated describe block below with the real RateLimitGuard) — stubbed
        // permissive so the many setup calls each functional test makes don't trip the
        // real 10-req/min bucket shared by the two @RateLimit-decorated routes.
        { provide: RateLimitGuard, useValue: { canActivate: () => true } },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.use((req: { user?: unknown }, _res: unknown, next: () => void) => {
      req.user = { sub: CALLER_ID, role: 'usager', aal: 'aal1', exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    paymentGateway.alwaysDecline = false;
    lockControlGateway.outcome = 'unlocked';
  });

  /**
   * Seeds an `initiated` session directly into the repository rather than
   * going through `POST /access-sessions` — used by the payments/complete
   * describe blocks below so their setup doesn't also consume tokens from
   * that route's rate-limit bucket (shared across the whole describe block
   * by caller+route), keeping those tests independent of exactly how many
   * other tests already called that route.
   */
  function seedInitiatedSession(cabinId: string, userId: string = CALLER_ID): AccessSession {
    const session = AccessSession.initiate({ id: randomUUID(), cabinId, userId, qrCodeScanned: cabinId });
    accessSessionRepository.seed(session);
    return session;
  }

  describe('POST /access-sessions', () => {
    it('201s for a free cabin', async () => {
      const res = await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', 'init-free-1')
        .send({ qrCodeScanned: CABIN_FREE })
        .expect(201);

      expect(res.body.status).toBe('initiated');
      expect(res.body.cabinId).toBe(CABIN_FREE);
    });

    it('201s for a paid cabin, status initiated', async () => {
      const res = await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', 'init-paid-1')
        .send({ qrCodeScanned: CABIN_PAID })
        .expect(201);

      expect(res.body.status).toBe('initiated');
      expect(res.body.cabinId).toBe(CABIN_PAID);
    });

    it('409s for an occupied cabin', async () => {
      await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', 'init-occupied-1')
        .send({ qrCodeScanned: CABIN_OCCUPIED })
        .expect(409);
    });

    it('409s for an unknown cabin', async () => {
      await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', 'init-unknown-1')
        .send({ qrCodeScanned: UNKNOWN_CABIN })
        .expect(409);
    });

    it('replays the identical response for a duplicate Idempotency-Key, without creating a second session', async () => {
      const key = 'init-replay-1';
      const first = await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', key)
        .send({ qrCodeScanned: CABIN_FREE })
        .expect(201);

      const countAfterFirst = accessSessionRepository.size;

      const second = await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', key)
        .send({ qrCodeScanned: CABIN_FREE })
        .expect(201);

      expect(second.body).toEqual(first.body);
      expect(accessSessionRepository.size).toBe(countAfterFirst);
    });

    it('400s when the Idempotency-Key header is missing', async () => {
      await request(app.getHttpServer()).post('/access-sessions').set(authHeader()).send({ qrCodeScanned: CABIN_FREE }).expect(400);
    });
  });

  describe('GET /access-sessions/{sessionId}', () => {
    it('200s for an existing session', async () => {
      const res = await request(app.getHttpServer())
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', 'get-setup-1')
        .send({ qrCodeScanned: CABIN_FREE })
        .expect(201);

      await request(app.getHttpServer()).get(`/access-sessions/${res.body.id}`).set(authHeader()).expect(200);
    });

    it('404s for an unknown session', async () => {
      await request(app.getHttpServer()).get(`/access-sessions/${UNKNOWN_SESSION}`).set(authHeader()).expect(404);
    });
  });

  describe('POST /access-sessions/{sessionId}/payments', () => {
    it('200s with a captured Transaction and unlocked AccessSession (paid cabin, gateway succeeds)', async () => {
      const session = seedInitiatedSession(CABIN_PAID_SUCCESS);

      const res = await request(app.getHttpServer())
        .post(`/access-sessions/${session.id}/payments`)
        .set(authHeader())
        .set('Idempotency-Key', `pay-ok-${Math.random()}`)
        .send({ paymentMethodId: '550e8400-e29b-41d4-a716-446655440010' })
        .expect(200);

      expect(res.body.status).toBe('captured');
      expect(res.body.accessSession.status).toBe('unlocked');
    });

    it('402s when the payment gateway declines', async () => {
      const session = seedInitiatedSession(CABIN_PAID_DECLINE);

      paymentGateway.alwaysDecline = true;

      await request(app.getHttpServer())
        .post(`/access-sessions/${session.id}/payments`)
        .set(authHeader())
        .set('Idempotency-Key', `pay-decline-${Math.random()}`)
        .send({ paymentMethodId: '550e8400-e29b-41d4-a716-446655440010' })
        .expect(402);
    });

    it('502s UNLOCK_FAILED_REFUNDED and ends the Transaction refunded when the lock gateway fails', async () => {
      const session = seedInitiatedSession(CABIN_PAID_UNLOCK_FAIL);

      lockControlGateway.outcome = 'failed';

      const res = await request(app.getHttpServer())
        .post(`/access-sessions/${session.id}/payments`)
        .set(authHeader())
        .set('Idempotency-Key', `pay-unlockfail-${Math.random()}`)
        .send({ paymentMethodId: '550e8400-e29b-41d4-a716-446655440010' })
        .expect(502);

      expect(res.body.code).toBe('UNLOCK_FAILED_REFUNDED');
    });

    it('free cabin: skips the payment gateway entirely and still unlocks', async () => {
      const session = seedInitiatedSession(CABIN_FREE);
      const callsBefore = paymentGateway.authorizeCallCount;

      const res = await request(app.getHttpServer())
        .post(`/access-sessions/${session.id}/payments`)
        .set(authHeader())
        .set('Idempotency-Key', `pay-free-${Math.random()}`)
        .send({})
        .expect(200);

      expect(res.body.accessSession.status).toBe('unlocked');
      expect(res.body.status).toBeUndefined();
      expect(paymentGateway.authorizeCallCount).toBe(callsBefore);
    });
  });

  describe('POST /access-sessions/{sessionId}/complete', () => {
    it('200s and flips the cabin occupancy to free', async () => {
      const initiateId = seedInitiatedSession(CABIN_FREE_2).id;

      await request(app.getHttpServer())
        .post(`/access-sessions/${initiateId}/payments`)
        .set(authHeader())
        .set('Idempotency-Key', `complete-pay-${Math.random()}`)
        .send({})
        .expect(200);

      expect(stationRepository.getOccupancy(CABIN_FREE_2)).toBe('occupied');

      const res = await request(app.getHttpServer())
        .post(`/access-sessions/${initiateId}/complete`)
        .set(authHeader())
        .expect(200);

      expect(res.body.status).toBe('completed');
      expect(stationRepository.getOccupancy(CABIN_FREE_2)).toBe('free');
    });

    it('403s when the caller is not the session owner', async () => {
      const foreignSession = AccessSession.initiate({
        id: '550e8400-e29b-41d4-a716-446655440077',
        cabinId: CABIN_FREE,
        userId: OTHER_USER_ID,
        qrCodeScanned: CABIN_FREE,
      });
      accessSessionRepository.seed(foreignSession);

      await request(app.getHttpServer())
        .post(`/access-sessions/${foreignSession.id}/complete`)
        .set(authHeader())
        .expect(403);
    });
  });
});

/**
 * FR-EMG-03 / ADR-0031 — server-side re-verification of applyEmergencyDiscount.
 * Its own describe block (own app instance, own FakeStationRepository/FakeUserRepository)
 * so the caller identity can vary per test via a `x-caller-id` header read by the
 * auth-stub middleware, independent of the fixed CALLER_ID used everywhere above.
 */
describe('POST /access-sessions/{sessionId}/payments — applyEmergencyDiscount (e2e)', () => {
  let app: INestApplication;
  let accessSessionRepository: InMemoryAccessSessionRepository;
  let stationRepository: FakeStationRepository;

  const VERIFIED_CALLER_ID = 'discount-verified-caller';
  const UNVERIFIED_CALLER_ID = 'discount-unverified-caller';

  function authHeaderFor(callerId: string) {
    return { Authorization: 'Bearer test', 'x-caller-id': callerId };
  }

  beforeAll(async () => {
    stationRepository = new FakeStationRepository();
    accessSessionRepository = new InMemoryAccessSessionRepository();
    const transactionRepository = new InMemoryTransactionRepository();
    const paymentGateway = new ConfigurablePaymentGateway();
    const lockControlGateway = new ConfigurableLockControlGateway();
    const userRepository = new FakeUserRepository();
    userRepository.seed(User.create({ id: VERIFIED_CALLER_ID, email: 'verified@example.com', diabeticVerificationStatus: 'verified' }));
    userRepository.seed(User.create({ id: UNVERIFIED_CALLER_ID, email: 'unverified@example.com', diabeticVerificationStatus: 'none' }));

    const moduleRef = await Test.createTestingModule({
      controllers: [AccessSessionsController],
      providers: [
        InitiateAccessSessionService,
        AuthorizeAndCapturePaymentService,
        AccessSessionQueryService,
        CompleteAccessSessionService,
        IdempotencyService,
        StationCommandService,
        UserQueryService,
        { provide: STATION_REPOSITORY, useValue: stationRepository },
        { provide: ACCESS_SESSION_REPOSITORY, useValue: accessSessionRepository },
        { provide: TRANSACTION_REPOSITORY, useValue: transactionRepository },
        { provide: IDEMPOTENCY_KEY_REPOSITORY, useClass: InMemoryIdempotencyKeyRepository },
        { provide: PAYMENT_GATEWAY, useValue: paymentGateway },
        { provide: LOCK_CONTROL_GATEWAY, useValue: lockControlGateway },
        { provide: DOMAIN_EVENT_BUS, useClass: NoopEventBus },
        { provide: USER_REPOSITORY, useValue: userRepository },
        { provide: RateLimitGuard, useValue: { canActivate: () => true } },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.use((req: { user?: unknown; headers: Record<string, string | undefined> }, _res: unknown, next: () => void) => {
      const callerId = req.headers['x-caller-id'] ?? VERIFIED_CALLER_ID;
      req.user = { sub: callerId, role: 'usager', aal: 'aal1', exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  function seedInitiatedSession(cabinId: string, userId: string): AccessSession {
    const session = AccessSession.initiate({ id: randomUUID(), cabinId, userId, qrCodeScanned: cabinId });
    accessSessionRepository.seed(session);
    return session;
  }

  it('verified caller: halves the captured amount and sets transaction.discountApplied to 50', async () => {
    const session = seedInitiatedSession(CABIN_PAID_SUCCESS, VERIFIED_CALLER_ID);

    const res = await request(app.getHttpServer())
      .post(`/access-sessions/${session.id}/payments`)
      .set(authHeaderFor(VERIFIED_CALLER_ID))
      .set('Idempotency-Key', `discount-verified-${Math.random()}`)
      .send({ paymentMethodId: '550e8400-e29b-41d4-a716-446655440010', applyEmergencyDiscount: true })
      .expect(200);

    expect(res.body.status).toBe('captured');
    expect(res.body.amount).toEqual({ amount: '25.00', currency: 'DZD' });
    expect(res.body.discountApplied).toBe('50');
  });

  it('unverified caller: charges full price, no discountApplied, no error', async () => {
    const session = seedInitiatedSession(CABIN_PAID_DECLINE, UNVERIFIED_CALLER_ID);

    const res = await request(app.getHttpServer())
      .post(`/access-sessions/${session.id}/payments`)
      .set(authHeaderFor(UNVERIFIED_CALLER_ID))
      .set('Idempotency-Key', `discount-unverified-${Math.random()}`)
      .send({ paymentMethodId: '550e8400-e29b-41d4-a716-446655440010', applyEmergencyDiscount: true })
      .expect(200);

    expect(res.body.status).toBe('captured');
    expect(res.body.amount).toEqual({ amount: '50.00', currency: 'DZD' });
    expect(res.body.discountApplied).toBeNull();
  });
});

describe('Access & Payment rate limiting (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const stationRepository = new FakeStationRepository();

    const moduleRef = await Test.createTestingModule({
      controllers: [AccessSessionsController],
      providers: [
        InitiateAccessSessionService,
        AuthorizeAndCapturePaymentService,
        AccessSessionQueryService,
        CompleteAccessSessionService,
        IdempotencyService,
        StationCommandService,
        UserQueryService,
        RateLimitGuard,
        { provide: STATION_REPOSITORY, useValue: stationRepository },
        { provide: ACCESS_SESSION_REPOSITORY, useClass: InMemoryAccessSessionRepository },
        { provide: TRANSACTION_REPOSITORY, useClass: InMemoryTransactionRepository },
        { provide: IDEMPOTENCY_KEY_REPOSITORY, useClass: InMemoryIdempotencyKeyRepository },
        { provide: PAYMENT_GATEWAY, useClass: ConfigurablePaymentGateway },
        { provide: LOCK_CONTROL_GATEWAY, useClass: ConfigurableLockControlGateway },
        { provide: DOMAIN_EVENT_BUS, useClass: NoopEventBus },
        { provide: USER_REPOSITORY, useClass: FakeUserRepository },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.use((req: { user?: unknown }, _res: unknown, next: () => void) => {
      req.user = { sub: 'rate-limit-caller', role: 'usager', aal: 'aal1', exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns 429 once the same caller exceeds the configured limit within the window', async () => {
    const server = app.getHttpServer();
    const LIMIT = 10;

    for (let i = 0; i < LIMIT; i++) {
      await request(server)
        .post('/access-sessions')
        .set(authHeader())
        .set('Idempotency-Key', `rate-limit-${i}`)
        .send({ qrCodeScanned: CABIN_FREE })
        .expect(201);
    }

    await request(server)
      .post('/access-sessions')
      .set(authHeader())
      .set('Idempotency-Key', `rate-limit-${LIMIT}`)
      .send({ qrCodeScanned: CABIN_FREE })
      .expect(429);
  });
});
