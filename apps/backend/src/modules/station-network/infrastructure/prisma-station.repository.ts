import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { GeoPosition, Money } from '../../../shared-kernel';
import { PrismaService } from '../../../platform/database/prisma.service';
import { Cabin } from '../domain/entities/cabin.entity';
import { SlatokiTent } from '../domain/entities/slatoki-tent.entity';
import { CabinPricingMix, Station } from '../domain/entities/station.entity';
import {
  NearestAccessibleStationResult,
  StationRepository,
  StationSearchCriteria,
  StationSearchPage,
  StationSearchResult,
} from '../domain/ports/station.repository';
import { assertCabinType } from '../domain/value-objects/cabin-type.vo';
import { assertOccupancyStatus, OccupancyStatus } from '../domain/value-objects/occupancy-status.vo';
import { PlaceFilterType } from '../domain/value-objects/place-filter-type.vo';
import { assertStationConfiguration } from '../domain/value-objects/station-configuration.vo';
import { assertStationStatus } from '../domain/value-objects/station-status.vo';
import { decodeSearchCursor, encodeSearchCursor } from './search-cursor';

interface StationRow {
  id: string;
  code: string;
  configuration: string;
  status: string;
  cabin_capacity: number;
  tank_capacity_liters: number;
  installed_at: Date;
  created_at: Date;
  updated_at: Date;
  lat: number;
  lng: number;
}

interface StationSearchRow {
  id: string;
  code: string;
  configuration: string;
  status: string;
  lat: number;
  lng: number;
  distance_meters: number;
  has_slatoki_tent: boolean;
  cabin_count: number;
  all_free: boolean;
  all_paid: boolean;
  average_rating: number | null;
  review_count: number;
}

/**
 * `Station.position` is a PostGIS `geography(Point,4326)` column, declared
 * `Unsupported` in schema.prisma (ADR-0012) — Prisma's normal query builder
 * can neither select nor write it, so every read of a Station row goes
 * through $queryRaw. Cabins/SlatokiTent have no geography column and use the
 * normal typed Prisma Client.
 */
@Injectable()
export class PrismaStationRepository implements StationRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<Station | null> {
    const rows = await this.prisma.$queryRaw<StationRow[]>`
      SELECT id, code, configuration, status, cabin_capacity, tank_capacity_liters,
             installed_at, created_at, updated_at,
             ST_Y(position::geometry) AS lat, ST_X(position::geometry) AS lng
      FROM station
      WHERE id = ${id}::uuid
    `;
    const row = rows[0];
    if (!row) {
      return null;
    }

    const [cabinRecords, tentRecord] = await Promise.all([
      this.prisma.cabin.findMany({ where: { stationId: id } }),
      this.prisma.slatokiTent.findUnique({ where: { stationId: id } }),
    ]);

    assertStationConfiguration(row.configuration);
    assertStationStatus(row.status);

