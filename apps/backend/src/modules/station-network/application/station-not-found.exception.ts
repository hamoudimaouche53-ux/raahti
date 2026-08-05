import { DomainException } from '../../../shared-kernel';

export class StationNotFoundException extends DomainException {
  readonly code = 'STATION_NETWORK_STATION_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Station ${id} was not found.`);
  }
}
