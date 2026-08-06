import { DomainException } from '../../../shared-kernel';
import { OccupancyStatus } from '../domain/value-objects/occupancy-status.vo';

/**
 * Thrown by StationCommandService.checkCabinAvailability() when a cabin
 * exists but is not `free` (occupied or out_of_service) — maps to
 * `POST /access-sessions`'s documented 409 response
 * (openapi.yaml: "Cabin no longer available", FR-PAY-02).
 */
export class CabinUnavailableException extends DomainException {
  readonly code = 'STATION_NETWORK_CABIN_UNAVAILABLE';
  readonly status = 409;

  constructor(id: string, occupancyStatus: OccupancyStatus) {
    super(`Cabin ${id} is not available (occupancyStatus="${occupancyStatus}").`);
  }
}
