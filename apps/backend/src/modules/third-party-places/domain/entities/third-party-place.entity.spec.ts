import { GeoPosition, Money } from '../../../../shared-kernel';
import { InvalidThirdPartyPlacePriceException, ThirdPartyPlace } from './third-party-place.entity';

function baseProps(overrides: Partial<Parameters<typeof ThirdPartyPlace.restore>[0]> = {}) {
  return {
    id: 'p1',
    nameFr: 'Mosquée Al-Fath',
    nameAr: 'مسجد الفتح',
    placeType: 'mosque' as const,
    position: GeoPosition.of(36.75, 3.05),
    isFree: true,
    price: null,
    declaredStatus: 'open' as const,
    statusSource: 'community' as const,
    tags: [],
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('ThirdPartyPlace', () => {
  it('allows a free place with no price', () => {
    const place = ThirdPartyPlace.restore(baseProps());
    expect(place.isFree).toBe(true);
  });

  it('allows a non-free place with a price', () => {
    const place = ThirdPartyPlace.restore(
      baseProps({ isFree: false, price: Money.fromDecimalString('20.00', 'DZD') }),
    );
    expect(place.price?.toDecimalString()).toBe('20.00');
  });

  it('rejects a non-free place with no price', () => {
    expect(() => ThirdPartyPlace.restore(baseProps({ isFree: false, price: null }))).toThrow(
      InvalidThirdPartyPlacePriceException,
    );
  });

  it('rejects a free place with a price set', () => {
    expect(() =>
      ThirdPartyPlace.restore(baseProps({ isFree: true, price: Money.fromDecimalString('20.00', 'DZD') })),
    ).toThrow(InvalidThirdPartyPlacePriceException);
  });

  it('reports tag membership', () => {
    const place = ThirdPartyPlace.restore(baseProps({ tags: ['women_confirmed', 'wudu'] }));
    expect(place.hasTag('women_confirmed')).toBe(true);
    expect(place.hasTag('pmr')).toBe(false);
  });
});
