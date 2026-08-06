import { Injectable } from '@nestjs/common';
import { GeoPosition } from '../../../shared-kernel';
import { UserQueryService } from '../../identity/application/user-query.service';
import { NearestAccessibleFacility, StationQueryService } from '../../station-network/application/station-query.service';
import { EmergencyDiscountPolicy } from '../domain/services/emergency-discount-policy';

export interface EmergencyNearestFacilityResult {
  place: NearestAccessibleFacility['place'];
  nearestCabinId: string | null;
  discountEligible: boolean;
}

/**
 * Emergency Mode bounded context (Domain Model §7) — owns no aggregate, no
 * persisted state, no Prisma models (module-dependency-diagram.md §5 rule 3:
 * "Orchestration modules own no persisted state"). Depends only on
 * IdentityModule's and StationNetworkModule's exported *QueryService, the
 * read edges the matrix grants specifically to Emergency (§3:
 * `Emergency -.->|read| Identity`, `Emergency -.->|read| StationNetwork`).
 */
@Injectable()
export class EmergencyQueryService {
  constructor(
    private readonly userQueryService: UserQueryService,
    private readonly stationQueryService: StationQueryService,
  ) {}

  /** Backing GET /emergency/nearest-facility (FR-EMG-01/02/03). */
  async findNearestFacility(params: { userId: string; position: GeoPosition }): Promise<EmergencyNearestFacilityResult | null> {
    const [user, nearest] = await Promise.all([
      this.userQueryService.findById(params.userId),
      this.stationQueryService.findNearestAccessible(params.position),
    ]);
    if (!nearest) {
      return null;
    }
    return {
      place: nearest.place,
      nearestCabinId: nearest.nearestCabinId,
      // No user (should not happen for an authenticated caller) is treated as
      // not eligible, never thrown — this endpoint's only job is to report
      // eligibility, not to enforce account existence.
      discountEligible: user ? EmergencyDiscountPolicy.isEligible(user.diabeticVerificationStatus) : false,
    };
  }
}
