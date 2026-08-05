import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GeoPosition } from '../../../../shared-kernel';
import { Public } from '../../../../platform/auth';
import { PlaceFilterType } from '../../place-filter-type';
import { PlacesQueryService } from '../../places-query.service';
import { NearbyPlacesQueryDto } from '../dto/nearby-places-query.dto';
import { PlaceSummaryDto } from '../dto/place-summary.dto';

/**
 * GET /places/nearby — openapi.yaml tag Places, security: [] (FR-USR-01 guest
 * usage). Composition-layer controller (ADR-0029) — not owned by either
 * StationNetworkModule or ThirdPartyPlacesModule.
 */
@ApiTags('Places')
@Controller('places')
export class PlacesController {
  constructor(private readonly placesQueryService: PlacesQueryService) {}

  @Public()
  @Get('nearby')
  async searchNearby(@Query() query: NearbyPlacesQueryDto): Promise<{ data: PlaceSummaryDto[]; nextCursor: string | null }> {
    const page = await this.placesQueryService.searchNearby({
      position: GeoPosition.of(query.lat, query.lng),
      radiusMeters: query.radiusMeters,
      types: query.type as PlaceFilterType[],
      query: query.q,
      cursor: query.cursor ?? null,
      limit: query.limit,
    });
    return {
      data: page.data.map((item) => PlaceSummaryDto.fromSearchItem(item)),
      nextCursor: page.nextCursor,
    };
  }
}
