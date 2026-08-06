import { DomainException } from '../../../shared-kernel';

/** No `active` station within EmergencyModule's search radius (FR-EMG-02) — backs GET /emergency/nearest-facility's 404. */
export class NoAccessibleFacilityFoundException extends DomainException {
  readonly code = 'NO_ACCESSIBLE_FACILITY_FOUND';
  readonly status = 404;

  constructor() {
    super('No accessible facility was found within the emergency search radius.');
  }
}
