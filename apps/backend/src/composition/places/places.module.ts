import { Module } from '@nestjs/common';
import { StationNetworkModule } from '../../modules/station-network/station-network.module';
import { ThirdPartyPlacesModule } from '../../modules/third-party-places/third-party-places.module';
import { PlacesController } from './interface/controllers/places.controller';
import { PlacesQueryService } from './places-query.service';

/**
 * Read-only cross-context composition for GET /places/nearby (ADR-0029) — not
 * a bounded-context module (repository-structure.md's 10+2 inventory is
 * unchanged). Imports the two Facilities modules only to reach their
 * exported *QueryService providers via NestJS DI; owns no domain/Prisma
 * models of its own.
 */
@Module({
  imports: [StationNetworkModule, ThirdPartyPlacesModule],
  controllers: [PlacesController],
  providers: [PlacesQueryService],
})
export class PlacesModule {}
