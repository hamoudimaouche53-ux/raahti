import { Money } from '../../../../shared-kernel';
import { Cabin, InvalidCabinPriceException } from './cabin.entity';

function baseProps(overrides: Partial<Parameters<typeof Cabin.restore>[0]> = {}) {
  return {
    id: 'c1',
    stationId: 's1',
    code: 'C-01',
    type: 'H' as const,
    occupancyStatus: 'free' as const,
    isPaid: false,
    price: null,
    ...overrides,
  };
}

describe('Cabin', () => {
  it('allows a free cabin with no price', () => {
    const cabin = Cabin.restore(baseProps());
    expect(cabin.isPaid).toBe(false);
    expect(cabin.price).toBeNull();
  });

  it('allows a paid cabin with a price', () => {
    const cabin = Cabin.restore(baseProps({ isPaid: true, price: Money.fromDecimalString('50.00', 'DZD') }));
    expect(cabin.price?.toDecimalString()).toBe('50.00');
  });

  it('rejects a paid cabin with no price', () => {
    expect(() => Cabin.restore(baseProps({ isPaid: true, price: null }))).toThrow(InvalidCabinPriceException);
  });

  it('rejects a free cabin with a price set', () => {
    expect(() =>
      Cabin.restore(baseProps({ isPaid: false, price: Money.fromDecimalString('50.00', 'DZD') })),
    ).toThrow(InvalidCabinPriceException);
  });
});
