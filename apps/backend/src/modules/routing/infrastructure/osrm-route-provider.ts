import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GeoPosition } from '../../../shared-kernel';
import { AppConfig } from '../../../platform/config/configuration';
import { RouteProvider } from '../domain/ports/route-provider';
import { Route } from '../domain/route';
import { RouteProviderUnavailableException } from '../application/route-provider-unavailable.exception';

/** Exported for tests — the exact duration `AbortSignal.timeout` is configured with. */
export const REQUEST_TIMEOUT_MS = 10_000;

interface OsrmRouteResponse {
  code: string;
  routes?: Array<{ geometry: string; distance: number; duration: number }>;
}

/**
 * [RouteProvider] backed by an OSRM HTTP API (foot profile), reached at
 * `${AppConfig.osrmBaseUrl}` (configurable — .env.example — never hard-coded,
 * so a self-hosted OSRM instance can replace the public demo server with no
 * code change). The only class in this module that knows OSRM's request/
 * response shape — [RouteQueryService] and everything above it see only the
 * normalized [Route] this returns.
 *
 * Uses the platform's built-in `fetch` (Node 18+, no new HTTP-client
 * dependency needed — no other backend module makes an outbound HTTP call
 * today, so there was no existing client wrapper to reuse).
 */
@Injectable()
export class OsrmRouteProvider implements RouteProvider {
  private readonly baseUrl: string;
  private readonly logger = new Logger(OsrmRouteProvider.name);

  constructor(configService: ConfigService) {
    this.baseUrl = configService.get<AppConfig>('app')!.osrmBaseUrl;
  }

  async getWalkingRoute(origin: GeoPosition, destination: GeoPosition): Promise<Route | null> {
    // OSRM's coordinate order is lng,lat (api-architecture.md §4 GeoJSON convention).
    const coordinates = `${origin.lng},${origin.lat};${destination.lng},${destination.lat}`;
    const url = `${this.baseUrl}/route/v1/foot/${coordinates}?overview=full&geometries=polyline`;

    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
    } catch (error) {
      // Logged server-side only, and deliberately without `coordinates`/`url` (which embed the
      // caller's lat/lng) — only the configured host and the underlying error are diagnostic-useful.
      // `RouteProviderUnavailableException` carries none of this to the client (see its own doc
      // comment) — `HttpExceptionFilter` forwards a `DomainException`'s message to the client verbatim.
      this.logger.error(`OSRM request to ${this.baseUrl} failed: ${(error as Error).message}`, (error as Error).stack);
      throw new RouteProviderUnavailableException();
    }

    if (!response.ok) {
      this.logger.error(`OSRM at ${this.baseUrl} returned HTTP ${response.status}.`);
      throw new RouteProviderUnavailableException();
    }

    const body = (await response.json()) as OsrmRouteResponse;
    // OSRM's own "no route" outcome (e.g. NoRoute/NoSegment) — a normal
    // negative result, not a provider failure, so this resolves null rather
    // than throwing (RouteQueryService turns that into RouteNotFoundException).
    if (body.code !== 'Ok' || !body.routes || body.routes.length === 0) {
      return null;
    }

    const [best] = body.routes;
    return {
      polyline: best.geometry,
      distanceMeters: best.distance,
      durationSeconds: best.duration,
    };
  }
}
