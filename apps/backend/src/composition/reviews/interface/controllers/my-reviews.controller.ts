import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { MyReviewsQueryService } from '../../my-reviews-query.service';
import { MyReviewListItemDto } from '../dto/my-review-list-item.dto';
import { MyReviewsListQueryDto } from '../dto/my-reviews-list-query.dto';

/**
 * GET /users/me/reviews — openapi.yaml tag Identity (path-prefix-driven tag
 * choice, consistent with sibling /users/me/* operations). Composition-layer
 * controller (ADR-0029 rule 3) — not owned by either StationNetworkModule or
 * ThirdPartyPlacesModule.
 */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/reviews')
export class MyReviewsController {
  constructor(private readonly myReviewsQueryService: MyReviewsQueryService) {}

  @Get()
  async list(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Query() query: MyReviewsListQueryDto,
  ): Promise<{ data: MyReviewListItemDto[]; nextCursor: string | null }> {
    const page = await this.myReviewsQueryService.listForUser(principal.sub, query.cursor ?? null, query.limit);
    return {
      data: page.data.map((item) => MyReviewListItemDto.fromItem(item)),
      nextCursor: page.nextCursor,
    };
  }
}
