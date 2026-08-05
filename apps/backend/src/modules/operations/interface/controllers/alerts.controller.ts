import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser, RequireMfa, Roles } from '../../../../platform/auth';
import { AlertService } from '../../application/alert.service';
import { AlertListQueryDto, AlertResponseDto, AlertUpdateRequestDto } from '../dto/alert.dto';

/**
 * GET/PATCH /ops/alerts — openapi.yaml tag Operations (FR-OPS-02).
 * `role=operateur` is stated explicitly only on `GET /ops/stations`'s
 * description, but every FR-OPS-01..05 requirement is grouped under one
 * "Operator Dashboard" heading in SRS §5 — applied uniformly across all
 * /ops/* routes as the natural reading, flagged as a judgment call.
 * `@RequireMfa()` per Security Architecture §1: "all /ops/* ... routes with
 * role != usager".
 */
@ApiTags('Operations')
@ApiBearerAuth('bearerAuth')
@Roles('operateur')
@RequireMfa()
@Controller('ops/alerts')
export class AlertsController {
  constructor(private readonly alertService: AlertService) {}

  @Get()
  async list(@Query() query: AlertListQueryDto): Promise<{ data: AlertResponseDto[] }> {
    const alerts = await this.alertService.list(query.status);
    return { data: alerts.map((alert) => AlertResponseDto.fromDomain(alert)) };
  }

  @Patch(':alertId')
  async updateStatus(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('alertId', ParseUUIDPipe) alertId: string,
    @Body() body: AlertUpdateRequestDto,
  ): Promise<AlertResponseDto> {
    const alert = await this.alertService.updateStatus(alertId, body.status, principal.sub);
    return AlertResponseDto.fromDomain(alert);
  }
}
