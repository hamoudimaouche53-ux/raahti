import { DomainException } from '../../../../shared-kernel';

/** See station-network's copy for the full FR-MAP-05/ADR-0021 rationale (duplicated per ADR-0029 independence). `rahati_unit` never matches a ThirdPartyPlace. */
export type PlaceFilterType = 'free_wc' | 'paid_wc' | 'rahati_unit' | 'slatoki';

const VALID: readonly PlaceFilterType[] = ['free_wc', 'paid_wc', 'rahati_unit', 'slatoki'];

export class InvalidPlaceFilterTypeException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_PLACE_FILTER_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized place filter type (expected free_wc|paid_wc|rahati_unit|slatoki).`);
  }
}

export function assertPlaceFilterType(value: string): asserts value is PlaceFilterType {
  if (!VALID.includes(value as PlaceFilterType)) {
    throw new InvalidPlaceFilterTypeException(value);
  }
}
