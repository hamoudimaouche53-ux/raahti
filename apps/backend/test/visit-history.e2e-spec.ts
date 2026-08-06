import { INestApplication, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { VisitHistoryQueryService } from '../src/modules/access-payment/application/visit-history-query.service';
import { AccessSession } from '../src/modules/access-payment/domain/entities/access-session.entity';
import {
  ACCESS_SESSION_REPOSITORY,
  AccessSessionRepository,
  VisitHistoryPage,
} from '../src/modules/access-payment/domain/ports/access-session.repository';
import { VisitHistoryController } from '../src/modules/access-payment/interface/controllers/visit-history.controller';
import { JWT_VERIFIER, JwtVerifier } from '../src/modules/identity/infrastructure/auth/jwt-verifier.port';
import { JwtAuthGuard } from '../src/modules/identity/interface/guards/jwt-auth.guard';
import { RequireMfaGuard } from '../src/modules/identity/interface/guards/require-mfa.guard';
import { RolesGuard } from '../src/modules/identity/interface/guards/roles.guard';
import { SiteScopeGuard } from '../src/modules/identity/interface/guards/site-scope.guard';
import { StationQueryService } from '../src/modules/station-network/application/station-query.service';
import { Cabin } from '../src/modules/station-network/domain/entities/cabin.entity';
import { Station } from '../src/modules/station-network/domain/entities/station.entity';
import {
  NearestAccessibleStationResult,
  STATION_REPOSITORY,
  StationRepository,
  StationSearchPage,
} from '../src/modules/station-network/domain/ports/station.repository';
import {
  STATION_REVIEW_REPOSITORY,
  StationRatingAggregate,
  StationReviewRepository,
} from '../src/modules/station-network/domain/ports/station-review.repository';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { Money } from '../src/shared-kernel';

interface FakeSessionRow {
  id: string;
  userId: string;
  cabinId: string;
  status: string;
  closedAt: Date | null;
  amount: Money | null;
}

/**
 * In-memory fake standing in for PrismaAccessSessionRepository — exercises
 * the real VisitHistoryController/VisitHistoryQueryService/StationQueryService
 * over HTTP without a live database (same no-DB e2e convention every other
 * suite in this file uses). Unlike prisma-access-session.repository.spec.ts
 * (which unit-tests the real `completed`-only WHERE clause), this fake
 * re-implements the same status filter + ordering itself so the
 * in-progress-session-excluded and cursor-round-trip cases can be exercised
 * end-to-end through the actual HTTP response shape.
 */
class FakeAccessSessionRepository implements AccessSessionRepository {
  private readonly rows: FakeSessionRow[] = [];

  seed(row: FakeSessionRow): void {
    this.rows.push(row);
  }

  async save(session: AccessSession): Promise<AccessSession> {
    return session;
  }

  async findById(): Promise<AccessSession | null> {
    return null;
  }

  async findActiveByCabinId(): Promise<AccessSession | null> {
    return null;
  }

  async listVisitHistoryForUser(userId: string, cursor: string | null, limit: number): Promise<VisitHistoryPage> {
    const sorted = this.rows
      .filter((row) => row.userId === userId && row.status === 'completed')
      .sort((a, b) => b.closedAt!.getTime() - a.closedAt!.getTime() || (a.id < b.id ? 1 : -1));

    const startIndex = cursor ? sorted.findIndex((row) => row.id === cursor) + 1 : 0;
    const window = sorted.slice(startIndex, startIndex + limit + 1);
    const hasMore = window.length > limit;
    const page = hasMore ? window.slice(0, limit) : window;

    return {
      data: page.map((row) => ({ id: row.id, cabinId: row.cabinId, closedAt: row.closedAt!, amount: row.amount })),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }
}

class FakeStationRepository implements StationRepository {
  private readonly codesByCabin = new Map<string, string>();

  seedStationCode(cabinId: string, code: string): void {
    this.codesByCabin.set(cabinId, code);
  }

  async findById(): Promise<Station | null> {
    return null;
  }

  async searchNearby(): Promise<StationSearchPage> {
    return { data: [], nextCursor: null };
  }

  async findAll(): Promise<Station[]> {
    return [];
  }

  async findCabinById(): Promise<Cabin | null> {
    return null;
  }

  async updateCabinOccupancy(): Promise<void> {}

  async findNearestAccessible(): Promise<NearestAccessibleStationResult | null> {
    return null;
  }

  async findStationCodesByCabinIds(cabinIds: string[]): Promise<Map<string, string>> {
    const result = new Map<string, string>();
    for (const cabinId of cabinIds) {
      const code = this.codesByCabin.get(cabinId);
      if (code) {
        result.set(cabinId, code);
      }
    }
    return result;
  }
}

class FakeStationReviewRepository implements StationReviewRepository {
  async save(): Promise<void> {}

  async aggregateByStationId(): Promise<StationRatingAggregate> {
    return { averageRating: null, reviewCount: 0 };
  }
}

/** Token format `valid-<userId>` — lets each test use its own isolated caller without a shared user store. */
class FakeJwtVerifier implements JwtVerifier {
  async verify(token: string) {
    if (!token.startsWith('valid-')) {
      throw new Error('invalid token');
    }
    const sub = token.slice('valid-'.length);
    return { sub, email: `${sub}@example.com`, role: 'usager', exp: 0, iat: 0 } as any;
  }
}

describe('GET /users/me/visit-history (e2e)', () => {
  let app: INestApplication;
  let accessSessionRepository: FakeAccessSessionRepository;
  let stationRepository: FakeStationRepository;

  beforeAll(async () => {
    accessSessionRepository = new FakeAccessSessionRepository();
    stationRepository = new FakeStationRepository();

    const moduleRef = await Test.createTestingModule({
      controllers: [VisitHistoryController],
      providers: [
        Reflector,
        VisitHistoryQueryService,
        StationQueryService,
        { provide: ACCESS_SESSION_REPOSITORY, useValue: accessSessionRepository },
        { provide: STATION_REPOSITORY, useValue: stationRepository },
        { provide: STATION_REVIEW_REPOSITORY, useClass: FakeStationReviewRepository },
        { provide: JWT_VERIFIER, useClass: FakeJwtVerifier },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_GUARD, useClass: RolesGuard },
        { provide: APP_GUARD, useClass: SiteScopeGuard },
        { provide: APP_GUARD, useClass: RequireMfaGuard },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const auth = (userId: string) => ({ Authorization: `Bearer valid-${userId}` });

  it('shows the correct amount for a completed paid visit', async () => {
    const userId = 'visit-user-paid';
    stationRepository.seedStationCode('cabin-paid', 'ST-001');
    accessSessionRepository.seed({
      id: 'visit-paid-1',
      userId,
      cabinId: 'cabin-paid',
      status: 'completed',
      closedAt: new Date('2026-08-01T10:00:00Z'),
      amount: Money.fromDecimalString('50.00', 'DZD'),
    });

    const res = await request(app.getHttpServer()).get('/users/me/visit-history').set(auth(userId)).expect(200);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0]).toEqual(
      expect.objectContaining({
        id: 'visit-paid-1',
        placeName: 'ST-001',
        amount: { amount: '50.00', currency: 'DZD' },
      }),
    );
    expect(res.body.nextCursor).toBeNull();
  });

  it('shows amount: null for a completed free visit', async () => {
    const userId = 'visit-user-free';
    stationRepository.seedStationCode('cabin-free', 'ST-002');
    accessSessionRepository.seed({
      id: 'visit-free-1',
      userId,
      cabinId: 'cabin-free',
      status: 'completed',
      closedAt: new Date('2026-08-01T09:00:00Z'),
      amount: null,
    });

    const res = await request(app.getHttpServer()).get('/users/me/visit-history').set(auth(userId)).expect(200);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].id).toBe('visit-free-1');
    expect(res.body.data[0].amount).toBeNull();
  });

  it('excludes an in-progress (unlocked) session from the list', async () => {
    const userId = 'visit-user-inprogress';
    stationRepository.seedStationCode('cabin-done', 'ST-003');
    stationRepository.seedStationCode('cabin-active', 'ST-004');
    accessSessionRepository.seed({
      id: 'visit-done-1',
      userId,
      cabinId: 'cabin-done',
      status: 'completed',
      closedAt: new Date('2026-08-01T08:00:00Z'),
      amount: null,
    });
    accessSessionRepository.seed({
      id: 'visit-active-1',
      userId,
      cabinId: 'cabin-active',
      status: 'unlocked',
      closedAt: null,
      amount: null,
    });

    const res = await request(app.getHttpServer()).get('/users/me/visit-history').set(auth(userId)).expect(200);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].id).toBe('visit-done-1');
  });

  it('paginates via cursor, round-tripping to the remaining rows on page two', async () => {
    const userId = 'visit-user-paging';
    stationRepository.seedStationCode('cabin-p', 'ST-005');
    accessSessionRepository.seed({
      id: 'visit-p-1',
      userId,
      cabinId: 'cabin-p',
      status: 'completed',
      closedAt: new Date('2026-08-03T00:00:00Z'),
      amount: null,
    });
    accessSessionRepository.seed({
      id: 'visit-p-2',
      userId,
      cabinId: 'cabin-p',
      status: 'completed',
      closedAt: new Date('2026-08-02T00:00:00Z'),
      amount: null,
    });
    accessSessionRepository.seed({
      id: 'visit-p-3',
      userId,
      cabinId: 'cabin-p',
      status: 'completed',
      closedAt: new Date('2026-08-01T00:00:00Z'),
      amount: null,
    });

    const firstPage = await request(app.getHttpServer())
      .get('/users/me/visit-history')
      .query({ limit: 2 })
      .set(auth(userId))
      .expect(200);

    expect(firstPage.body.data.map((item: { id: string }) => item.id)).toEqual(['visit-p-1', 'visit-p-2']);
    expect(firstPage.body.nextCursor).not.toBeNull();

    const secondPage = await request(app.getHttpServer())
      .get('/users/me/visit-history')
      .query({ limit: 2, cursor: firstPage.body.nextCursor })
      .set(auth(userId))
      .expect(200);

    expect(secondPage.body.data.map((item: { id: string }) => item.id)).toEqual(['visit-p-3']);
    expect(secondPage.body.nextCursor).toBeNull();
  });

  it('401s when unauthenticated', async () => {
    await request(app.getHttpServer()).get('/users/me/visit-history').expect(401);
  });
});
