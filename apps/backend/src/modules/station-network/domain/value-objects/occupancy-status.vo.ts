import { DomainException } from '../../../../shared-kernel';

export type OccupancyStatus = 'free' | 'occupied' | 'out_of_service';

const VALID: readonly OccupancyStatus[] = ['free', 'occupied', 'out_of_service'];

export class InvalidOccupancyStatusException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_OCCUPANCY_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized occupancy status (expected free|occupied|out_of_service).`);
  }
}

export function assertOccupancyStatus(value: string): asserts value is OccupancyStatus {
  if (!VALID.includes(value as OccupancyStatus)) {
    throw new InvalidOccupancyStatusException(value);
  }
}
