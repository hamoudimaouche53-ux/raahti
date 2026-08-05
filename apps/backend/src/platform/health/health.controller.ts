import { Controller, Get } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { HealthCheck, HealthCheckService, PrismaHealthIndicator } from '@nestjs/terminus';
import { Public } from '../auth';
import { PrismaService } from '../database/prisma.service';

/**
 * Operational liveness/readiness endpoint — internal, not part of the public client
 * contract (api-architecture.md §11 precedent: internal integration contracts are
 * documented outside openapi.yaml, not added to the versioned API surface).
 *
 * `@Public()` — found missing during Release Validation (docs/phase-5-release-validation-report.md):
 * JwtAuthGuard is wired globally (identity.module.ts, APP_GUARD), so without
 * this decorator the health check itself required a bearer token, which
 * defeats its purpose — infrastructure liveness/readiness probes (load
 * balancers, container orchestrators, uptime monitors) never carry an
 * end-user JWT. Bug, not a design choice; fixed here.
 */
@Public()
@ApiExcludeController()
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly prismaIndicator: PrismaHealthIndicator,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([() => this.prismaIndicator.pingCheck('database', this.prisma)]);
  }
}
