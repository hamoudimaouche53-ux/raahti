import { Inject, Injectable } from '@nestjs/common';
import { Cabin } from '../domain/entities/cabin.entity';
import { STATION_REPOSITORY, StationRepository } from '../domain/ports/station.repository';
import { OccupancyStatus } from '../domain/value-objects/occupancy-status.vo';
import { CabinNotFoundException } from './cabin-not-found.exception';
import { CabinUnavailableException } from './cabin-unavailable.exception';

/**
 * Exported application-layer command surface for this module — the sanctioned
 * `AccessPay -> StationNet` COMMAND dependency (module-dependency-diagram.md
 * §3, plain ✔, distinct from the read-only `✔(read)` edges other modules
 * get) and the `Ops -> StationNet` command edge (maintenance start/stop).
 * Mirrors StationQueryService's "the only thing another module may depend
 * on" contract, but for writes — AccessPaymentModule/OperationsModule must
 * never import STATION_REPOSITORY or the Cabin entity constructor directly
 * (module-dependency-diagram.md §5 rule 1).
 */
@Injectable()
export class StationCommandService {
  constructor(@Inject(STATION_REPOSITORY) private readonly stationRepository: StationRepository) {}

  /**
   * Synchronous availability check (module-dependency-diagram.md §5 rule 4:
   * "cabin availability must be checked synchronously before payment").
   * Throws CabinNotFoundException (404) if the cabin doesn't exist,
   * CabinUnavailableException (409) if it exists but isn't `free`.
   */
  async checkCabinAvailability(cabinId: string): Promise<Cabin> {
    const cabin = await this.stationRepository.findCabinById(cabinId);
    if (!cabin) {
      throw new CabinNotFoundException(cabinId);
    }
    if (cabin.occupancyStatus !== 'free') {
      throw new CabinUnavailableException(cabinId, cabin.occupancyStatus);
    }
    return cabin;
  }

  /**
   * Synchronous occupancy write (module-dependency-diagram.md §5 rule 4:
   * "station status must update synchronously" — same immediate-consistency
   * rationale extended to per-cabin occupancy). Used by AccessPaymentModule
   * around the unlock/complete flow.
   */
  async setCabinOccupancy(cabinId: string, status: 'free' | 'occupied'): Promise<void> {
    await this.stationRepository.updateCabinOccupancy(cabinId, status as OccupancyStatus);
  }
}
