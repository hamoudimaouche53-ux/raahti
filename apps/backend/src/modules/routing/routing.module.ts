import { Module } from '@nestjs/common';
import { ROUTE_PROVIDER } from './domain/ports/route-provider';
import { OsrmRouteProvider } from './infrastructure/osrm-route-provider';
import { RouteQueryService } from './application/route-query.service';
import { RoutingController } from './interface/controllers/routing.controller';

/**
 * Routing bounded context — application/infrastructure/interface only, no
 * owned domain aggregate (just the [Route] value shape) and no Prisma
 * models, same "orchestration module" shape as EmergencyModule
 * (module-dependency-diagram.md §5 rule 3). Imports nothing from other
 * feature modules — routing only needs the two coordinates the caller
 * supplies, no cross-module read.
 *
 * [OsrmRouteProvider] is the sole [ROUTE_PROVIDER] binding — swapping
 * routing engines later is a one-line change here.
 */
@Module({
  controllers: [RoutingController],
  providers: [RouteQueryService, { provide: ROUTE_PROVIDER, useClass: OsrmRouteProvider }],
})
export class RoutingModule {}
