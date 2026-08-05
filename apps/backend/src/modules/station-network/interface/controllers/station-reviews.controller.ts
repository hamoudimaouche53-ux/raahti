import { Body, Controller, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { ReviewService } from '../../application/review.service';
import { ReviewCreateRequestDto, ReviewResponseDto } from '../dto/review.dto';

/**
 * POST /places/station/{stationId}/reviews — openapi.yaml tag Places
 * (templated as `/places/{placeType}/{placeId}/reviews`, placeType=station).
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
}
