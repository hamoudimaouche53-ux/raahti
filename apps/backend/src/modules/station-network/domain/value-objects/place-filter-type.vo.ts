import { DomainException } from '../../../../shared-kernel';

/**
 * FR-MAP-05 quick-filter chip values (ADR-0021, already shipped mobile-side
 * as `PlaceCategory`). Multi-select, OR semantics. `rahati_unit` matches every
 * Station unconditionally; `free_wc`/`paid_wc` mirror `isFree`/`!isFree`;
 * `slatoki` mirrors `pinColor === magenta` — see ADR-0021's `_matchesAnyCategory`
 * (apps/mobile/.../filter_places.dart), mirrored server-side here.
 */
export type PlaceFilterType = 'free_wc' | 'paid_wc' | 'rahati_unit' | 'slatoki';

const VALID: readonly PlaceFilterType[] = ['free_wc', 'paid_wc', 'rahati_unit', 'slatoki'];

export class InvalidPlaceFilterTypeException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_PLACE_FILTER_TYPE';
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
