import { DomainException } from '../../../../shared-kernel';

export type StationStatus = 'active' | 'inactive' | 'maintenance';

const VALID: readonly StationStatus[] = ['active', 'inactive', 'maintenance'];

export class InvalidStationStatusException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized station status (expected active|inactive|maintenance).`);
  }
}

export function assertStationStatus(value: string): asserts value is StationStatus {
  if (!VALID.includes(value as StationStatus)) {
    throw new InvalidStationStatusException(value);
  }
}
