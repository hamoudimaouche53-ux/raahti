import { DomainException } from '../../../shared-kernel';

export class ThirdPartyPlaceNotFoundException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_PLACE_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Third-party place ${id} was not found.`);
  }
}
