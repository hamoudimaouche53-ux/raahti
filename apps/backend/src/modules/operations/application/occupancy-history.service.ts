import { Inject, Injectable } from '@nestjs/common';
import { StationQueryService } from '../../station-network/application/station-query.service';
import { TELEMETRY_READING_REPOSITORY, TelemetryReadingRepository } from '../domain/ports/telemetry-reading.repository';

export interface OccupancyHistoryPoint {
  timestamp: Date;
  occupiedCabinCount: number;
}

export interface OccupancyHistoryResult {
  stationId: string;
  points: OccupancyHistoryPoint[];
}

/**
 * GET /ops/stations/{stationId}/occupancy-history (FR-OPS-04). Backed by
 * `telemetry_reading`'s `occupancy` metric (ADR-0013). Each such reading's
 * `value` is interpreted as an already-computed count of occupied cabins at
 * that station at that instant — a station-level rollup (`cabin_id IS NULL`)
 * a future IoT ingestion pipeline would write, not a raw per-cabin
 * door-sensor event fanned out here. Neither the ERD nor domain-model.md
 * specifies the `occupancy` metric's payload shape/granularity beyond its
 * name — flagged judgment call, necessary because `OccupancyHistorySeries`
 * needs one station-level series, not a per-cabin one.
 *
 * No telemetry ingestion write path exists in this pass (IoT Platform is
 * Master Roadmap Phase 9, entirely out of scope) — this query is real and
 * correct, but `telemetry_reading` will be empty until Phase 9. Same
 * treatment as Facilities' PostGIS queries validated with no live database.
 */
@Injectable()
export class OccupancyHistoryService {
  constructor(
    private readonly stationQueryService: StationQueryService,
    @Inject(TELEMETRY_READING_REPOSITORY) private readonly telemetryReadingRepository: TelemetryReadingRepository,
  ) {}

  async getHistory(stationId: string, from: Date, to: Date): Promise<OccupancyHistoryResult> {
    // Propagates StationQueryService's own StationNotFoundException (404) for
    // an unknown station — no need to import that exception type here; the
    // global HttpExceptionFilter maps any DomainException by its own status.
    await this.stationQueryService.getById(stationId);

    const series = await this.telemetryReadingRepository.findSeries(stationId, 'occupancy', from, to);
    return {
      stationId,
      points: series.map((point) => ({ timestamp: point.recordedAt, occupiedCabinCount: point.value })),
    };
  }
}
