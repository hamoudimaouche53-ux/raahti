import { Body, Controller, Delete, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { ReviewService } from '../../application/review.service';
import { ReviewCreateRequestDto, ReviewResponseDto, ReviewUpdateRequestDto } from '../dto/review.dto';

/**
 * POST/PATCH/DELETE /places/third-party-place/{placeId}/reviews[/{reviewId}]
 * — openapi.yaml tag Places (templated as
 * `/places/{placeType}/{placeId}/reviews[/{reviewId}]`,
 * placeType=third-party-place). Owned entirely by ThirdPartyPlacesModule —
 * see ADR-0029; StationNetworkModule owns the sibling concrete route for
 * placeType=station, independently.
 */
@ApiTags('Places')
@ApiBearerAuth('bearerAuth')
@Controller('places/third-party-place')
export class ThirdPartyPlaceReviewsController {
  constructor(private readonly reviewService: ReviewService) {}

  @Post(':placeId/reviews')
  @HttpCode(HttpStatus.CREATED)
  async submit(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('placeId', ParseUUIDPipe) placeId: string,
    @Body() body: ReviewCreateRequestDto,
  ): Promise<ReviewResponseDto> {
    const review = await this.reviewService.submit(principal.sub, placeId, body);
    return ReviewResponseDto.fromDomain(review);
  }

  /** EPIC-05 US-05.2 — update the caller's own review; 403/404 via ReviewService's ownership check. */
  @Patch(':placeId/reviews/:reviewId')
  async update(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('placeId', ParseUUIDPipe) placeId: string,
    @Param('reviewId', ParseUUIDPipe) reviewId: string,
    @Body() body: ReviewUpdateRequestDto,
  ): Promise<ReviewResponseDto> {
    const review = await this.reviewService.update(principal.sub, placeId, reviewId, body);
    return ReviewResponseDto.fromDomain(review);
  }

  /** EPIC-05 US-05.2 — delete the caller's own review; 403/404 via ReviewService's ownership check. */
  @Delete(':placeId/reviews/:reviewId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('placeId', ParseUUIDPipe) placeId: string,
    @Param('reviewId', ParseUUIDPipe) reviewId: string,
  ): Promise<void> {
    await this.reviewService.delete(principal.sub, placeId, reviewId);
  }
}
