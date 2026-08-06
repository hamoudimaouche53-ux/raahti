import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { VisitHistoryQueryService } from '../../application/visit-history-query.service';
import { VisitHistoryItemResponseDto, VisitHistoryListResponseDto, VisitHistoryQueryDto } from '../dto/visit-history.dto';

/**
 * GET /users/me/visit-history — openapi.yaml tag AccessPayment (EPIC-05
 * US-05.2, FR-USR-02). Separate controller from AccessSessionsController:
 * different URL root (`users/me/visit-history` vs `access-sessions`), same
 * granularity precedent already used elsewhere in this codebase (e.g.
 * station-network splits StationDetailController/StationReviewsController).
 * Sits behind the already-global JwtAuthGuard, same as every other
 * AccessPayment route — no extra auth decorator needed.
 */
@ApiTags('AccessPayment')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/visit-history')
export class VisitHistoryController {
  constructor(private readonly visitHistoryQueryService: VisitHistoryQueryService) {}

  @Get()
  async list(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Query() query: VisitHistoryQueryDto,
  ): Promise<VisitHistoryListResponseDto> {
    const page = await this.visitHistoryQueryService.listForUser(principal.sub, query.cursor ?? null, query.limit);
    return {
      data: page.data.map((item) => VisitHistoryItemResponseDto.fromResult(item)),
      nextCursor: page.nextCursor,
    };
  }
}
