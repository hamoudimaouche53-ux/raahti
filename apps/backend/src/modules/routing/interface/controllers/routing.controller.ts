import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GeoPosition } from '../../../../shared-kernel';
import { Public } from '../../../../platform/auth';
import { RouteQueryService } from '../../application/route-query.service';
import { RouteQueryDto } from '../dto/route-query.dto';
import { RouteDto } from '../dto/route.dto';

/**
 * GET /routes/walking — openapi.yaml tag Routing, security: [] (same
 * guest-usable reasoning as GET /places/nearby — Directions is available
 * from the Place Detail sheet before sign-in, FR-USR-01).
 */
@ApiTags('Routing')
@Controller('routes')
export class RoutingController {
  constructor(private readonly routeQueryService: RouteQueryService) {}

  @Public()
  @Get('walking')
  async walking(@Query() query: RouteQueryDto): Promise<RouteDto> {
    const route = await this.routeQueryService.getWalkingRoute({
      origin: GeoPosition.of(query.originLat, query.originLng),
      destination: GeoPosition.of(query.destLat, query.destLng),
    });
    return RouteDto.fromRoute(route);
  }
}