    return Station.restore({
      id: row.id,
      code: row.code,
      configuration: row.configuration,
      position: GeoPosition.of(row.lat, row.lng),
      status: row.status,
      cabinCapacity: row.cabin_capacity,
      tankCapacityLiters: row.tank_capacity_liters,
      installedAt: row.installed_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      cabins: cabinRecords.map((record) => this.cabinToDomain(record)),
      slatokiTent: tentRecord
        ? SlatokiTent.restore({
            id: tentRecord.id,
            stationId: tentRecord.stationId,
            deploymentStatus: tentRecord.deploymentStatus,
            matCapacity: tentRecord.matCapacity,
            hasLighting: tentRecord.hasLighting,
            hasPrivacyCurtain: tentRecord.hasPrivacyCurtain,
          })
        : null,
    });
  }

  /**
   * Fleet-wide listing (Operations FR-OPS-01) — every station regardless of
   * status, with its cabins. Cabins/tents are batch-loaded (2 extra queries
   * total, not N+1) the same way `findById` avoids fanning out per station.
   */
  async findAll(): Promise<Station[]> {
    const rows = await this.prisma.$queryRaw<StationRow[]>`
      SELECT id, code, configuration, status, cabin_capacity, tank_capacity_liters,
             installed_at, created_at, updated_at,
             ST_Y(position::geometry) AS lat, ST_X(position::geometry) AS lng
      FROM station
    `;
    if (rows.length === 0) {
      return [];
    }

    const stationIds = rows.map((row) => row.id);
    const [cabinRecords, tentRecords] = await Promise.all([
      this.prisma.cabin.findMany({ where: { stationId: { in: stationIds } } }),
      this.prisma.slatokiTent.findMany({ where: { stationId: { in: stationIds } } }),
    ]);

    const cabinsByStation = new Map<string, typeof cabinRecords>();
    for (const cabin of cabinRecords) {
      const list = cabinsByStation.get(cabin.stationId) ?? [];
      list.push(cabin);
      cabinsByStation.set(cabin.stationId, list);
    }
    const tentByStation = new Map(tentRecords.map((tent) => [tent.stationId, tent]));

    return rows.map((row) => {
      assertStationConfiguration(row.configuration);
      assertStationStatus(row.status);
      const tentRecord = tentByStation.get(row.id);
      return Station.restore({
        id: row.id,
        code: row.code,
        configuration: row.configuration,
        position: GeoPosition.of(row.lat, row.lng),
        status: row.status,
        cabinCapacity: row.cabin_capacity,
        tankCapacityLiters: row.tank_capacity_liters,
        installedAt: row.installed_at,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        cabins: (cabinsByStation.get(row.id) ?? []).map((record) => this.cabinToDomain(record)),
        slatokiTent: tentRecord
          ? SlatokiTent.restore({
              id: tentRecord.id,
              stationId: tentRecord.stationId,
              deploymentStatus: tentRecord.deploymentStatus,
              matCapacity: tentRecord.matCapacity,
              hasLighting: tentRecord.hasLighting,
              hasPrivacyCurtain: tentRecord.hasPrivacyCurtain,
            })
          : null,
      });
    });
  }

  /**
   * ST_DWithin nearby search (FR-MAP-01/02/04/05). Only `active` stations are
   * discoverable (a station under maintenance/inactive shouldn't appear as an
   * available option — inferred from FR-PLC-02's real-time-status intent, not
   * literal spec text; flagged as a judgment call, not a silent assumption).
   * Cabin and review aggregates are computed in their OWN pre-grouped CTEs
   * (one row per station_id each) before joining to the station row — joining
   * both `cabin` and `review` directly in one GROUP BY would fan-out (N cabins
   * x M reviews rows per station), silently corrupting both COUNT()s and
   * AVG(rating). The outer query's type-filter OR-logic (rahati_unit/free_wc/
   * paid_wc/slatoki) references the resulting plain boolean/numeric columns
   * instead of re-deriving aggregates inside a WHERE clause (illegal —
   * aggregates aren't available pre-GROUP BY).
   */
  async searchNearby(criteria: StationSearchCriteria): Promise<StationSearchPage> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${criteria.position.lng}, ${criteria.position.lat}), 4326)::geography`;

    const preAggregateConditions: Prisma.Sql[] = [
      Prisma.sql`ST_DWithin(s.position, ${point}, ${criteria.radiusMeters})`,
      Prisma.sql`s.status = 'active'`,
    ];
    if (criteria.query) {
      preAggregateConditions.push(Prisma.sql`s.code ILIKE ${'%' + criteria.query + '%'}`);
    }

    const decodedCursor = criteria.cursor ? decodeSearchCursor(criteria.cursor) : null;
    const postAggregateConditions: Prisma.Sql[] = [this.buildTypeFilterSql(criteria.types)];
    if (decodedCursor) {
      postAggregateConditions.push(Prisma.sql`(
        distance_meters > ${decodedCursor.distanceMeters}
        OR (distance_meters = ${decodedCursor.distanceMeters} AND id > ${decodedCursor.id}::uuid)
      )`);
    }

    const rows = await this.prisma.$queryRaw<StationSearchRow[]>`
      WITH cabin_agg AS (
        SELECT station_id,
               COUNT(*)::int AS cabin_count,
               BOOL_AND(NOT is_paid) AS all_free,
               BOOL_AND(is_paid) AS all_paid
        FROM cabin
        GROUP BY station_id
      ),
      review_agg AS (
        SELECT station_id, AVG(rating)::float AS average_rating, COUNT(*)::int AS review_count
        FROM review
        WHERE station_id IS NOT NULL
        GROUP BY station_id
      ),
      station_agg AS (
        SELECT s.id, s.code, s.configuration, s.status,
               ST_Y(s.position::geometry) AS lat, ST_X(s.position::geometry) AS lng,
               ST_Distance(s.position, ${point}) AS distance_meters,
               EXISTS(SELECT 1 FROM slatoki_tent st WHERE st.station_id = s.id) AS has_slatoki_tent,
               COALESCE(ca.cabin_count, 0) AS cabin_count,
               COALESCE(ca.all_free, false) AS all_free,
               COALESCE(ca.all_paid, false) AS all_paid,
               ra.average_rating AS average_rating,
               COALESCE(ra.review_count, 0) AS review_count
        FROM station s
        LEFT JOIN cabin_agg ca ON ca.station_id = s.id
        LEFT JOIN review_agg ra ON ra.station_id = s.id
        WHERE ${Prisma.join(preAggregateConditions, ' AND ')}
      )
      SELECT * FROM station_agg
      WHERE ${Prisma.join(postAggregateConditions, ' AND ')}
      ORDER BY distance_meters ASC, id ASC
      LIMIT ${criteria.limit + 1}
    `;

    const hasMore = rows.length > criteria.limit;
    const page = hasMore ? rows.slice(0, criteria.limit) : rows;

    return {
      data: page.map((row) => this.searchRowToResult(row)),
      nextCursor: hasMore
        ? encodeSearchCursor({ distanceMeters: page[page.length - 1].distance_meters, id: page[page.length - 1].id })
        : null,
    };
  }

  /** Backs StationQueryService.findNearestAccessible() — see the port doc comment for the radius/cabin-tiebreak judgment calls. */
  async findNearestAccessible(position: GeoPosition, radiusMeters: number): Promise<NearestAccessibleStationResult | null> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${position.lng}, ${position.lat}), 4326)::geography`;

    // Same pre-aggregated-CTE + distance-query shape as searchNearby above (avoids
    // the cabin/review fan-out join bug that method's own doc comment explains),
    // just narrowed to `LIMIT 1` and no cursor/type-filter/query params.
    const rows = await this.prisma.$queryRaw<StationSearchRow[]>`
      WITH cabin_agg AS (
        SELECT station_id,
               COUNT(*)::int AS cabin_count,
               BOOL_AND(NOT is_paid) AS all_free,
               BOOL_AND(is_paid) AS all_paid
        FROM cabin
        GROUP BY station_id
      ),
      review_agg AS (
        SELECT station_id, AVG(rating)::float AS average_rating, COUNT(*)::int AS review_count
        FROM review
        WHERE station_id IS NOT NULL
        GROUP BY station_id
      )
      SELECT s.id, s.code, s.configuration, s.status,
             ST_Y(s.position::geometry) AS lat, ST_X(s.position::geometry) AS lng,
             ST_Distance(s.position, ${point}) AS distance_meters,
             EXISTS(SELECT 1 FROM slatoki_tent st WHERE st.station_id = s.id) AS has_slatoki_tent,
             COALESCE(ca.cabin_count, 0) AS cabin_count,
             COALESCE(ca.all_free, false) AS all_free,
             COALESCE(ca.all_paid, false) AS all_paid,
             ra.average_rating AS average_rating,
             COALESCE(ra.review_count, 0) AS review_count
      FROM station s
      LEFT JOIN cabin_agg ca ON ca.station_id = s.id
      LEFT JOIN review_agg ra ON ra.station_id = s.id
      WHERE ST_DWithin(s.position, ${point}, ${radiusMeters})
        AND s.status = 'active'
      ORDER BY distance_meters ASC
      LIMIT 1
    `;

    const row = rows[0];
    if (!row) {
      return null;
    }

    const cabins = await this.prisma.cabin.findMany({ where: { stationId: row.id } });

    return {
      station: this.searchRowToResult(row),
      nearestCabinId: this.pickAccessibleCabinId(cabins),
    };
  }

  /**
   * Judgment call (FR-EMG-02 specifies no tiebreak rule): prefer a free
   * cabin; otherwise fall back to any cabin that isn't out_of_service; `null`
   * only when the station has no cabins at all.
   */
  private pickAccessibleCabinId(cabins: Array<{ id: string; occupancyStatus: string }>): string | null {
    const free = cabins.find((cabin) => cabin.occupancyStatus === 'free');
    if (free) {
      return free.id;
    }
    const usable = cabins.find((cabin) => cabin.occupancyStatus !== 'out_of_service');
    return usable ? usable.id : null;
  }

  /** Backs StationCommandService.checkCabinAvailability() — see the port doc comment. */
  async findCabinById(cabinId: string): Promise<Cabin | null> {
    const record = await this.prisma.cabin.findUnique({ where: { id: cabinId } });
    return record ? this.cabinToDomain(record) : null;
  }

  /** Backs StationCommandService.setCabinOccupancy() — see the port doc comment. */
  async updateCabinOccupancy(cabinId: string, status: OccupancyStatus): Promise<void> {
    await this.prisma.cabin.update({
      where: { id: cabinId },
      data: { occupancyStatus: status, lastStatusChangeAt: new Date() },
    });
  }

  /** Backs StationQueryService.getStationCodesForCabinIds() — see the port doc comment. */
  async findStationCodesByCabinIds(cabinIds: string[]): Promise<Map<string, string>> {
    if (cabinIds.length === 0) {
      return new Map();
    }
    const cabins = await this.prisma.cabin.findMany({
      where: { id: { in: cabinIds } },
      select: { id: true, station: { select: { code: true } } },
    });
    return new Map(cabins.map((cabin) => [cabin.id, cabin.station.code]));
  }

  private buildTypeFilterSql(types: PlaceFilterType[]): Prisma.Sql {
    if (types.length === 0) {
      return Prisma.sql`TRUE`;
    }
    const parts = types.map((type) => {
      switch (type) {
        case 'rahati_unit':
          return Prisma.sql`TRUE`; // every station matches (ADR-0021 filterPlaces semantics)
        case 'free_wc':
          return Prisma.sql`all_free`;
        case 'paid_wc':
          return Prisma.sql`all_paid`;
        case 'slatoki':
          return Prisma.sql`has_slatoki_tent`;
      }
    });
    return Prisma.sql`(${Prisma.join(parts, ' OR ')})`;
  }

  private searchRowToResult(row: StationSearchRow): StationSearchResult {
    assertStationConfiguration(row.configuration);
    assertStationStatus(row.status);
    const cabinPricingMix: CabinPricingMix =
      row.cabin_count === 0 ? 'no_cabins' : row.all_free ? 'all_free' : row.all_paid ? 'all_paid' : 'mixed';
    return {
      id: row.id,
      code: row.code,
      configuration: row.configuration,
      status: row.status,
      position: GeoPosition.of(row.lat, row.lng),
      distanceMeters: row.distance_meters,
      hasSlatokiTent: row.has_slatoki_tent,
      cabinPricingMix,
      averageRating: row.average_rating,
      reviewCount: row.review_count,
    };
  }

  private cabinToDomain(record: Prisma.CabinGetPayload<Record<string, never>>): Cabin {
    assertCabinType(record.type);
    assertOccupancyStatus(record.occupancyStatus);
    return Cabin.restore({
      id: record.id,
      stationId: record.stationId,
      code: record.code,
      type: record.type,
      occupancyStatus: record.occupancyStatus,
      isPaid: record.isPaid,
      price:
        record.isPaid && record.priceAmount
          ? Money.fromDecimalString(record.priceAmount.toString(), record.priceCurrency ?? 'DZD')
          : null,
    });
  }
}
