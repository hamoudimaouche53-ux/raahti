import { DomainException } from '../../../../shared-kernel';

export type CabinType = 'H' | 'F' | 'Slatoki' | 'PMR';

const VALID: readonly CabinType[] = ['H', 'F', 'Slatoki', 'PMR'];

export class InvalidCabinTypeException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_CABIN_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized cabin type (expected H|F|Slatoki|PMR).`);
  }
}

export function assertCabinType(value: string): asserts value is CabinType {
  if (!VALID.includes(value as CabinType)) {
    throw new InvalidCabinTypeException(value);
  }
}
