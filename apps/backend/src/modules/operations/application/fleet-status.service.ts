import { Inject, Injectable } from '@nestjs/common';
import { Money } from '../../../shared-kernel';
import { StationQueryService } from '../../station-network/application/station-query.service';
import { ALERT_REPOSITORY, AlertRepository } from '../domain/ports/alert.repository';
import { TELEMETRY_READING_REPOSITORY, TelemetryReadingRepository } from '../domain/ports/telemetry-reading.repository';

export interface FleetCabinStatus {
  id: string;
  code: string;
  type: string;
  occupancyStatus: string;
  isPaid: boolean;
  price: Money | null;
}

export interface StationFleetStatus {
  stationId: string;
  batteryLevel: number | null;
  waterLevel: number | null;
  cabins: FleetCabinStatus[];
  activeAlertCount: number;
}

/**
 * GET /ops/stations (FR-OPS-01) — "consolidated view of all network
 * stations: battery status, water level, per-cabin occupancy, active
 * alerts" (SRS §5). Orchestrates three sources: Station Network (via its
 * exported StationQueryService — the sanctioned `Ops -> StationNet` edge),
 * this module's own Alert aggregate, and telemetry_reading (battery/water).
 *
 * `site_scope`-based filtering (openapi.yaml: "scoped by site_scope") is
 * NOT implemented — flagged, not silently dropped. Neither the ERD nor
 * schema.prisma defines any Site entity or `station.site_id`/`site` column;
 * `user_role.site_scope` (ERD §3.7) is a free-form string with no
 * documented linkage to a Station-side column at all. Identity's own
 * `SiteScopeGuard` only compares against a literal `:siteId` route param
 * (none of the /ops/stations routes have one), so it is a structural no-op
 * here too. Returns the full fleet, unscoped, until a Site concept exists.
 */
@Injectable()
export class FleetStatusService {
  constructor(
    private readonly stationQueryService: StationQueryService,
    @Inject(ALERT_REPOSITORY) private readonly alertRepository: AlertRepository,
    @Inject(TELEMETRY_READING_REPOSITORY) private readonly telemetryReadingRepository: TelemetryReadingRepository,
  ) {}

  async getFleetStatus(): Promise<StationFleetStatus[]> {
    const [stations, activeAlertCounts] = await Promise.all([
      this.stationQueryService.listAllForFleetView(),
      this.alertRepository.countActiveGroupedByStation(),
    ]);

    return Promise.all(
      stations.map(async (station) => {
        const [batteryLevel, waterLevel] = await Promise.all([
          this.telemetryReadingRepository.findLatestValue(station.stationId, 'battery_level'),
          this.telemetryReadingRepository.findLatestValue(station.stationId, 'water_level'),
        ]);
        return {
          stationId: station.stationId,
          batteryLevel,
          waterLevel,
          cabins: station.cabins,
          activeAlertCount: activeAlertCounts.get(station.stationId) ?? 0,
        };
      }),
    );
  }
}
