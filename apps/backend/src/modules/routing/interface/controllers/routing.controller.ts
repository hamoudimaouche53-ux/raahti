import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GeoPosition } from '../../../../shared-kernel';
import { Public } from '../../../../platform/auth';
import { RATE_LIMIT_WINDOW_MS, RateLimit, RateLimitGuard, ROUTING_RATE_LIMIT_PER_MINUTE } from '../../../../platform/http/rate-limit.guard';
import { RouteQueryService } from '../../application/route-query.service';
import { RouteQueryDto } from '../dto/route-query.dto';
import { RouteDto } from '../dto/route.dto';

/**
 * GET /routes/walking — openapi.yaml tag Routing, security: [] (same
 * guest-usable reasoning as GET /places/nearby — Directions is available
 * from the Place Detail sheet before sign-in, FR-USR-01).
 *
 * Rate-limited at the stricter routing tier (api-architecture.md §9), not
 * the general public one — every call proxies a request to OSRM
 * (`OsrmRouteProvider`, the only outbound HTTP call anywhere in this
 * backend), so unbounded traffic here also risks the backend's own IP
 * getting throttled or banned by the upstream routing provider.
 */
@ApiTags('Routing')
@Controller('routes')
export class RoutingController {
  constructor(private readonly routeQueryService: RouteQueryService) {}

  @Public()
  @UseGuards(RateLimitGuard)
  @RateLimit(ROUTING_RATE_LIMIT_PER_MINUTE, RATE_LIMIT_WINDOW_MS)
  @Get('walking')
  async walking(@Query() query: RouteQueryDto): Promise<RouteDto> {
    const route = await this.routeQueryService.getWalkingRoute({
      origin: GeoPosition.of(query.originLat, query.originLng),
      destination: GeoPosition.of(query.destLat, query.destLng),
    });
    return RouteDto.fromRoute(route);
  }
}
