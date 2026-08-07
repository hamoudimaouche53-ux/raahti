import { GeoPosition } from '../../../../shared-kernel';
import { Route } from '../route';

export const ROUTE_PROVIDER = Symbol('ROUTE_PROVIDER');

/**
 * Port for a walking-directions engine. [OsrmRouteProvider] is the only
 * implementation today; the token/interface split is what lets a future
 * provider replace it (routing.module.ts's single wiring point) without any
 * change to [RouteQueryService] or the interface/ layer above it.
 */
export interface RouteProvider {
  /** Resolves `null` (not throws) when the provider found no walkable route
   * between the two points — a normal, expected outcome, distinct from the
   * provider being unreachable/erroring (see [RouteProviderUnavailableException]). */
  getWalkingRoute(origin: GeoPosition, destination: GeoPosition): Promise<Route | null>;
}
