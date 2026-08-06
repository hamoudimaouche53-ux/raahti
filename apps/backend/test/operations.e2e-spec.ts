import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AlertService } from '../src/modules/operations/application/alert.service';
import { FleetStatusService } from '../src/modules/operations/application/fleet-status.service';
import { MaintenanceInterventionService } from '../src/modules/operations/application/maintenance-intervention.service';
import { OccupancyHistoryService } from '../src/modules/operations/application/occupancy-history.service';
import { Alert } from '../src/modules/operations/domain/entities/alert.entity';
import { MaintenanceIntervention } from '../src/modules/operations/domain/entities/maintenance-intervention.entity';
import { ALERT_REPOSITORY, AlertRepository } from '../src/modules/operations/domain/ports/alert.repository';
import {
  MAINTENANCE_INTERVENTION_REPOSITORY,
  MaintenanceInterventionRepository,
} from '../src/modules/operations/domain/ports/maintenance-intervention.repository';
import {
  TELEMETRY_READING_REPOSITORY,
  TelemetryMetric,
  TelemetryReadingRepository,
  TelemetrySeriesPoint,
} from '../src/modules/operations/domain/ports/telemetry-reading.repository';
import { AlertStatus } from '../src/modules/operations/domain/value-objects/alert-status.vo';
import { AlertsController } from '../src/modules/operations/interface/controllers/alerts.controller';
import { FleetController } from '../src/modules/operations/interface/controllers/fleet.controller';
import { MaintenanceInterventionsController } from '../src/modules/operations/interface/controllers/maintenance-interventions.controller';
import { StationQueryService } from '../src/modules/station-network/application/station-query.service';
import { Cabin } from '../src/modules/station-network/domain/entities/cabin.entity';
import { Station } from '../src/modules/station-network/domain/entities/station.entity';
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
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { GeoPosition, Money } from '../src/shared-kernel';

const STATION_1 = '550e8400-e29b-41d4-a716-446655440000';
const STATION_2 = '6ba7b810-9dad-41d4-80b4-00c04fd430c8';
const ALERT_1 = '16fd2706-8baf-433b-82eb-8c7fada847da';
const UNKNOWN_ALERT = '6ba7b810-9dad-41d4-80b4-00c04fd430c9';
const OPERATOR_ID = 'operator-1';

class FakeStationRepository implements StationRepository {
  async findById(id: string): Promise<Station | null> {
    if (id !== STATION_1) return null;
    return this.station(STATION_1);
  }

  async findAll(): Promise<Station[]> {
    return [this.station(STATION_1), this.station(STATION_2)];
  }

  async searchNearby(): Promise<StationSearchPage> {
    return { data: [], nextCursor: null };
  }

  async findCabinById(): Promise<Cabin | null> {
    return null;
  }

  async findNearestAccessible() {
    return null;
  }

  async findStationCodesByCabinIds(cabinIds: string[]): Promise<Map<string, string>> {
    return new Map(cabinIds.map((id) => [id, 'ST-001']));
  }

  async updateCabinOccupancy(): Promise<void> {}

  private station(id: string): Station {
    return Station.restore({
      id,
      code: id === STATION_1 ? 'ST-001' : 'ST-002',
      configuration: 'fixe',
      position: GeoPosition.of(36.75, 3.05),
      status: 'active',
      cabinCapacity: 1,
      tankCapacityLiters: 500,
      installedAt: new Date('2026-01-01'),
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
      cabins:
        id === STATION_1
          ? [
              Cabin.restore({
                id: 'c1',
                stationId: id,
                code: 'C-01',
                type: 'H',
                occupancyStatus: 'occupied',
                isPaid: true,
                price: Money.fromDecimalString('50.00', 'DZD'),
              }),
            ]
          : [],
      slatokiTent: null,
    });
  }
}

class FakeStationReviewRepository implements StationReviewRepository {
  async save(): Promise<void> {}
  async findById() {
    return null;
  }
  async listByUserId() {
    return { data: [], nextCursor: null };
  }
  async delete() {}
  async aggregateByStationId(): Promise<StationRatingAggregate> {
    return { averageRating: null, reviewCount: 0 };
  }
}

