import { DomainException } from '../../../shared-kernel';

export class CabinNotFoundException extends DomainException {
  readonly code = 'STATION_NETWORK_CABIN_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Cabin ${id} was not found.`);
  }
}
