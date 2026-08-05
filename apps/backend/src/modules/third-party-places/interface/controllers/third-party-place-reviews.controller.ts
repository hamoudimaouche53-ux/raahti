import { Body, Controller, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { ReviewService } from '../../application/review.service';
import { ReviewCreateRequestDto, ReviewResponseDto } from '../dto/review.dto';

/**
 * POST /places/third-party-place/{placeId}/reviews — openapi.yaml tag Places
 * (templated as `/places/{placeType}/{placeId}/reviews`,
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
}
