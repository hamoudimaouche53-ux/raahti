import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { StationQueryService } from '../src/modules/station-network/application/station-query.service';
import { Cabin } from '../src/modules/station-network/domain/entities/cabin.entity';
import { SlatokiTent } from '../src/modules/station-network/domain/entities/slatoki-tent.entity';
import { Station } from '../src/modules/station-network/domain/entities/station.entity';
import {
  STATION_REPOSITORY,
  StationRepository,
  StationSearchPage,
} from '../src/modules/station-network/domain/ports/station.repository';
import { StationDetailController } from '../src/modules/station-network/interface/controllers/station-detail.controller';
import { ThirdPartyPlaceQueryService } from '../src/modules/third-party-places/application/third-party-place-query.service';
import { ThirdPartyPlace } from '../src/modules/third-party-places/domain/entities/third-party-place.entity';
import {
  THIRD_PARTY_PLACE_REPOSITORY,
  ThirdPartyPlaceRepository,
  ThirdPartyPlaceSearchPage,
} from '../src/modules/third-party-places/domain/ports/third-party-place.repository';
import { ThirdPartyPlaceDetailController } from '../src/modules/third-party-places/interface/controllers/third-party-place-detail.controller';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { GeoPosition, Money } from '../src/shared-kernel';
import { ReviewService as StationReviewService } from '../src/modules/station-network/application/review.service';
import { StationReview } from '../src/modules/station-network/domain/entities/review.entity';
import {
  STATION_REVIEW_REPOSITORY,
  StationRatingAggregate,
  StationReviewRepository,
} from '../src/modules/station-network/domain/ports/station-review.repository';
import { StationReviewsController } from '../src/modules/station-network/interface/controllers/station-reviews.controller';
import { ReviewService as ThirdPartyPlaceReviewService } from '../src/modules/third-party-places/application/review.service';
import { ThirdPartyPlaceReview } from '../src/modules/third-party-places/domain/entities/review.entity';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceRatingAggregate,
  ThirdPartyPlaceReviewRepository,
} from '../src/modules/third-party-places/domain/ports/third-party-place-review.repository';
import { ThirdPartyPlaceReviewsController } from '../src/modules/third-party-places/interface/controllers/third-party-place-reviews.controller';
import { RateLimitGuard } from '../src/platform/http/rate-limit.guard';

const STATION_ID = '550e8400-e29b-41d4-a716-446655440000';
const PLACE_ID = '6ba7b810-9dad-41d4-80b4-00c04fd430c8';

class FakeStationRepository implements StationRepository {
  async findById(id: string): Promise<Station | null> {
    if (id !== STATION_ID) return null;
    return Station.restore({
      id,
      code: 'ST-001',
      configuration: 'fixe',
      position: GeoPosition.of(36.75, 3.05),
      status: 'active',
      cabinCapacity: 2,
      tankCapacityLiters: 500,
      installedAt: new Date('2026-01-01'),
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
      cabins: [
        Cabin.restore({ id: 'c1', stationId: id, code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, price: null }),
        Cabin.restore({
          id: 'c2',
          stationId: id,
          code: 'C-02',
          type: 'F',
          occupancyStatus: 'occupied',
          isPaid: true,
          price: Money.fromDecimalString('50.00', 'DZD'),
        }),
      ],
      slatokiTent: SlatokiTent.restore({
        id: 't1',
        stationId: id,
        deploymentStatus: 'deployed',
        matCapacity: 4,
        hasLighting: true,
        hasPrivacyCurtain: true,
      }),
    });
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

  async findNearestAccessible() {
    return null;
  }

  async findStationCodesByCabinIds(cabinIds: string[]): Promise<Map<string, string>> {
    return new Map(cabinIds.map((id) => [id, 'ST-001']));
  }
}

class FakeThirdPartyPlaceRepository implements ThirdPartyPlaceRepository {
  async findById(id: string): Promise<ThirdPartyPlace | null> {
    if (id !== PLACE_ID) return null;
    return ThirdPartyPlace.restore({
      id,
      nameFr: 'Mosquée Al-Fath',
      nameAr: 'مسجد الفتح',
      placeType: 'mosque',
      position: GeoPosition.of(36.76, 3.06),
      isFree: true,
      price: null,
      declaredStatus: 'open',
      statusSource: 'community',
      tags: ['women_confirmed', 'wudu'],
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    });
  }

