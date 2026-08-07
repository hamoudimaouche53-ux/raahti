import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { RouteQueryService } from '../src/modules/routing/application/route-query.service';
import { RouteProviderUnavailableException } from '../src/modules/routing/application/route-provider-unavailable.exception';
import { ROUTE_PROVIDER, RouteProvider } from '../src/modules/routing/domain/ports/route-provider';
import { Route } from '../src/modules/routing/domain/route';
import { RoutingController } from '../src/modules/routing/interface/controllers/routing.controller';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';
import { RateLimitGuard } from '../src/platform/http/rate-limit.guard';

class FakeRouteProvider implements RouteProvider {
  constructor(private readonly route: Route | null) {}

  async getWalkingRoute(): Promise<Route | null> {
    return this.route;
  }
}

class ThrowingRouteProvider implements RouteProvider {
  constructor(private readonly error: Error) {}

  async getWalkingRoute(): Promise<Route | null> {
    throw this.error;
  }
}

async function buildApp(routeProvider: RouteProvider): Promise<INestApplication> {
  // Real RateLimitGuard, not stubbed — each test builds its own fresh `app`
  // (and therefore a fresh, empty bucket Map), and every existing test below
  // sends at most one request, well under any tier's limit, so this doesn't
  // affect them. The dedicated rate-limiting describe block further down
  // exercises the guard's actual 429 behavior.
  const moduleRef = await Test.createTestingModule({
    controllers: [RoutingController],
    providers: [RouteQueryService, RateLimitGuard, { provide: ROUTE_PROVIDER, useValue: routeProvider }],
  }).compile();

  const app = moduleRef.createNestApplication();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  app.useGlobalFilters(new HttpExceptionFilter());
  await app.init();
  return app;
}

describe('GET /routes/walking (e2e)', () => {
  it('returns a route with no authentication required', async () => {
    const route: Route = { polyline: 'a~l~Fjk~uOwHJ', distanceMeters: 500, durationSeconds: 360 };
    const app = await buildApp(new FakeRouteProvider(route));

    const res = await request(app.getHttpServer())
      .get('/routes/walking')
      .query({ originLat: 36.75, originLng: 3.05, destLat: 36.751, destLng: 3.051 })
      .expect(200);

    expect(res.body).toEqual(route);
    await app.close();
  });

  it('returns 404 when no route was found', async () => {
    const app = await buildApp(new FakeRouteProvider(null));

    await request(app.getHttpServer())
      .get('/routes/walking')
      .query({ originLat: 36.75, originLng: 3.05, destLat: 36.751, destLng: 3.051 })
      .expect(404);

    await app.close();
  });

  it('rejects a missing coordinate with 400', async () => {
    const app = await buildApp(new FakeRouteProvider(null));

    await request(app.getHttpServer())
      .get('/routes/walking')
      .query({ originLat: 36.75, originLng: 3.05, destLat: 36.751 })
      .expect(400);

    await app.close();
  });

  it('rejects an out-of-range latitude with 400', async () => {
    const app = await buildApp(new FakeRouteProvider(null));

    await request(app.getHttpServer())
      .get('/routes/walking')
      .query({ originLat: 999, originLng: 3.05, destLat: 36.751, destLng: 3.051 })
      .expect(400);

    await app.close();
  });

  it('maps a route-provider failure to 502 with a sanitized detail — no internal/network '
    + 'details reach the client', async () => {
    const app = await buildApp(
      new ThrowingRouteProvider(new RouteProviderUnavailableException()),
    );

    const res = await request(app.getHttpServer())
      .get('/routes/walking')
      .query({ originLat: 36.75, originLng: 3.05, destLat: 36.751, destLng: 3.051 })
      .expect(502);

    expect(res.body).toMatchObject({
      status: 502,
      code: 'ROUTE_PROVIDER_UNAVAILABLE',
      detail: 'The routing provider is temporarily unavailable. Please try again later.',
    });
    expect(JSON.stringify(res.body)).not.toContain('ENOTFOUND');
    expect(JSON.stringify(res.body)).not.toContain('osrm');

    await app.close();
  });
});

describe('GET /routes/walking rate limiting (e2e)', () => {
  it('uses the stricter routing tier (20/min), not the general public tier '
    + '(60/min) — returns 429 with Retry-After well before 60 requests', async () => {
    const route: Route = { polyline: 'a~l~Fjk~uOwHJ', distanceMeters: 500, durationSeconds: 360 };
    const app = await buildApp(new FakeRouteProvider(route));
    const server = app.getHttpServer();
    const STRICT_LIMIT = 20;

    for (let i = 0; i < STRICT_LIMIT; i++) {
      await request(server)
        .get('/routes/walking')
        .query({ originLat: 36.75, originLng: 3.05, destLat: 36.751, destLng: 3.051 })
        .expect(200);
    }

    const res = await request(server)
      .get('/routes/walking')
      .query({ originLat: 36.75, originLng: 3.05, destLat: 36.751, destLng: 3.051 })
      .expect(429);

    expect(res.body).toEqual(expect.objectContaining({ code: 'RATE_LIMIT_EXCEEDED', status: 429 }));
    expect(res.headers['retry-after']).toBeDefined();
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);

    await app.close();
  });
});