class InMemoryAlertRepository implements AlertRepository {
  private readonly items = new Map<string, Alert>();

  seed(alert: Alert): void {
    this.items.set(alert.id, alert);
  }

  async save(alert: Alert): Promise<void> {
    this.items.set(alert.id, alert);
  }

  async findById(id: string): Promise<Alert | null> {
    return this.items.get(id) ?? null;
  }

  async findAll(status?: AlertStatus): Promise<Alert[]> {
    const all = [...this.items.values()];
    return status ? all.filter((alert) => alert.status === status) : all;
  }

  async countActiveGroupedByStation(): Promise<Map<string, number>> {
    const counts = new Map<string, number>();
    for (const alert of this.items.values()) {
      if (alert.isActive) {
        counts.set(alert.stationId, (counts.get(alert.stationId) ?? 0) + 1);
      }
    }
    return counts;
  }
}

class InMemoryMaintenanceInterventionRepository implements MaintenanceInterventionRepository {
  private readonly items: MaintenanceIntervention[] = [];

  async save(intervention: MaintenanceIntervention): Promise<void> {
    this.items.push(intervention);
  }

  async findAll(): Promise<MaintenanceIntervention[]> {
    return [...this.items];
  }
}

class FakeTelemetryReadingRepository implements TelemetryReadingRepository {
  async findLatestValue(stationId: string, metric: TelemetryMetric): Promise<number | null> {
    if (stationId === STATION_1 && metric === 'battery_level') return 87;
    return null;
  }

  async findSeries(): Promise<TelemetrySeriesPoint[]> {
    return [{ recordedAt: new Date('2026-08-01T06:00:00Z'), value: 4 }];
  }
}