  async searchNearby(): Promise<ThirdPartyPlaceSearchPage> {
    return { data: [], nextCursor: null };
  }
}

class InMemoryStationReviewRepository implements StationReviewRepository {
  private readonly items: StationReview[] = [];

  async save(review: StationReview): Promise<void> {
    const index = this.items.findIndex((item) => item.id === review.id);
    if (index === -1) {
      this.items.push(review);
    } else {
      this.items[index] = review;
    }
  }

  async findById(id: string): Promise<StationReview | null> {
    return this.items.find((item) => item.id === id) ?? null;
  }

  async listByUserId(userId: string) {
    const data = this.items
      .filter((item) => item.userId === userId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return { data, nextCursor: null };
  }

  async delete(id: string): Promise<void> {
    const index = this.items.findIndex((item) => item.id === id);
    if (index !== -1) {
      this.items.splice(index, 1);
    }
  }

  async aggregateByStationId(stationId: string): Promise<StationRatingAggregate> {
    const forStation = this.items.filter((r) => r.stationId === stationId);
    if (forStation.length === 0) {
      return { averageRating: null, reviewCount: 0 };
    }
    const average = forStation.reduce((sum, r) => sum + r.rating, 0) / forStation.length;
    return { averageRating: average, reviewCount: forStation.length };
  }
}

class InMemoryThirdPartyPlaceReviewRepository implements ThirdPartyPlaceReviewRepository {
  private readonly items: ThirdPartyPlaceReview[] = [];

  async save(review: ThirdPartyPlaceReview): Promise<void> {
    const index = this.items.findIndex((item) => item.id === review.id);
    if (index === -1) {
      this.items.push(review);
    } else {
      this.items[index] = review;
    }
  }

  async findById(id: string): Promise<ThirdPartyPlaceReview | null> {
    return this.items.find((item) => item.id === id) ?? null;
  }

