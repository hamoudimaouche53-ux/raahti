import { GeoPosition, Money } from '../../../shared-kernel';
import { ThirdPartyPlace } from '../domain/entities/third-party-place.entity';
import { deriveThirdPartyPlacePinColor } from './pin-color';

function basePlace(overrides: Partial<Parameters<typeof ThirdPartyPlace.restore>[0]> = {}): ThirdPartyPlace {
  return ThirdPartyPlace.restore({
    id: 'p1',
    nameFr: 'Mosquée Al-Fath',
    nameAr: 'مسجد الفتح',
    placeType: 'mosque',
    position: GeoPosition.of(36.75, 3.05),
    isFree: true,
    price: null,
    declaredStatus: 'open',
    statusSource: 'community',
    tags: [],
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  });
}

describe('deriveThirdPartyPlacePinColor', () => {
  it('returns magenta when tagged women_confirmed, regardless of isFree', () => {
    const place = basePlace({ tags: ['women_confirmed'], isFree: false, price: Money.fromDecimalString('10.00', 'DZD') });
    expect(deriveThirdPartyPlacePinColor(place)).toBe('magenta');
  });

  it('returns green when free and not women_confirmed', () => {
    expect(deriveThirdPartyPlacePinColor(basePlace({ isFree: true }))).toBe('green');
  });

  it('returns blue when not free and not women_confirmed', () => {
    const place = basePlace({ isFree: false, price: Money.fromDecimalString('10.00', 'DZD') });
    expect(deriveThirdPartyPlacePinColor(place)).toBe('blue');
  });
});
