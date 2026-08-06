import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { GeoPosition } from '../../../../shared-kernel';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import { EmergencyQueryService } from '../../application/emergency-query.service';
import { NoAccessibleFacilityFoundException } from '../../application/no-accessible-facility-found.exception';
import { EmergencyFacilityResultDto } from '../dto/emergency-facility-result.dto';
import { NearestFacilityQueryDto } from '../dto/nearest-facility-query.dto';

/**
 * GET /emergency/nearest-facility — openapi.yaml tag Emergency (FR-EMG-01/02/03).
 * Sits behind the already-global JwtAuthGuard (IdentityModule's APP_GUARD
 * wiring) — no `@Public()`, no `@Roles()`/`@RequireMfa()` (any authenticated
 * usager may use this route), same as AccessSessionsController.
 */
@ApiTags('Emergency')
@ApiBearerAuth('bearerAuth')
@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergencyQueryService: EmergencyQueryService) {}

  @Get('nearest-facility')
  async nearestFacility(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Query() query: NearestFacilityQueryDto,
  ): Promise<EmergencyFacilityResultDto> {
    const result = await this.emergencyQueryService.findNearestFacility({
      userId: principal.sub,
      position: GeoPosition.of(query.lat, query.lng),
    });
    if (!result) {
      throw new NoAccessibleFacilityFoundException();
    }
    return EmergencyFacilityResultDto.fromResult(result);
  }
}
