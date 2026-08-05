import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedPrincipal, CurrentUser, RequireMfa, Roles } from '../../../../platform/auth';
import { MaintenanceInterventionService } from '../../application/maintenance-intervention.service';
import {
  MaintenanceInterventionCreateRequestDto,
  MaintenanceInterventionResponseDto,
} from '../dto/maintenance-intervention.dto';

/** GET/POST /ops/maintenance-interventions — openapi.yaml tag Operations (FR-OPS-03). See AlertsController's doc comment for the role/MFA reasoning. */
@ApiTags('Operations')
@ApiBearerAuth('bearerAuth')
@Roles('operateur')
@RequireMfa()
@Controller('ops/maintenance-interventions')
export class MaintenanceInterventionsController {
  constructor(private readonly maintenanceInterventionService: MaintenanceInterventionService) {}

  @Get()
  async list(): Promise<{ data: MaintenanceInterventionResponseDto[] }> {
    const interventions = await this.maintenanceInterventionService.list();
    return { data: interventions.map((intervention) => MaintenanceInterventionResponseDto.fromDomain(intervention)) };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async schedule(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Body() body: MaintenanceInterventionCreateRequestDto,
  ): Promise<MaintenanceInterventionResponseDto> {
    const intervention = await this.maintenanceInterventionService.schedule(
      {
        stationId: body.stationId,
        interventionType: body.interventionType,
        scheduledAt: new Date(body.scheduledAt),
        assignedTo: body.assignedTo,
      },
      principal.sub,
    );
    return MaintenanceInterventionResponseDto.fromDomain(intervention);
  }
}
