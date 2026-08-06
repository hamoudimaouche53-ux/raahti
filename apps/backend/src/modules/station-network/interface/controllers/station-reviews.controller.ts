import { Body, Controller, Delete, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { ReviewService } from '../../application/review.service';
import { ReviewCreateRequestDto, ReviewResponseDto, ReviewUpdateRequestDto } from '../dto/review.dto';

/**
 * POST/PATCH/DELETE /places/station/{stationId}/reviews[/{reviewId}] —
 * openapi.yaml tag Places (templated as
 * `/places/{placeType}/{placeId}/reviews[/{reviewId}]`, placeType=station).
 * Owned entirely by StationNetworkModule — see ADR-0029 ("writes stay inside
 * their owning bounded context"); ThirdPartyPlacesModule owns the sibling
 * concrete route for placeType=third-party-place, independently.
 */
@ApiTags('Places')
@ApiBearerAuth('bearerAuth')
@Controller('places/station')
export class StationReviewsController {
  constructor(private readonly reviewService: ReviewService) {}

  @Post(':stationId/reviews')
  @HttpCode(HttpStatus.CREATED)
  async submit(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('stationId', ParseUUIDPipe) stationId: string,
    @Body() body: ReviewCreateRequestDto,
  ): Promise<ReviewResponseDto> {
    const review = await this.reviewService.submit(principal.sub, stationId, body);
    return ReviewResponseDto.fromDomain(review);
  }

  /** EPIC-05 US-05.2 — update the caller's own review; 403/404 via ReviewService's ownership check. */
  @Patch(':stationId/reviews/:reviewId')
  async update(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('stationId', ParseUUIDPipe) stationId: string,
    @Param('reviewId', ParseUUIDPipe) reviewId: string,
    @Body() body: ReviewUpdateRequestDto,
  ): Promise<ReviewResponseDto> {
    const review = await this.reviewService.update(principal.sub, stationId, reviewId, body);
    return ReviewResponseDto.fromDomain(review);
  }

  /** EPIC-05 US-05.2 — delete the caller's own review; 403/404 via ReviewService's ownership check. */
  @Delete(':stationId/reviews/:reviewId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('stationId', ParseUUIDPipe) stationId: string,
    @Param('reviewId', ParseUUIDPipe) reviewId: string,
  ): Promise<void> {
    await this.reviewService.delete(principal.sub, stationId, reviewId);
  }
}
