import { DomainException } from '../../../../shared-kernel';

/** ERD/domain-model.md §4, FR-SLK-03. */
export type PrayerFacilityFilter = 'prayer_only' | 'wudu_only' | 'prayer_and_wudu';

const VALID: readonly PrayerFacilityFilter[] = ['prayer_only', 'wudu_only', 'prayer_and_wudu'];

export class InvalidPrayerFacilityFilterException extends DomainException {
  readonly code = 'SLATOKI_INVALID_PRAYER_FACILITY_FILTER';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized Slatoki filter (expected prayer_only|wudu_only|prayer_and_wudu).`);
  }
}

export function assertPrayerFacilityFilter(value: string): asserts value is PrayerFacilityFilter {
  if (!VALID.includes(value as PrayerFacilityFilter)) {
    throw new InvalidPrayerFacilityFilterException(value);
  }
}
