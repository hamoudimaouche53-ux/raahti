import { Module } from '@nestjs/common';
import { IdentityModule } from '../identity/identity.module';
import { StationNetworkModule } from '../station-network/station-network.module';
import { EmergencyQueryService } from './application/emergency-query.service';
import { EmergencyController } from './interface/controllers/emergency.controller';

/**
 * Emergency Mode bounded context (Domain Model §7) — application/interface
 * only, no owned domain aggregate (besides the stateless EmergencyDiscountPolicy
 * domain service), no Prisma models, no repository (module-dependency-diagram.md
 * §5 rule 3). Imports IdentityModule/StationNetworkModule only to reach their
 * exported *QueryService via NestJS DI — the read-only dependency the matrix
 * grants specifically to Emergency (§3: `Emergency -.->|read| Identity`,
 * `Emergency -.->|read| StationNetwork`).
 */
@Module({
  imports: [IdentityModule, StationNetworkModule],
  controllers: [EmergencyController],
  providers: [EmergencyQueryService],
})
export class EmergencyModule {}
