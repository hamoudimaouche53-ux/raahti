import { INestApplication, UnauthorizedException, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { EmergencyQueryService } from '../src/modules/emergency/application/emergency-query.service';
import { EmergencyController } from '../src/modules/emergency/interface/controllers/emergency.controller';
import { UserQueryService } from '../src/modules/identity/application/user-query.service';
import { User } from '../src/modules/identity/domain/entities/user.entity';
import { USER_REPOSITORY, UserRepository } from '../src/modules/identity/domain/ports/user.repository';
import { JWT_VERIFIER, JwtVerifier } from '../src/modules/identity/infrastructure/auth/jwt-verifier.port';
import { JwtAuthGuard } from '../src/modules/identity/interface/guards/jwt-auth.guard';
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
import { GeoPosition } from '../src/shared-kernel';

const VERIFIED_USER_ID = 'u-verified';
const UNVERIFIED_USER_ID = 'u-unverified';

class FakeUserRepository implements UserRepository {
  private readonly items = new Map<string, User>([
    [VERIFIED_USER_ID, User.create({ id: VERIFIED_USER_ID, email: 'verified@example.com', diabeticVerificationStatus: 'verified' })],
    [UNVERIFIED_USER_ID, User.create({ id: UNVERIFIED_USER_ID, email: 'unverified@example.com', diabeticVerificationStatus: 'none' })],
  ]);

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

/** Configurable in-memory StationRepository — tests flip `.hasFacility` directly on the shared instance. */
class ConfigurableStationRepository implements StationRepository {
  hasFacility = true;

  async findById(): Promise<Station | null> {
    return null;
  }

  async findAll(): Promise<Station[]> {
    return [];
  }

  async searchNearby(): Promise<StationSearchPage> {
    return { data: [], nextCursor: null };
  }

  async findCabinById(): Promise<Cabin | null> {
    return null;
  }

  async updateCabinOccupancy(): Promise<void> {}

  async findNearestAccessible(): Promise<NearestAccessibleStationResult | null> {
    if (!this.hasFacility) {
      return null;
    }
    return {
      station: {
        id: 's1',
        code: 'ST-001',
        configuration: 'fixe',
        status: 'active',
        position: GeoPosition.of(36.751, 3.051),
        distanceMeters: 500,
        hasSlatokiTent: false,
        cabinPricingMix: 'all_paid',
        averageRating: null,
        reviewCount: 0,
      },
      nearestCabinId: 'c1',
    };
  }
}

class FakeStationReviewRepository implements StationReviewRepository {
  async save() {}
  async aggregateByStationId(): Promise<StationRatingAggregate> {
    return { averageRating: null, reviewCount: 0 };
  }
}

class FakeJwtVerifier implements JwtVerifier {
  async verify(token: string) {
    const claims: Record<string, unknown> = {
      'valid-verified': { sub: VERIFIED_USER_ID, role: 'usager', exp: 0, iat: 0 },
      'valid-unverified': { sub: UNVERIFIED_USER_ID, role: 'usager', exp: 0, iat: 0 },
    };
    const found = claims[token];
    if (!found) {
      throw new UnauthorizedException('invalid token');
    }
    return found as any;
  }
}

describe('GET /emergency/nearest-facility (e2e)', () => {
  let app: INestApplication;
  let stationRepository: ConfigurableStationRepository;

  beforeAll(async () => {
    stationRepository = new ConfigurableStationRepository();

    const moduleRef = await Test.createTestingModule({
      controllers: [EmergencyController],
      providers: [
        Reflector,
        EmergencyQueryService,
        StationQueryService,
        UserQueryService,
        { provide: STATION_REPOSITORY, useValue: stationRepository },
        { provide: STATION_REVIEW_REPOSITORY, useClass: FakeStationReviewRepository },
        { provide: USER_REPOSITORY, useClass: FakeUserRepository },
        { provide: JWT_VERIFIER, useClass: FakeJwtVerifier },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
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

  beforeEach(() => {
    stationRepository.hasFacility = true;
  });

  it('200s with discountEligible: true for a verified user', async () => {
    const res = await request(app.getHttpServer())
      .get('/emergency/nearest-facility')
      .set('Authorization', 'Bearer valid-verified')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(200);

    expect(res.body.discountEligible).toBe(true);
    expect(res.body.place.id).toBe('s1');
    expect(res.body.nearestCabinId).toBe('c1');
  });

  it('200s with discountEligible: false for an unverified (none) user', async () => {
    const res = await request(app.getHttpServer())
      .get('/emergency/nearest-facility')
      .set('Authorization', 'Bearer valid-unverified')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(200);

    expect(res.body.discountEligible).toBe(false);
  });

  it('404s when no accessible station is within the emergency search radius', async () => {
    stationRepository.hasFacility = false;

    const res = await request(app.getHttpServer())
      .get('/emergency/nearest-facility')
      .set('Authorization', 'Bearer valid-verified')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(404);

    expect(res.body.code).toBe('NO_ACCESSIBLE_FACILITY_FOUND');
  });

  it('400s when lat/lng are missing', async () => {
    await request(app.getHttpServer())
      .get('/emergency/nearest-facility')
      .set('Authorization', 'Bearer valid-verified')
      .expect(400);
  });

  it('401s when no Authorization header is sent', async () => {
    await request(app.getHttpServer())
      .get('/emergency/nearest-facility')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(401);
  });
});
