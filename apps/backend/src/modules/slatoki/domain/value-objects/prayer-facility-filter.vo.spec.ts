import { assertPrayerFacilityFilter, InvalidPrayerFacilityFilterException } from './prayer-facility-filter.vo';

describe('assertPrayerFacilityFilter', () => {
  it.each(['prayer_only', 'wudu_only', 'prayer_and_wudu'])('accepts %p', (value) => {
    expect(() => assertPrayerFacilityFilter(value)).not.toThrow();
  });

  it('rejects an unrecognized value', () => {
    expect(() => assertPrayerFacilityFilter('everything')).toThrow(InvalidPrayerFacilityFilterException);
  });
});
