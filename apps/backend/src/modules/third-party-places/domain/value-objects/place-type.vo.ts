import { DomainException } from '../../../../shared-kernel';

export type PlaceType = 'mosque' | 'business' | 'gas_station' | 'other';

const VALID: readonly PlaceType[] = ['mosque', 'business', 'gas_station', 'other'];

export class InvalidPlaceTypeException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_PLACE_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized place type (expected mosque|business|gas_station|other).`);
  }
}

export function assertPlaceType(value: string): asserts value is PlaceType {
  if (!VALID.includes(value as PlaceType)) {
    throw new InvalidPlaceTypeException(value);
  }
}
