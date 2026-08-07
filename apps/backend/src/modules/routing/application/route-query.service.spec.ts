import { GeoPosition } from '../../../shared-kernel';
import { RouteProvider } from '../domain/ports/route-provider';
import { Route } from '../domain/route';
import { RouteNotFoundException } from './route-not-found.exception';
import { RouteQueryService } from './route-query.service';

const ORIGIN = GeoPosition.of(36.75, 3.05);
const DESTINATION = GeoPosition.of(36.751, 3.051);

function aRoute(overrides: Partial<Route> = {}): Route {
  return { polyline: 'a~l~Fjk~uOwHJ', distanceMeters: 500, durationSeconds: 360, ...overrides };
}

function createRouteProvider(route: Route | null): jest.Mocked<RouteProvider> {
  return { getWalkingRoute: jest.fn().mockResolvedValue(route) };
}

describe('RouteQueryService', () => {
  it('returns the route unchanged when the provider resolves one', async () => {
    const route = aRoute();
    const routeProvider = createRouteProvider(route);
    const service = new RouteQueryService(routeProvider);

    const result = await service.getWalkingRoute({ origin: ORIGIN, destination: DESTINATION });

    expect(result).toEqual(route);
    expect(routeProvider.getWalkingRoute).toHaveBeenCalledWith(ORIGIN, DESTINATION);
  });

  it('throws RouteNotFoundException when the provider resolves null', async () => {
    const routeProvider = createRouteProvider(null);
    const service = new RouteQueryService(routeProvider);

    await expect(service.getWalkingRoute({ origin: ORIGIN, destination: DESTINATION })).rejects.toThrow(
      RouteNotFoundException,
    );
  });
});
