import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { SlatokiController } from '../src/modules/slatoki/interface/controllers/slatoki.controller';
import { SlatokiQueryService } from '../src/modules/slatoki/application/slatoki-query.service';
import { StationQueryService } from '../src/modules/station-network/application/station-query.service';
import {
  STATION_REPOSITORY,
  StationRepository,
  StationSearchPage,
} from '../src/modules/station-network/domain/ports/station.repository';
import {
  STATION_REVIEW_REPOSITORY,
  StationRatingAggregate,
  StationReviewRepository,
} from '../src/modules/station-network/domain/ports/station-review.repository';
import { ThirdPartyPlaceQueryService } from '../src/modules/third-party-places/application/third-party-place-query.service';
import {
  THIRD_PARTY_PLACE_REPOSITORY,
  ThirdPartyPlaceRepository,
  ThirdPartyPlaceSearchPage,
} from '../src/modules/third-party-places/domain/ports/third-party-place.repository';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceRatingAggregate,
  ThirdPartyPlaceReviewRepository,
} from '../src/modules/third-party-places/domain/ports/third-party-place-review.repository';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { GeoPosition } from '../src/shared-kernel';

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
          code: 'ST-TENT',
          configuration: 'mobile',
          status: 'active',
          position: GeoPosition.of(36.751, 3.051),
          distanceMeters: 80,
          hasSlatokiTent: true,
          cabinPricingMix: 'all_free',
          averageRating: null,
          reviewCount: 0,
        },
        {
          id: 's2',
          code: 'ST-PLAIN',
          configuration: 'fixe',
          status: 'active',
          position: GeoPosition.of(36.752, 3.052),
          distanceMeters: 90,
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
  async findStationCodesByCabinIds(): Promise<Map<string, string>> {
    return new Map();
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
          nameFr: 'Mosquée Vérifiée',
          nameAr: 'مسجد موثق',
          placeType: 'mosque',
          position: GeoPosition.of(36.753, 3.053),
          distanceMeters: 150,
          isFree: true,
          declaredStatus: 'open',
          statusSource: 'community',
          tags: ['prayer', 'wudu', 'women_confirmed'],
          averageRating: null,
          reviewCount: 0,
        },
        {
          id: 'p2',
          nameFr: 'Mosquée Générique',
          nameAr: 'مسجد عام',
          placeType: 'mosque',
          position: GeoPosition.of(36.754, 3.054),
          distanceMeters: 300,
          isFree: true,
          declaredStatus: 'open',
          statusSource: 'community',
          tags: ['prayer'],
          averageRating: null,
          reviewCount: 0,
        },
        {
          id: 'p3',
          nameFr: 'Commerce',
          nameAr: 'متجر',
          placeType: 'business',
          position: GeoPosition.of(36.755, 3.055),
          distanceMeters: 50,
          isFree: false,
          declaredStatus: 'open',
          statusSource: 'community',
          tags: ['pmr'],
          averageRating: null,
          reviewCount: 0,
        },
      ],
      nextCursor: null,
    };
  }
}

class FakeStationReviewRepository implements StationReviewRepository {
  async save() {}
  async aggregateByStationId(): Promise<StationRatingAggregate> {
    return { averageRating: null, reviewCount: 0 };
  }
}

class FakeThirdPartyPlaceReviewRepository implements ThirdPartyPlaceReviewRepository {
  async save() {}
  async aggregateByThirdPartyPlaceId(): Promise<ThirdPartyPlaceRatingAggregate> {
    return { averageRating: null, reviewCount: 0 };
  }
}

describe('GET /slatoki/places (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [SlatokiController],
      providers: [
        SlatokiQueryService,
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

  it('returns Slatoki-qualified places only, distance-sorted, with no authentication required', async () => {
    const res = await request(app.getHttpServer())
      .get('/slatoki/places')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(200);

    // s2 (no tent) and p3 (business, no prayer/wudu tag) must be excluded
    // even though p3 is the closest result overall.
    expect(res.body.data.map((p: { id: string }) => p.id)).toEqual(['s1', 'p1', 'p2']);
  });

  it('marks the Slatoki-tented station and the women_confirmed-tagged mosque as verified_confirmed', async () => {
    const res = await request(app.getHttpServer())
      .get('/slatoki/places')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(200);

    const byId = Object.fromEntries(res.body.data.map((p: { id: string }) => [p.id, p]));
    expect(byId.s1.womenVerificationLevel).toBe('verified_confirmed');
    expect(byId.p1.womenVerificationLevel).toBe('verified_confirmed');
    expect(byId.p2.womenVerificationLevel).toBe('generic');
  });

  it('marks the Slatoki-tented station pin magenta and returns its RAHETI-code-derived trilingual name', async () => {
    const res = await request(app.getHttpServer())
      .get('/slatoki/places')
      .query({ lat: 36.75, lng: 3.05 })
      .expect(200);

    const station = res.body.data.find((p: { id: string }) => p.id === 's1');
    expect(station.pinColor).toBe('magenta');
    expect(station.name).toEqual({ fr: 'ST-TENT', ar: 'ST-TENT', en: 'ST-TENT' });
  });

  it('applies the wudu_only filter, excluding a mosque tagged prayer only', async () => {
    const res = await request(app.getHttpServer())
      .get('/slatoki/places')
      .query({ lat: 36.75, lng: 3.05, filter: 'wudu_only' })
      .expect(200);

    expect(res.body.data.map((p: { id: string }) => p.id)).toEqual(['s1', 'p1']);
  });

  it('requires lat/lng and rejects a missing one with 400', async () => {
    await request(app.getHttpServer()).get('/slatoki/places').query({ lat: 36.75 }).expect(400);
  });

  it('rejects an unrecognized filter value with 400', async () => {
    await request(app.getHttpServer())
      .get('/slatoki/places')
      .query({ lat: 36.75, lng: 3.05, filter: 'everything' })
      .expect(400);
  });
});
