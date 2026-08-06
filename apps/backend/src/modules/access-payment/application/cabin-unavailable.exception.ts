import { DomainException } from '../../../shared-kernel';

/**
 * This module's own 409 for `POST /access-sessions` (openapi.yaml:
 * "Cabin no longer available" — no 404 is documented for that route at
 * all). `InitiateAccessSessionService` catches both
 * `StationCommandService.checkCabinAvailability()`'s possible failures
 * (station-network's own `CabinNotFoundException` 404 and
 * `CabinUnavailableException` 409) and re-raises this module-owned
 * exception uniformly, so the documented contract (409 only) holds
 * regardless of which underlying reason applies.
 */
export class CabinUnavailableException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_CABIN_UNAVAILABLE';
  readonly status = 409;

  constructor(cabinId: string) {
    super(`Cabin ${cabinId} is not available for a new access session.`);
  }
}
