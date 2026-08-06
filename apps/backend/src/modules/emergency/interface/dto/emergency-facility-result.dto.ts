import { ApiProperty } from '@nestjs/swagger';
import { EmergencyNearestFacilityResult } from '../../application/emergency-query.service';
import { PlaceSummaryDto } from './place-summary.dto';

/** Matches openapi.yaml components.schemas.EmergencyFacilityResult exactly. */
export class EmergencyFacilityResultDto {
  @ApiProperty({ type: PlaceSummaryDto })
  place!: PlaceSummaryDto;

  @ApiProperty({ format: 'uuid', nullable: true })
  nearestCabinId!: string | null;

  @ApiProperty({ description: 'True only if caller.diabeticVerificationStatus = verified (FR-EMG-03).' })
  discountEligible!: boolean;

  static fromResult(result: EmergencyNearestFacilityResult): EmergencyFacilityResultDto {
    const dto = new EmergencyFacilityResultDto();
    dto.place = PlaceSummaryDto.fromSearchItem(result.place);
    dto.nearestCabinId = result.nearestCabinId;
    dto.discountEligible = result.discountEligible;
    return dto;
  }
}
