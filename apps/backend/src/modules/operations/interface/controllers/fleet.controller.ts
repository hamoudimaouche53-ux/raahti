import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RequireMfa, Roles } from '../../../../platform/auth';
import { FleetStatusService } from '../../application/fleet-status.service';
import { OccupancyHistoryService } from '../../application/occupancy-history.service';
import { OccupancyHistoryQueryDto, OccupancyHistorySeriesDto } from '../dto/occupancy-history.dto';
import { StationFleetStatusDto } from '../dto/fleet-status.dto';

/**
 * GET /ops/stations, GET /ops/stations/{stationId}/occupancy-history —
 * openapi.yaml tag Operations (FR-OPS-01, FR-OPS-04). `role=operateur` +
 * MFA per openapi.yaml's explicit description on GET /ops/stations and
 * Security Architecture §1 (all /ops/* routes, role != usager).
 */
@ApiTags('Operations')
@ApiBearerAuth('bearerAuth')
@Roles('operateur')
@RequireMfa()
@Controller('ops/stations')
export class FleetController {
  constructor(
    private readonly fleetStatusService: FleetStatusService,
    private readonly occupancyHistoryService: OccupancyHistoryService,
  ) {}

  @Get()
  async list(): Promise<{ data: StationFleetStatusDto[] }> {
    const fleet = await this.fleetStatusService.getFleetStatus();
    return { data: fleet.map((status) => StationFleetStatusDto.fromDomain(status)) };
  }

  @Get(':stationId/occupancy-history')
  async occupancyHistory(
    @Param('stationId', ParseUUIDPipe) stationId: string,
    @Query() query: OccupancyHistoryQueryDto,
  ): Promise<OccupancyHistorySeriesDto> {
    const history = await this.occupancyHistoryService.getHistory(stationId, new Date(query.from), new Date(query.to));
    return OccupancyHistorySeriesDto.fromDomain(history);
  }
}
