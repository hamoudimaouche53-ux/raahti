import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { GeoPosition } from '../src/shared-kernel';

import { StationQueryService } from '../src/modules/station-network/application/station-query.service';
import { ReviewService as StationReviewService } from '../src/modules/station-network/application/review.service';
import { StationReview } from '../src/modules/station-network/domain/entities/review.entity';
import {
  STATION_REVIEW_REPOSITORY,
  StationRatingAggregate,
  StationReviewPage,
  StationReviewRepository,
} from '../src/modules/station-network/domain/ports/station-review.repository';
import { StationReviewsController } from '../src/modules/station-network/interface/controllers/station-reviews.controller';
import { Station } from '../src/modules/station-network/domain/entities/station.entity';
import {
  STATION_REPOSITORY,
  StationRepository,
  StationSearchPage,
} from '../src/modules/station-network/domain/ports/station.repository';

import { ThirdPartyPlaceQueryService } from '../src/modules/third-party-places/application/third-party-place-query.service';
import { ReviewService as ThirdPartyPlaceReviewService } from '../src/modules/third-party-places/application/review.service';
import { ThirdPartyPlaceReview } from '../src/modules/third-party-places/domain/entities/review.entity';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceRatingAggregate,
  ThirdPartyPlaceReviewPage,
  ThirdPartyPlaceReviewRepository,
} from '../src/modules/third-party-places/domain/ports/third-party-place-review.repository';
import { ThirdPartyPlaceReviewsController } from '../src/modules/third-party-places/interface/controllers/third-party-place-reviews.controller';
import { ThirdPartyPlace } from '../src/modules/third-party-places/domain/entities/third-party-place.entity';
import {
  THIRD_PARTY_PLACE_REPOSITORY,
  ThirdPartyPlaceRepository,
  ThirdPartyPlaceSearchPage,
} from '../src/modules/third-party-places/domain/ports/third-party-place.repository';