  async listByUserId(userId: string) {
    const data = this.items
      .filter((item) => item.userId === userId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return { data, nextCursor: null };
  }

  async delete(id: string): Promise<void> {
    const index = this.items.findIndex((item) => item.id === id);
    if (index !== -1) {
      this.items.splice(index, 1);
    }
  }

  async aggregateByThirdPartyPlaceId(thirdPartyPlaceId: string): Promise<ThirdPartyPlaceRatingAggregate> {
    const forPlace = this.items.filter((r) => r.thirdPartyPlaceId === thirdPartyPlaceId);
    if (forPlace.length === 0) {
      return { averageRating: null, reviewCount: 0 };
    }
    const average = forPlace.reduce((sum, r) => sum + r.rating, 0) / forPlace.length;
    return { averageRating: average, reviewCount: forPlace.length };
  }
}

describe('Facilities detail endpoints (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [
        StationDetailController,
        ThirdPartyPlaceDetailController,
        StationReviewsController,
        ThirdPartyPlaceReviewsController,
      ],
      providers: [
        StationQueryService,
        ThirdPartyPlaceQueryService,
        StationReviewService,
        ThirdPartyPlaceReviewService,
        { provide: STATION_REPOSITORY, useClass: FakeStationRepository },
        { provide: THIRD_PARTY_PLACE_REPOSITORY, useClass: FakeThirdPartyPlaceRepository },
        { provide: STATION_REVIEW_REPOSITORY, useClass: InMemoryStationReviewRepository },
        { provide: THIRD_PARTY_PLACE_REVIEW_REPOSITORY, useClass: InMemoryThirdPartyPlaceReviewRepository },
        // Real, not stubbed — this suite's request volume per endpoint stays
        // well under the general public tier's 60/min limit.
        RateLimitGuard,
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    // No JwtAuthGuard is registered in this test app (detail endpoints are
    // @Public()) — the review endpoints still need a request.user for
    // @CurrentUser(), so a trivial middleware stands in for it here.
    app.use((req: { user?: unknown }, _res: unknown, next: () => void) => {
      req.user = { sub: 'test-user-1', exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns a station detail with no authentication required', async () => {
    const res = await request(app.getHttpServer()).get(`/stations/${STATION_ID}`).expect(200);

    expect(res.body).toEqual(
      expect.objectContaining({
        id: STATION_ID,
        placeKind: 'station',
        pinColor: 'magenta', // has a Slatoki tent
        cabins: expect.arrayContaining([expect.objectContaining({ code: 'C-01' })]),
        slatokiTent: expect.objectContaining({ deploymentStatus: 'deployed' }),
      }),
    );
    expect(res.body.name).toEqual({ fr: 'ST-001', ar: 'ST-001', en: 'ST-001' });
  });

  it('returns 404 for an unknown station id', async () => {
    await request(app.getHttpServer()).get('/stations/6ba7b810-9dad-41d4-80b4-00c04fd430c9').expect(404);
  });

  it('rejects a malformed station id with 400', async () => {
    await request(app.getHttpServer()).get('/stations/not-a-uuid').expect(400);
  });

  it('lists cabins for a station', async () => {
    const res = await request(app.getHttpServer()).get(`/stations/${STATION_ID}/cabins`).expect(200);

    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[1]).toEqual(
      expect.objectContaining({ code: 'C-02', isPaid: true, price: { amount: '50.00', currency: 'DZD' } }),
    );
  });

  it('returns a third-party place detail with no authentication required', async () => {
    const res = await request(app.getHttpServer()).get(`/third-party-places/${PLACE_ID}`).expect(200);

    expect(res.body).toEqual(
      expect.objectContaining({
        id: PLACE_ID,
        placeKind: 'third_party_place',
        pinColor: 'magenta', // tagged women_confirmed
        placeType: 'mosque',
      }),
    );
    expect(res.body.name).toEqual({ fr: 'Mosquée Al-Fath', ar: 'مسجد الفتح', en: 'Mosquée Al-Fath' });
  });

  it('returns 404 for an unknown third-party place id', async () => {
    await request(app.getHttpServer()).get('/third-party-places/6ba7b810-9dad-41d4-80b4-00c04fd430c9').expect(404);
  });

  it('a station detail starts with no reviews', async () => {
    const res = await request(app.getHttpServer()).get(`/stations/${STATION_ID}`).expect(200);
    expect(res.body).toEqual(expect.objectContaining({ averageRating: null, reviewCount: 0 }));
  });

  it('submitting a station review updates the aggregate on the next detail fetch', async () => {
    await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 4, comment: 'Propre et bien entretenu.' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 2 })
      .expect(201);

    const res = await request(app.getHttpServer()).get(`/stations/${STATION_ID}`).expect(200);
    expect(res.body.averageRating).toBe(3);
    expect(res.body.reviewCount).toBe(2);
  });

  it('rejects a station review with a rating outside 1-5', async () => {
    await request(app.getHttpServer()).post(`/places/station/${STATION_ID}/reviews`).send({ rating: 6 }).expect(400);
    await request(app.getHttpServer()).post(`/places/station/${STATION_ID}/reviews`).send({ rating: 0 }).expect(400);
  });

  it('submitting a third-party place review updates the aggregate on the next detail fetch', async () => {
    await request(app.getHttpServer())
      .post(`/places/third-party-place/${PLACE_ID}/reviews`)
      .send({ rating: 5 })
      .expect(201);

    const res = await request(app.getHttpServer()).get(`/third-party-places/${PLACE_ID}`).expect(200);
    expect(res.body.averageRating).toBe(5);
    expect(res.body.reviewCount).toBe(1);
  });
});
