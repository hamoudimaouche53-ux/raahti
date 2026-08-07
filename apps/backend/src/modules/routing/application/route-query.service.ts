import { Inject, Injectable } from '@nestjs/common';
import { GeoPosition } from '../../../shared-kernel';
import { ROUTE_PROVIDER, RouteProvider } from '../domain/ports/route-provider';
import { Route } from '../domain/route';
import { RouteNotFoundException } from './route-not-found.exception';

/**
 * Routing bounded context (proxy over an external routing engine) — owns no
 * aggregate, no persisted state, no Prisma models, same "orchestration
 * module" shape as EmergencyModule (module-dependency-diagram.md §5 rule 3).
 * Depends only on [RouteProvider], never on OSRM (or any other engine)
 * directly.
 */
@Injectable()
export class RouteQueryService {
  constructor(@Inject(ROUTE_PROVIDER) private readonly routeProvider: RouteProvider) {}

  /** Backing GET /routes/walking. */
  async getWalkingRoute(params: { origin: GeoPosition; destination: GeoPosition }): Promise<Route> {
    const route = await this.routeProvider.getWalkingRoute(params.origin, params.destination);
    if (!route) {
      throw new RouteNotFoundException();
    }
    return route;
  }
}
