import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { PlacesController } from '../src/composition/places/interface/controllers/places.controller';
import { PlacesQueryService } from '../src/composition/places/places-query.service';
import { StationQueryService } from '../src/modules/station-network/application/station-query.service';
import { GeoPosition } from '../src/shared-kernel';
import {
  STATION_REPOSITORY,
  StationRepository,
  StationSearchPage,
} from '../src/modules/station-network/domain/ports/station.repository';
import { ThirdPartyPlaceQueryService } from '../src/modules/third-party-places/application/third-party-place-query.service';
import {
  THIRD_PARTY_PLACE_REPOSITORY,
  ThirdPartyPlaceRepository,
  ThirdPartyPlaceSearchPage,
} from '../src/modules/third-party-places/domain/ports/third-party-place.repository';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import {
  STATION_REVIEW_REPOSITORY,
  StationReviewRepository,
} from '../src/modules/station-network/domain/ports/station-review.repository';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceReviewRepository,
} from '../src/modules/third-party-places/domain/ports/third-party-place-review.repository';

class FakeStationReviewRepository implements StationReviewRepository {
  async save() {}
  async findById() {
    return null;
  }
  async listByUserId() {
    return { data: [], nextCursor: null };
  }
  async delete() {}
  async aggregateByStationId() {
    return { averageRating: null, reviewCount: 0 };
  }
}

class FakeThirdPartyPlaceReviewRepository implements ThirdPartyPlaceReviewRepository {
  async save() {}
  async findById() {
    return null;
  }
  async listByUserId() {
    return { data: [], nextCursor: null };
  }
  async delete() {}
  async aggregateByThirdPartyPlaceId() {
    return { averageRating: null, reviewCount: 0 };
  }
}

class FakeStationRepository implements StationRepository {
  async findById() {
    return null;
  }
  async findAll() {
    return [];
  }
  async searchNearby(): Promise<StationSearchPage> {
    return {
      data: [
        {
          id: 's1',
          code: 'ST-001',
          configuration: 'fixe',
          status: 'active',
          position: GeoPosition.of(36.751, 3.051),
          distanceMeters: 50,
          hasSlatokiTent: false,
          cabinPricingMix: 'all_free',
          averageRating: null,
          reviewCount: 0,
        },
      ],
      nextCursor: null,
    };
  }
  async findCabinById() {
    return null;
  }
  async updateCabinOccupancy() {}
  async findNearestAccessible() {
    return null;
  }
  async findStationCodesByCabinIds(cabinIds: string[]): Promise<Map<string, string>> {
    return new Map(cabinIds.map((id) => [id, 'ST-001']));
  }
}

class FakeThirdPartyPlaceRepository implements ThirdPartyPlaceRepository {
  async findById() {
    return null;
  }
  async searchNearby(): Promise<ThirdPartyPlaceSearchPage> {
    return {
      data: [
        {
          id: 'p1',
          nameFr: 'Mosquée Al-Fath',
          nameAr: 'مسجد الفتح',
          placeType: 'mosque',
          position: GeoPosition.of(36.752, 3.052),
          distanceMeters: 200,
          isFree: true,
          declaredStatus: 'open',
          statusSource: 'community',
          tags: ['women_confirmed'],
          averageRating: null,
          reviewCount: 0,
        },
      ],
      nextCursor: null,
    };
  }
}

describe('GET /places/nearby (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [PlacesController],
      providers: [
        PlacesQueryService,
        StationQueryService,
        ThirdPartyPlaceQueryService,
        { provide: STATION_REPOSITORY, useClass: FakeStationRepository },
        { provide: THIRD_PARTY_PLACE_REPOSITORY, useClass: FakeThirdPartyPlaceRepository },
        { provide: STATION_REVIEW_REPOSITORY, useClass: FakeStationReviewRepository },
        { provide: THIRD_PARTY_PLACE_REVIEW_REPOSITORY, useClass: FakeThirdPartyPlaceReviewRepository },
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

  it('returns a unified, distance-sorted list with no authentication required', async () => {
    const res = await request(app.getHttpServer())
      .get('/places/nearby')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(200);

    expect(res.body.data.map((p: { id: string }) => p.id)).toEqual(['s1', 'p1']);
    expect(res.body.data[0]).toEqual(
      expect.objectContaining({ placeKind: 'station', pinColor: 'green', distanceMeters: 50 }),
    );
    expect(res.body.data[1]).toEqual(
      expect.objectContaining({ placeKind: 'third_party_place', pinColor: 'magenta', distanceMeters: 200 }),
    );
  });

  it('requires lat/lng and rejects a missing one with 400', async () => {
    await request(app.getHttpServer()).get('/places/nearby').query({ lat: 36.75 }).expect(400);
  });

  it('rejects a radiusMeters above the 20000 cap with 400', async () => {
    await request(app.getHttpServer())
      .get('/places/nearby')
      .query({ lat: 36.75, lng: 3.05, radiusMeters: 20001 })
      .expect(400);
  });

  it('accepts repeated type[] query params', async () => {
    await request(app.getHttpServer())
      .get('/places/nearby')
      .query({ lat: 36.75, lng: 3.05, type: ['free_wc', 'slatoki'] })
      .expect(200);
  });

  it('rejects an unrecognized type value with 400', async () => {
    await request(app.getHttpServer())
      .get('/places/nearby')
      .query({ lat: 36.75, lng: 3.05, type: 'not-a-real-type' })
      .expect(400);
  });
});
