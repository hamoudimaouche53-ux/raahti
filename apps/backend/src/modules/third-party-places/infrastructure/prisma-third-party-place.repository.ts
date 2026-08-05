import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { GeoPosition, Money } from '../../../shared-kernel';
import { PrismaService } from '../../../platform/database/prisma.service';
import { ThirdPartyPlace } from '../domain/entities/third-party-place.entity';
import {
  ThirdPartyPlaceRepository,
  ThirdPartyPlaceSearchCriteria,
  ThirdPartyPlaceSearchPage,
  ThirdPartyPlaceSearchResult,
} from '../domain/ports/third-party-place.repository';
import { assertDeclaredStatus, assertStatusSource } from '../domain/value-objects/declared-status.vo';
import { PlaceFilterType } from '../domain/value-objects/place-filter-type.vo';
import { assertPlaceType } from '../domain/value-objects/place-type.vo';
import { assertTagCode, TagCode } from '../domain/value-objects/tag.vo';
import { decodeSearchCursor, encodeSearchCursor } from './search-cursor';

interface ThirdPartyPlaceRow {
  id: string;
  name_fr: string;
  name_ar: string;
  place_type: string;
  is_free: boolean;
  price_amount: string | null;
  price_currency: string | null;
  declared_status: string;
  status_source: string;
  created_at: Date;
  updated_at: Date;
  lat: number;
  lng: number;
}

interface ThirdPartyPlaceSearchRow {
  id: string;
  name_fr: string;
  name_ar: string;
  place_type: string;
  is_free: boolean;
  declared_status: string;
  status_source: string;
  lat: number;
  lng: number;
  distance_meters: number;
  average_rating: number | null;
  review_count: number;
}

/** `ThirdPartyPlace.position` — see PrismaStationRepository's note on Unsupported geography columns. */
@Injectable()
export class PrismaThirdPartyPlaceRepository implements ThirdPartyPlaceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<ThirdPartyPlace | null> {
    const rows = await this.prisma.$queryRaw<ThirdPartyPlaceRow[]>`
      SELECT id, name_fr, name_ar, place_type, is_free, price_amount, price_currency,
             declared_status, status_source, created_at, updated_at,
             ST_Y(position::geometry) AS lat, ST_X(position::geometry) AS lng
      FROM third_party_place
      WHERE id = ${id}::uuid
    `;
    const row = rows[0];
    if (!row) {
      return null;
    }

    const tagRecords = await this.prisma.thirdPartyPlaceTag.findMany({
      where: { thirdPartyPlaceId: id },
      include: { tag: true },
    });

    assertPlaceType(row.place_type);
    assertDeclaredStatus(row.declared_status);
    assertStatusSource(row.status_source);

