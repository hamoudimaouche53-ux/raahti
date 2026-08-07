import { ConfigService } from '@nestjs/config';
import { GeoPosition } from '../../../shared-kernel';
import { RouteProviderUnavailableException } from '../application/route-provider-unavailable.exception';
import { OsrmRouteProvider, REQUEST_TIMEOUT_MS } from './osrm-route-provider';

const ORIGIN = GeoPosition.of(36.75, 3.05);
const DESTINATION = GeoPosition.of(36.751, 3.051);
const BASE_URL = 'https://osrm.example.test';

function createConfigService(osrmBaseUrl: string = BASE_URL): ConfigService {
  return { get: jest.fn().mockReturnValue({ osrmBaseUrl }) } as unknown as ConfigService;
}

function jsonResponse(body: unknown, ok = true, status = 200): Response {
  return { ok, status, json: () => Promise.resolve(body) } as unknown as Response;
}

describe('OsrmRouteProvider', () => {
  let fetchSpy: jest.SpiedFunction<typeof fetch>;

  beforeEach(() => {
    fetchSpy = jest.spyOn(global, 'fetch');
  });

  afterEach(() => {
    fetchSpy.mockRestore();
  });

  it('requests the foot profile with lng,lat coordinate order and a polyline geometry', async () => {
    fetchSpy.mockResolvedValue(
      jsonResponse({ code: 'Ok', routes: [{ geometry: 'a~l~Fjk~uOwHJ', distance: 500, duration: 360 }] }),
    );
    const provider = new OsrmRouteProvider(createConfigService());

    await provider.getWalkingRoute(ORIGIN, DESTINATION);

    const [url] = fetchSpy.mock.calls[0];
    expect(url).toBe(
      `${BASE_URL}/route/v1/foot/${ORIGIN.lng},${ORIGIN.lat};${DESTINATION.lng},${DESTINATION.lat}?overview=full&geometries=polyline`,
    );
  });

  it('normalizes the OSRM response to a Route', async () => {
    fetchSpy.mockResolvedValue(
      jsonResponse({ code: 'Ok', routes: [{ geometry: 'a~l~Fjk~uOwHJ', distance: 500, duration: 360 }] }),
    );
    const provider = new OsrmRouteProvider(createConfigService());

    const route = await provider.getWalkingRoute(ORIGIN, DESTINATION);

    expect(route).toEqual({ polyline: 'a~l~Fjk~uOwHJ', distanceMeters: 500, durationSeconds: 360 });
  });

  it('picks the first route when OSRM returns multiple alternatives', async () => {
    fetchSpy.mockResolvedValue(
      jsonResponse({
        code: 'Ok',
        routes: [
          { geometry: 'first', distance: 500, duration: 360 },
          { geometry: 'second', distance: 900, duration: 700 },
        ],
      }),
    );
    const provider = new OsrmRouteProvider(createConfigService());

    const route = await provider.getWalkingRoute(ORIGIN, DESTINATION);

    expect(route?.polyline).toBe('first');
  });

  it('returns null when OSRM reports no route (code !== Ok)', async () => {
    fetchSpy.mockResolvedValue(jsonResponse({ code: 'NoRoute', routes: [] }));
    const provider = new OsrmRouteProvider(createConfigService());

    const route = await provider.getWalkingRoute(ORIGIN, DESTINATION);

    expect(route).toBeNull();
  });

  it('returns null when OSRM reports Ok but an empty routes array', async () => {
    fetchSpy.mockResolvedValue(jsonResponse({ code: 'Ok', routes: [] }));
    const provider = new OsrmRouteProvider(createConfigService());

    const route = await provider.getWalkingRoute(ORIGIN, DESTINATION);

    expect(route).toBeNull();
  });

  it('throws RouteProviderUnavailableException on a non-2xx HTTP response', async () => {
    fetchSpy.mockResolvedValue(jsonResponse({}, false, 503));
    const provider = new OsrmRouteProvider(createConfigService());

    await expect(provider.getWalkingRoute(ORIGIN, DESTINATION)).rejects.toThrow(RouteProviderUnavailableException);
  });

  it('throws RouteProviderUnavailableException when the network call itself rejects', async () => {
    fetchSpy.mockRejectedValue(new Error('network unreachable'));
    const provider = new OsrmRouteProvider(createConfigService());

    await expect(provider.getWalkingRoute(ORIGIN, DESTINATION)).rejects.toThrow(RouteProviderUnavailableException);
  });

  describe('timeout', () => {
    it('configures fetch with an AbortSignal timing out after REQUEST_TIMEOUT_MS', async () => {
      const timeoutSpy = jest.spyOn(AbortSignal, 'timeout');
      fetchSpy.mockResolvedValue(jsonResponse({ code: 'Ok', routes: [{ geometry: 'a', distance: 1, duration: 1 }] }));
      const provider = new OsrmRouteProvider(createConfigService());

      await provider.getWalkingRoute(ORIGIN, DESTINATION);

      expect(timeoutSpy).toHaveBeenCalledWith(REQUEST_TIMEOUT_MS);
      const [, init] = fetchSpy.mock.calls[0];
      expect(init?.signal).toBeInstanceOf(AbortSignal);
      timeoutSpy.mockRestore();
    });

    it('throws RouteProviderUnavailableException when the request is aborted by the timeout '
      + '(the same rejection shape AbortSignal.timeout produces)', async () => {
      fetchSpy.mockRejectedValue(new DOMException('The operation was aborted due to timeout', 'TimeoutError'));
      const provider = new OsrmRouteProvider(createConfigService());

      await expect(provider.getWalkingRoute(ORIGIN, DESTINATION)).rejects.toThrow(RouteProviderUnavailableException);
    });
  });

  describe('error message sanitization (no internal-details leak)', () => {
    it('never includes the raw underlying error message when the network call rejects', async () => {
      fetchSpy.mockRejectedValue(new Error('getaddrinfo ENOTFOUND internal-osrm.private.example.test'));
      const provider = new OsrmRouteProvider(createConfigService());

      await expect(provider.getWalkingRoute(ORIGIN, DESTINATION)).rejects.toMatchObject({
        message: 'The routing provider is temporarily unavailable. Please try again later.',
      });
    });

    it('never includes the upstream HTTP status detail or host when OSRM answers with a non-2xx', async () => {
      fetchSpy.mockResolvedValue(jsonResponse({}, false, 503));
      const provider = new OsrmRouteProvider(createConfigService());

      await expect(provider.getWalkingRoute(ORIGIN, DESTINATION)).rejects.toMatchObject({
        message: 'The routing provider is temporarily unavailable. Please try again later.',
      });
    });
  });
});
