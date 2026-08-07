import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { RouteQueryService } from '../src/modules/routing/application/route-query.service';
import { RouteProviderUnavailableException } from '../src/modules/routing/application/route-provider-unavailable.exception';
import { ROUTE_PROVIDER, RouteProvider } from '../src/modules/routing/domain/ports/route-provider';
import { Route } from '../src/modules/routing/domain/route';
import { RoutingController } from '../src/modules/routing/interface/controllers/routing.controller';
import { HttpExceptionFilter } from '../src/platform/http/http-exception.filter';

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
  const moduleRef = await Test.createTestingModule({
    controllers: [RoutingController],
    providers: [RouteQueryService, { provide: ROUTE_PROVIDER, useValue: routeProvider }],
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