    return ThirdPartyPlace.restore({
      id: row.id,
      nameFr: row.name_fr,
      nameAr: row.name_ar,
      placeType: row.place_type,
      position: GeoPosition.of(row.lat, row.lng),
      isFree: row.is_free,
      price: !row.is_free && row.price_amount ? Money.fromDecimalString(row.price_amount, row.price_currency ?? 'DZD') : null,
      declaredStatus: row.declared_status,
      statusSource: row.status_source,
      tags: tagRecords.map((record) => {
        assertTagCode(record.tag.code);
        return record.tag.code;
      }),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    });
  }

  /**
   * ST_DWithin nearby search (FR-MAP-01/02/04/05). `rahati_unit` never
   * matches (station-only category, ADR-0021) — if it's the only selected
   * type, the WHERE clause is unsatisfiable and the query correctly returns
   * no rows without a special-cased short-circuit.
   */
  async searchNearby(criteria: ThirdPartyPlaceSearchCriteria): Promise<ThirdPartyPlaceSearchPage> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${criteria.position.lng}, ${criteria.position.lat}), 4326)::geography`;

    const conditions: Prisma.Sql[] = [
      Prisma.sql`ST_DWithin(p.position, ${point}, ${criteria.radiusMeters})`,
      this.buildTypeFilterSql(criteria.types),
    ];
    if (criteria.query) {
      conditions.push(Prisma.sql`(p.name_fr ILIKE ${'%' + criteria.query + '%'} OR p.name_ar ILIKE ${'%' + criteria.query + '%'})`);
    }

    const decodedCursor = criteria.cursor ? decodeSearchCursor(criteria.cursor) : null;
    if (decodedCursor) {
      conditions.push(Prisma.sql`(
        ST_Distance(p.position, ${point}) > ${decodedCursor.distanceMeters}
        OR (ST_Distance(p.position, ${point}) = ${decodedCursor.distanceMeters} AND p.id > ${decodedCursor.id}::uuid)
      )`);
    }

    const rows = await this.prisma.$queryRaw<ThirdPartyPlaceSearchRow[]>`
      SELECT p.id, p.name_fr, p.name_ar, p.place_type, p.is_free, p.declared_status, p.status_source,
             ST_Y(p.position::geometry) AS lat, ST_X(p.position::geometry) AS lng,
             ST_Distance(p.position, ${point}) AS distance_meters,
             AVG(r.rating)::float AS average_rating,
             COUNT(r.id)::int AS review_count
      FROM third_party_place p
      LEFT JOIN review r ON r.third_party_place_id = p.id
      WHERE ${Prisma.join(conditions, ' AND ')}
      GROUP BY p.id
      ORDER BY distance_meters ASC, p.id ASC
      LIMIT ${criteria.limit + 1}
    `;

    const hasMore = rows.length > criteria.limit;
    const page = hasMore ? rows.slice(0, criteria.limit) : rows;
    const tagsByPlaceId = await this.fetchTagsByPlaceId(page.map((row) => row.id));

    return {
      data: page.map((row) => this.searchRowToResult(row, tagsByPlaceId.get(row.id) ?? [])),
      nextCursor: hasMore
        ? encodeSearchCursor({ distanceMeters: page[page.length - 1].distance_meters, id: page[page.length - 1].id })
        : null,
    };
  }

  private buildTypeFilterSql(types: PlaceFilterType[]): Prisma.Sql {
    if (types.length === 0) {
      return Prisma.sql`TRUE`;
    }
    const parts = types.map((type) => {
      switch (type) {
        case 'rahati_unit':
          return Prisma.sql`FALSE`; // station-only category — no ThirdPartyPlace ever matches
        case 'free_wc':
          return Prisma.sql`p.is_free`;
        case 'paid_wc':
          return Prisma.sql`NOT p.is_free`;
        case 'slatoki':
          return Prisma.sql`EXISTS (
            SELECT 1 FROM third_party_place_tag tpt
            JOIN tag t ON t.id = tpt.tag_id
            WHERE tpt.third_party_place_id = p.id AND t.code = 'women_confirmed'
          )`;
      }
    });
    return Prisma.sql`(${Prisma.join(parts, ' OR ')})`;
  }

  private async fetchTagsByPlaceId(placeIds: string[]): Promise<Map<string, TagCode[]>> {
    if (placeIds.length === 0) {
      return new Map();
    }
    const records = await this.prisma.thirdPartyPlaceTag.findMany({
      where: { thirdPartyPlaceId: { in: placeIds } },
      include: { tag: true },
    });
    const byPlaceId = new Map<string, TagCode[]>();
    for (const record of records) {
      assertTagCode(record.tag.code);
      const existing = byPlaceId.get(record.thirdPartyPlaceId) ?? [];
      existing.push(record.tag.code);
      byPlaceId.set(record.thirdPartyPlaceId, existing);
    }
    return byPlaceId;
  }

  private searchRowToResult(row: ThirdPartyPlaceSearchRow, tags: TagCode[]): ThirdPartyPlaceSearchResult {
    assertPlaceType(row.place_type);
    assertDeclaredStatus(row.declared_status);
    assertStatusSource(row.status_source);
    return {
      id: row.id,
      nameFr: row.name_fr,
      nameAr: row.name_ar,
      placeType: row.place_type,
      position: GeoPosition.of(row.lat, row.lng),
      distanceMeters: row.distance_meters,
      isFree: row.is_free,
      declaredStatus: row.declared_status,
      statusSource: row.status_source,
      tags,
      averageRating: row.average_rating,
      reviewCount: row.review_count,
    };
  }
}