import { MyReviewsQueryService } from '../src/composition/reviews/my-reviews-query.service';
import { MyReviewsController } from '../src/composition/reviews/interface/controllers/my-reviews.controller';

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
      cabins: [],
      slatokiTent: null,
    });
  }
  async searchNearby(): Promise<StationSearchPage> {
    return { data: [], nextCursor: null };
  }
  async findAll(): Promise<Station[]> {
    return [];
  }
  async findCabinById() {
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
      tags: [],
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

  async listByUserId(userId: string, _cursor: string | null, limit: number): Promise<StationReviewPage> {
    const data = this.items.filter((item) => item.userId === userId).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return { data: data.slice(0, limit), nextCursor: null };
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
    return {
      averageRating: forStation.reduce((sum, r) => sum + r.rating, 0) / forStation.length,
      reviewCount: forStation.length,
    };
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

  async listByUserId(userId: string, _cursor: string | null, limit: number): Promise<ThirdPartyPlaceReviewPage> {
    const data = this.items.filter((item) => item.userId === userId).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return { data: data.slice(0, limit), nextCursor: null };
  }

  async delete(id: string): Promise<void> {
    const index = this.items.findIndex((item) => item.id === id);
    if (index !== -1) {
      this.items.splice(index, 1);
    }
  }

  async aggregateByThirdPartyPlaceId(placeId: string): Promise<ThirdPartyPlaceRatingAggregate> {
    const forPlace = this.items.filter((r) => r.thirdPartyPlaceId === placeId);
    if (forPlace.length === 0) {
      return { averageRating: null, reviewCount: 0 };
    }
    return {
      averageRating: forPlace.reduce((sum, r) => sum + r.rating, 0) / forPlace.length,
      reviewCount: forPlace.length,
    };
  }
}

describe('Reviews management (e2e) — EPIC-05 US-05.2', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [StationReviewsController, ThirdPartyPlaceReviewsController, MyReviewsController],
      providers: [
        StationQueryService,
        ThirdPartyPlaceQueryService,
        StationReviewService,
        ThirdPartyPlaceReviewService,
        MyReviewsQueryService,
        { provide: STATION_REPOSITORY, useClass: FakeStationRepository },
        { provide: THIRD_PARTY_PLACE_REPOSITORY, useClass: FakeThirdPartyPlaceRepository },
        { provide: STATION_REVIEW_REPOSITORY, useClass: InMemoryStationReviewRepository },
        { provide: THIRD_PARTY_PLACE_REVIEW_REPOSITORY, useClass: InMemoryThirdPartyPlaceReviewRepository },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    // No JwtAuthGuard is registered in this test app — a trivial middleware
    // stands in for it, same as facilities-detail.e2e-spec.ts, except it also
    // lets a test switch the acting user via an `x-test-user` header (needed
    // to exercise the ownership-check 403 path).
    app.use((req: { user?: unknown; headers: Record<string, unknown> }, _res: unknown, next: () => void) => {
      const sub = (req.headers['x-test-user'] as string | undefined) ?? 'user-1';
      req.user = { sub, exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('a submitted station review appears in GET /users/me/reviews with correct placeName/placeType', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 4, comment: 'Propre.' })
      .expect(201);

    const listRes = await request(app.getHttpServer()).get('/users/me/reviews').expect(200);

    expect(listRes.body.data).toEqual([
      expect.objectContaining({
        id: createRes.body.id,
        placeType: 'station',
        placeId: STATION_ID,
        placeName: { fr: 'ST-001', ar: 'ST-001', en: 'ST-001' },
        rating: 4,
        comment: 'Propre.',
      }),
    ]);
  });

  it('update by the owner succeeds and is reflected in both the PATCH response and the my-reviews list', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 2, comment: 'Meh.' })
      .expect(201);
    const reviewId = createRes.body.id;

    const updateRes = await request(app.getHttpServer())
      .patch(`/places/station/${STATION_ID}/reviews/${reviewId}`)
      .send({ rating: 5, comment: 'Excellent finally.' })
      .expect(200);
    expect(updateRes.body).toEqual(expect.objectContaining({ id: reviewId, rating: 5, comment: 'Excellent finally.' }));

    const listRes = await request(app.getHttpServer()).get('/users/me/reviews').expect(200);
    const updated = listRes.body.data.find((item: { id: string }) => item.id === reviewId);
    expect(updated).toEqual(expect.objectContaining({ rating: 5, comment: 'Excellent finally.' }));
  });

  it('update by a different user is rejected with 403 and leaves the review unchanged', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 3, comment: 'Original.' })
      .expect(201);
    const reviewId = createRes.body.id;

    await request(app.getHttpServer())
      .patch(`/places/station/${STATION_ID}/reviews/${reviewId}`)
      .set('x-test-user', 'user-2')
      .send({ rating: 1, comment: 'Hijacked.' })
      .expect(403);

    const listRes = await request(app.getHttpServer()).get('/users/me/reviews').expect(200);
    const untouched = listRes.body.data.find((item: { id: string }) => item.id === reviewId);
    expect(untouched).toEqual(expect.objectContaining({ rating: 3, comment: 'Original.' }));
  });

  it('delete then re-list confirms removal, and a second delete returns 404', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 3 })
      .expect(201);
    const reviewId = createRes.body.id;

    await request(app.getHttpServer()).delete(`/places/station/${STATION_ID}/reviews/${reviewId}`).expect(204);

    const listRes = await request(app.getHttpServer()).get('/users/me/reviews').expect(200);
    expect(listRes.body.data.find((item: { id: string }) => item.id === reviewId)).toBeUndefined();

    await request(app.getHttpServer()).delete(`/places/station/${STATION_ID}/reviews/${reviewId}`).expect(404);
  });

  it('a delete attempt by a non-owner is rejected with 403, not silently succeeding', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/third-party-place/${PLACE_ID}/reviews`)
      .send({ rating: 4 })
      .expect(201);
    const reviewId = createRes.body.id;

    await request(app.getHttpServer())
      .delete(`/places/third-party-place/${PLACE_ID}/reviews/${reviewId}`)
      .set('x-test-user', 'user-2')
      .expect(403);
  });

  it('merges a station review and a third-party-place review into a single createdAt-desc-sorted, cross-source page', async () => {
    await request(app.getHttpServer())
      .post(`/places/third-party-place/${PLACE_ID}/reviews`)
      .send({ rating: 5, comment: 'Calme.' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 4, comment: 'Propre.' })
      .expect(201);

    const listRes = await request(app.getHttpServer()).get('/users/me/reviews').query({ limit: 100 }).expect(200);

    const kinds = new Set(listRes.body.data.map((item: { placeType: string }) => item.placeType));
    expect(kinds.has('station')).toBe(true);
    expect(kinds.has('third-party-place')).toBe(true);
    const thirdPartyItem = listRes.body.data.find((item: { placeType: string }) => item.placeType === 'third-party-place');
    expect(thirdPartyItem).toEqual(
      expect.objectContaining({ placeId: PLACE_ID, placeName: { fr: 'Mosquée Al-Fath', ar: 'مسجد الفتح', en: 'Mosquée Al-Fath' } }),
    );

    // newest-first: every consecutive pair must be non-increasing by createdAt.
    const createdAts = listRes.body.data.map((item: { createdAt: string }) => new Date(item.createdAt).getTime());
    for (let i = 1; i < createdAts.length; i++) {
      expect(createdAts[i]).toBeLessThanOrEqual(createdAts[i - 1]);
    }
  });

  it('rejects an update with an out-of-range rating with 400', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 3 })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/places/station/${STATION_ID}/reviews/${createRes.body.id}`)
      .send({ rating: 7 })
      .expect(400);
  });

  it('returns 404 (not leaking existence) for a PATCH on a review that exists but under the wrong placeType/placeId', async () => {
    const createRes = await request(app.getHttpServer())
      .post(`/places/station/${STATION_ID}/reviews`)
      .send({ rating: 3 })
      .expect(201);

    // Same review id, but addressed through the third-party-place route.
    await request(app.getHttpServer())
      .patch(`/places/third-party-place/${PLACE_ID}/reviews/${createRes.body.id}`)
      .send({ rating: 1 })
      .expect(404);
  });
});
