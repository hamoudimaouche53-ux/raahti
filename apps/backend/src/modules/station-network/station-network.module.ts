import { Module } from '@nestjs/common';
import { ReviewService } from './application/review.service';
import { StationCommandService } from './application/station-command.service';
import { StationQueryService } from './application/station-query.service';
import { STATION_REPOSITORY } from './domain/ports/station.repository';
import { STATION_REVIEW_REPOSITORY } from './domain/ports/station-review.repository';
import { PrismaStationRepository } from './infrastructure/prisma-station.repository';
import { PrismaStationReviewRepository } from './infrastructure/prisma-station-review.repository';
import { StationDetailController } from './interface/controllers/station-detail.controller';
import { StationReviewsController } from './interface/controllers/station-reviews.controller';

/**
 * Station Network bounded context (Domain Model §3). Facilities module
 * (Phase 4 Implementation Plan §6 item 3): domain, Prisma schema,
 * repositories, application query/review services, detail/cabins/reviews
 * controllers.
 */
@Module({
  controllers: [StationDetailController, StationReviewsController],
  providers: [
    { provide: STATION_REPOSITORY, useClass: PrismaStationRepository },
    { provide: STATION_REVIEW_REPOSITORY, useClass: PrismaStationReviewRepository },
    StationQueryService,
    StationCommandService,
    ReviewService,
  ],
  exports: [STATION_REPOSITORY, StationQueryService, StationCommandService],
})
export class StationNetworkModule {}
