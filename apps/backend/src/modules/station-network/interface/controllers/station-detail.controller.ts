import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { StationQueryService } from '../../application/station-query.service';
import { Public } from '../../../../platform/auth';
import { CabinDto } from '../dto/cabin.dto';
import { StationDetailDto } from '../dto/station-detail.dto';

/** GET /stations/{stationId}(/cabins) — openapi.yaml tag Places, security: [] (FR-USR-01 guest usage). */
@ApiTags('Places')
@Controller('stations')
export class StationDetailController {
  constructor(private readonly stationQueryService: StationQueryService) {}

  @Public()
  @Get(':stationId')
  async getDetail(@Param('stationId', ParseUUIDPipe) stationId: string): Promise<StationDetailDto> {
    const [station, rating] = await Promise.all([
      this.stationQueryService.getById(stationId),
      this.stationQueryService.getRatingAggregate(stationId),
    ]);
    return StationDetailDto.fromDomain(station, rating);
  }

  @Public()
  @Get(':stationId/cabins')
  async listCabins(@Param('stationId', ParseUUIDPipe) stationId: string): Promise<{ data: CabinDto[] }> {
    const station = await this.stationQueryService.getById(stationId);
    return { data: station.cabins.map((cabin) => CabinDto.fromDomain(cabin)) };
  }
}
