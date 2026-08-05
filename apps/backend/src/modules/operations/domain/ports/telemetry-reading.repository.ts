export const TELEMETRY_READING_REPOSITORY = Symbol('TELEMETRY_READING_REPOSITORY');

export type TelemetryMetric = 'battery_level' | 'water_level' | 'door_sensor' | 'occupancy';

export interface TelemetrySeriesPoint {
  recordedAt: Date;
  value: number;
}

/**
 * Read-only query side of `telemetry_reading` (ERD §3.13), consumed by
 * Operations for FR-OPS-01/FR-OPS-04. No write path exists in this pass —
 * ingestion is Station Network's telemetry Anti-Corruption Layer per the
 * Domain Model §1 context map (`SN -->|ACL| IOT_EXT`), and the IoT Platform
 * that would feed it is Master Roadmap Phase 9, entirely out of scope here.
 * This table is therefore expected to stay empty until Phase 9 — flagged,
 * not silently hidden (see prisma/README.md).
 */
export interface TelemetryReadingRepository {
  /** Latest station-level (cabin_id IS NULL) reading for a metric — GET /ops/stations battery/water level. */
  findLatestValue(stationId: string, metric: TelemetryMetric): Promise<number | null>;
  /** Time-bounded series for a metric — GET /ops/stations/{id}/occupancy-history (FR-OPS-04, ADR-0013). */
  findSeries(stationId: string, metric: TelemetryMetric, from: Date, to: Date): Promise<TelemetrySeriesPoint[]>;
}
