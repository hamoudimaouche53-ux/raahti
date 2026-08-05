import { Module } from '@nestjs/common';
import { StationNetworkModule } from '../station-network/station-network.module';
import { AlertService } from './application/alert.service';
import { FleetStatusService } from './application/fleet-status.service';
import { MaintenanceInterventionService } from './application/maintenance-intervention.service';
import { OccupancyHistoryService } from './application/occupancy-history.service';
import { ALERT_REPOSITORY } from './domain/ports/alert.repository';
import { MAINTENANCE_INTERVENTION_REPOSITORY } from './domain/ports/maintenance-intervention.repository';
import { TELEMETRY_READING_REPOSITORY } from './domain/ports/telemetry-reading.repository';
import { PrismaAlertRepository } from './infrastructure/prisma-alert.repository';
import { PrismaMaintenanceInterventionRepository } from './infrastructure/prisma-maintenance-intervention.repository';
import { PrismaTelemetryReadingRepository } from './infrastructure/prisma-telemetry-reading.repository';
import { AlertsController } from './interface/controllers/alerts.controller';
import { FleetController } from './interface/controllers/fleet.controller';
import { MaintenanceInterventionsController } from './interface/controllers/maintenance-interventions.controller';

/**
 * Operations bounded context (Domain Model §10) — the last mandatory module
 * of Phase 4 Implementation Plan §6. Imports StationNetworkModule only to
 * reach its exported StationQueryService — the sanctioned read edge
 * module-dependency-diagram.md §3 grants Operations specifically
 * (`Ops -> StationNet`, plain ✔), used for fleet-wide station/cabin data
 * (FR-OPS-01) and station-existence checks (FR-OPS-04). No other module may
 * depend on operations/ (see eslint.config.mjs — matrix grants no incoming
 * edges except Analytics's, which is out of scope for this pass).
 */
@Module({
  imports: [StationNetworkModule],
  controllers: [AlertsController, MaintenanceInterventionsController, FleetController],
  providers: [
    { provide: ALERT_REPOSITORY, useClass: PrismaAlertRepository },
    { provide: MAINTENANCE_INTERVENTION_REPOSITORY, useClass: PrismaMaintenanceInterventionRepository },
    { provide: TELEMETRY_READING_REPOSITORY, useClass: PrismaTelemetryReadingRepository },
    AlertService,
    MaintenanceInterventionService,
    FleetStatusService,
    OccupancyHistoryService,
  ],
})
export class OperationsModule {}
