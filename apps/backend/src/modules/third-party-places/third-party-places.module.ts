import { Module } from '@nestjs/common';
import { ReviewService } from './application/review.service';
import { ThirdPartyPlaceQueryService } from './application/third-party-place-query.service';
import { THIRD_PARTY_PLACE_REPOSITORY } from './domain/ports/third-party-place.repository';
import { THIRD_PARTY_PLACE_REVIEW_REPOSITORY } from './domain/ports/third-party-place-review.repository';
import { PrismaThirdPartyPlaceRepository } from './infrastructure/prisma-third-party-place.repository';
import { PrismaThirdPartyPlaceReviewRepository } from './infrastructure/prisma-third-party-place-review.repository';
import { ThirdPartyPlaceDetailController } from './interface/controllers/third-party-place-detail.controller';
import { ThirdPartyPlaceReviewsController } from './interface/controllers/third-party-place-reviews.controller';

/**
 * Third-Party Places bounded context (Domain Model §5). Facilities module
 * (Phase 4 Implementation Plan §6 item 3): domain, Prisma schema,
 * repositories, application query/review services, detail/reviews controllers.
 */
@Module({
  controllers: [ThirdPartyPlaceDetailController, ThirdPartyPlaceReviewsController],
  providers: [
    { provide: THIRD_PARTY_PLACE_REPOSITORY, useClass: PrismaThirdPartyPlaceRepository },
    { provide: THIRD_PARTY_PLACE_REVIEW_REPOSITORY, useClass: PrismaThirdPartyPlaceReviewRepository },
    ThirdPartyPlaceQueryService,
    ReviewService,
  ],
  exports: [THIRD_PARTY_PLACE_REPOSITORY, ThirdPartyPlaceQueryService],
})
export class ThirdPartyPlacesModule {}
