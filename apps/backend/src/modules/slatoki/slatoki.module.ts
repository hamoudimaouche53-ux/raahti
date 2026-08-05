import { Module } from '@nestjs/common';
import { StationNetworkModule } from '../station-network/station-network.module';
import { ThirdPartyPlacesModule } from '../third-party-places/third-party-places.module';
import { SlatokiQueryService } from './application/slatoki-query.service';
import { SlatokiController } from './interface/controllers/slatoki.controller';

/**
 * Slatoki bounded context (Domain Model §4) — application/interface only, no
 * owned domain aggregate, no Prisma models, no repository (module-dependency-
 * diagram.md §2). Imports StationNetworkModule/ThirdPartyPlacesModule only to
 * reach their exported *QueryService via NestJS DI — the read-only dependency
 * the matrix grants specifically to Slatoki (§3: `Slatoki -.->|read| StationNetwork`,
 * `Slatoki -.->|read| ThirdPartyPlaces`).
 */
@Module({
  imports: [StationNetworkModule, ThirdPartyPlacesModule],
  controllers: [SlatokiController],
  providers: [SlatokiQueryService],
})
export class SlatokiModule {}
