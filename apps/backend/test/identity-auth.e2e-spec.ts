import { Controller, Get, INestApplication, UnauthorizedException } from '@nestjs/common';
import { APP_GUARD, Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { JWT_VERIFIER, JwtVerifier } from '../src/modules/identity/infrastructure/auth/jwt-verifier.port';
import { Public, RequireMfa, Roles } from '../src/platform/auth';
import { JwtAuthGuard } from '../src/modules/identity/interface/guards/jwt-auth.guard';
import { RequireMfaGuard } from '../src/modules/identity/interface/guards/require-mfa.guard';
import { RolesGuard } from '../src/modules/identity/interface/guards/roles.guard';
import { SiteScopeGuard } from '../src/modules/identity/interface/guards/site-scope.guard';

/**
 * End-to-end guard-stack test: exercises JwtAuthGuard + RolesGuard + SiteScopeGuard +
 * RequireMfaGuard together over real HTTP requests, without a live database — a fake
 * JwtVerifier stands in for Supabase Auth so this test has no external dependency,
 * mirroring how AppModule wires the same four guards as APP_GUARD (IdentityModule).
 */
@Controller('test')
class TestController {
  @Get('public')
  @Public()
  publicRoute() {
    return { ok: true };
  }

  @Get('protected')
  protectedRoute() {
    return { ok: true };
  }

  @Get('admin-only')
  @Roles('admin')
  adminOnlyRoute() {
    return { ok: true };
  }

  @Get('sites/:siteId/ops')
  @Roles('operateur', 'admin')
  siteScopedRoute() {
    return { ok: true };
  }

  @Get('dashboard')
  @Roles('operateur')
  @RequireMfa()
  dashboardRoute() {
    return { ok: true };
  }
}

class FakeJwtVerifier implements JwtVerifier {
  async verify(token: string) {
    const claims: Record<string, unknown> = {
      'valid-usager': { sub: 'u1', role: 'usager', exp: 0, iat: 0 },
      'valid-admin': { sub: 'u2', role: 'admin', exp: 0, iat: 0 },
      'valid-operateur-site-1': { sub: 'u3', role: 'operateur', site_scope: 'site-1', exp: 0, iat: 0 },
      'valid-operateur-site-1-mfa': {
        sub: 'u4',
        role: 'operateur',
        site_scope: 'site-1',
        aal: 'aal2',
        exp: 0,
        iat: 0,
      },
    };
    const found = claims[token];
    if (!found) {
      throw new UnauthorizedException('invalid token');
    }
    return found as any;
  }
}

describe('Identity guard stack (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [TestController],
      providers: [
        Reflector,
        { provide: JWT_VERIFIER, useClass: FakeJwtVerifier },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_GUARD, useClass: RolesGuard },
        { provide: APP_GUARD, useClass: SiteScopeGuard },
        { provide: APP_GUARD, useClass: RequireMfaGuard },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('allows an unauthenticated request to a @Public() route', async () => {
    await request(app.getHttpServer()).get('/test/public').expect(200);
  });

  it('rejects an unauthenticated request to a protected route with 401', async () => {
    await request(app.getHttpServer()).get('/test/protected').expect(401);
  });

  it('allows an authenticated request to a protected route with no role requirement', async () => {
    await request(app.getHttpServer())
      .get('/test/protected')
      .set('Authorization', 'Bearer valid-usager')
      .expect(200);
  });

  it('rejects a valid token with 401 if it does not match any known token (bad signature)', async () => {
    await request(app.getHttpServer()).get('/test/protected').set('Authorization', 'Bearer garbage').expect(401);
  });

  it('rejects an authenticated usager on an admin-only route with 403', async () => {
    await request(app.getHttpServer())
      .get('/test/admin-only')
      .set('Authorization', 'Bearer valid-usager')
      .expect(403);
  });

  it('allows an admin on an admin-only route', async () => {
    await request(app.getHttpServer()).get('/test/admin-only').set('Authorization', 'Bearer valid-admin').expect(200);
  });

  it('allows an operateur scoped to the requested site', async () => {
    await request(app.getHttpServer())
      .get('/test/sites/site-1/ops')
      .set('Authorization', 'Bearer valid-operateur-site-1')
      .expect(200);
  });

  it('rejects an operateur scoped to a different site with 403', async () => {
    await request(app.getHttpServer())
      .get('/test/sites/site-2/ops')
      .set('Authorization', 'Bearer valid-operateur-site-1')
      .expect(403);
  });

  it('rejects an operateur without MFA on a dashboard route with 403', async () => {
    await request(app.getHttpServer())
      .get('/test/dashboard')
      .set('Authorization', 'Bearer valid-operateur-site-1')
      .expect(403);
  });

  it('allows an operateur with MFA (aal2) on a dashboard route', async () => {
    await request(app.getHttpServer())
      .get('/test/dashboard')
      .set('Authorization', 'Bearer valid-operateur-site-1-mfa')
      .expect(200);
  });
});
