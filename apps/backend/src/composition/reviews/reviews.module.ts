import { Module } from '@nestjs/common';
import { StationNetworkModule } from '../../modules/station-network/station-network.module';
import { ThirdPartyPlacesModule } from '../../modules/third-party-places/third-party-places.module';
import { MyReviewsController } from './interface/controllers/my-reviews.controller';
import { MyReviewsQueryService } from './my-reviews-query.service';

/**
 * Read-only cross-context composition for GET /users/me/reviews (EPIC-05
 * US-05.2, ADR-0029 rule 3) — not a bounded-context module
 * (repository-structure.md's 10+2 inventory is unchanged), mirrors
 * composition/places's PlacesModule precisely. Imports the two Facilities
 * modules only to reach their exported *QueryService providers via NestJS
 * DI; owns no domain/Prisma models of its own. Review update/delete (writes)
 * are NOT here — they stay in StationNetworkModule's/ThirdPartyPlacesModule's
 * own controllers (ADR-0029 rule 3).
 */
@Module({
  imports: [StationNetworkModule, ThirdPartyPlacesModule],
  controllers: [MyReviewsController],
  providers: [MyReviewsQueryService],
})
export class ReviewsModule {}