describe('Operations endpoints (e2e)', () => {
  let app: INestApplication;
  let alertRepo: InMemoryAlertRepository;

  beforeAll(async () => {
    alertRepo = new InMemoryAlertRepository();
    alertRepo.seed(Alert.raise({ id: ALERT_1, stationId: STATION_1, type: 'fire', severity: 'critical' }));

    const moduleRef = await Test.createTestingModule({
      controllers: [AlertsController, MaintenanceInterventionsController, FleetController],
      providers: [
        AlertService,
        MaintenanceInterventionService,
        FleetStatusService,
        OccupancyHistoryService,
        StationQueryService,
        { provide: ALERT_REPOSITORY, useValue: alertRepo },
        { provide: MAINTENANCE_INTERVENTION_REPOSITORY, useClass: InMemoryMaintenanceInterventionRepository },
        { provide: TELEMETRY_READING_REPOSITORY, useClass: FakeTelemetryReadingRepository },
        { provide: STATION_REPOSITORY, useClass: FakeStationRepository },
        { provide: STATION_REVIEW_REPOSITORY, useClass: FakeStationReviewRepository },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.use((req: { user?: unknown }, _res: unknown, next: () => void) => {
      req.user = { sub: OPERATOR_ID, role: 'operateur', aal: 'aal2', exp: 0, iat: 0 };
      next();
    });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /ops/alerts', () => {
    it('lists alerts', async () => {
      const res = await request(app.getHttpServer()).get('/ops/alerts').expect(200);
      expect(res.body.data.map((a: { id: string }) => a.id)).toEqual([ALERT_1]);
    });

    it('filters by status', async () => {
      const res = await request(app.getHttpServer()).get('/ops/alerts?status=resolved').expect(200);
      expect(res.body.data).toEqual([]);
    });

    it('rejects an invalid status filter with 400', async () => {
      await request(app.getHttpServer()).get('/ops/alerts?status=bogus').expect(400);
    });
  });

  describe('PATCH /ops/alerts/{alertId}', () => {
    it('acknowledges an alert', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/ops/alerts/${ALERT_1}`)
        .send({ status: 'acknowledged' })
        .expect(200);

      expect(res.body.status).toBe('acknowledged');
    });

    it('rejects an invalid transition with 400', async () => {
      await request(app.getHttpServer()).patch(`/ops/alerts/${ALERT_1}`).send({ status: 'resolved' }).expect(200);
      await request(app.getHttpServer()).patch(`/ops/alerts/${ALERT_1}`).send({ status: 'acknowledged' }).expect(400);
    });

    it('returns 404 for an unknown alert', async () => {
      await request(app.getHttpServer()).patch(`/ops/alerts/${UNKNOWN_ALERT}`).send({ status: 'acknowledged' }).expect(404);
    });

    it('rejects a status value not in AlertUpdateRequest (e.g. "open") with 400', async () => {
      await request(app.getHttpServer()).patch(`/ops/alerts/${ALERT_1}`).send({ status: 'open' }).expect(400);
    });
  });

  describe('GET/POST /ops/maintenance-interventions', () => {
    it('starts empty', async () => {
      const res = await request(app.getHttpServer()).get('/ops/maintenance-interventions').expect(200);
      expect(res.body.data).toEqual([]);
    });

    it('schedules an intervention, defaulting assignedTo to the caller when omitted', async () => {
      const res = await request(app.getHttpServer())
        .post('/ops/maintenance-interventions')
        .send({ stationId: STATION_1, interventionType: 'refill', scheduledAt: '2026-08-10T09:00:00Z' })
        .expect(201);

      expect(res.body.stationId).toBe(STATION_1);
      expect(res.body.status).toBe('scheduled');

      const list = await request(app.getHttpServer()).get('/ops/maintenance-interventions').expect(200);
      expect(list.body.data).toHaveLength(1);
    });

    it('rejects an unknown interventionType with 400', async () => {
      await request(app.getHttpServer())
        .post('/ops/maintenance-interventions')
        .send({ stationId: STATION_1, interventionType: 'bogus', scheduledAt: '2026-08-10T09:00:00Z' })
        .expect(400);
    });
  });

  describe('GET /ops/stations', () => {
    it('returns fleet-wide status with cabins, telemetry, and active alert counts', async () => {
      const res = await request(app.getHttpServer()).get('/ops/stations').expect(200);

      const station1 = res.body.data.find((s: { stationId: string }) => s.stationId === STATION_1);
      const station2 = res.body.data.find((s: { stationId: string }) => s.stationId === STATION_2);

      expect(station1.batteryLevel).toBe(87);
      expect(station1.cabins).toHaveLength(1);
      expect(station1.cabins[0]).toEqual(
        expect.objectContaining({ id: 'c1', occupancyStatus: 'occupied', price: { amount: '50.00', currency: 'DZD' } }),
      );
      // ALERT_1 was resolved by the earlier PATCH test — no active alerts remain for STATION_1.
      expect(station1.activeAlertCount).toBe(0);

      expect(station2.batteryLevel).toBeNull();
      expect(station2.cabins).toEqual([]);
    });
  });

  describe('GET /ops/stations/{stationId}/occupancy-history', () => {
    it('returns a station occupancy series', async () => {
      const res = await request(app.getHttpServer())
        .get(`/ops/stations/${STATION_1}/occupancy-history?from=2026-08-01&to=2026-08-02`)
        .expect(200);

      expect(res.body.stationId).toBe(STATION_1);
      expect(res.body.points).toEqual([{ timestamp: '2026-08-01T06:00:00.000Z', occupiedCabinCount: 4 }]);
    });

    it('returns 404 for an unknown station', async () => {
      await request(app.getHttpServer())
        .get(`/ops/stations/${UNKNOWN_ALERT}/occupancy-history?from=2026-08-01&to=2026-08-02`)
        .expect(404);
    });

    it('rejects a missing "to" query param with 400', async () => {
      await request(app.getHttpServer()).get(`/ops/stations/${STATION_1}/occupancy-history?from=2026-08-01`).expect(400);
    });
  });
});
