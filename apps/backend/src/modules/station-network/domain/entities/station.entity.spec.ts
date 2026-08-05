import { GeoPosition, Money } from '../../../../shared-kernel';
import { Cabin } from './cabin.entity';
import { SlatokiTent } from './slatoki-tent.entity';
import { CabinStationMismatchException, SlatokiTentStationMismatchException, Station } from './station.entity';

function freeCabin(id: string, stationId: string) {
  return Cabin.restore({ id, stationId, code: id, type: 'H', occupancyStatus: 'free', isPaid: false, price: null });
}

function paidCabin(id: string, stationId: string) {
  return Cabin.restore({
    id,
    stationId,
    code: id,
    type: 'F',
    occupancyStatus: 'free',
    isPaid: true,
    price: Money.fromDecimalString('30.00', 'DZD'),
  });
}

function baseStationProps(overrides: Partial<Parameters<typeof Station.restore>[0]> = {}) {
  return {
    id: 's1',
    code: 'ST-001',
    configuration: 'fixe' as const,
    position: GeoPosition.of(36.75, 3.05),
    status: 'active' as const,
    cabinCapacity: 2,
    tankCapacityLiters: 500,
    installedAt: new Date('2026-01-01'),
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    cabins: [],
    slatokiTent: null,
    ...overrides,
  };
}

describe('Station', () => {
  it('restores with cabins belonging to it', () => {
    const station = Station.restore(baseStationProps({ cabins: [freeCabin('c1', 's1')] }));
    expect(station.cabins).toHaveLength(1);
  });

  it('rejects a cabin belonging to a different station', () => {
    expect(() => Station.restore(baseStationProps({ cabins: [freeCabin('c1', 'other-station')] }))).toThrow(
      CabinStationMismatchException,
    );
  });

  it('rejects a slatoki tent belonging to a different station', () => {
    const tent = SlatokiTent.restore({
      id: 't1',
      stationId: 'other-station',
      deploymentStatus: 'deployed',
      matCapacity: 4,
      hasLighting: true,
      hasPrivacyCurtain: true,
    });
    expect(() => Station.restore(baseStationProps({ slatokiTent: tent }))).toThrow(
      SlatokiTentStationMismatchException,
    );
  });

  it('reports hasSlatokiTent correctly', () => {
    const withTent = Station.restore(
      baseStationProps({
        slatokiTent: SlatokiTent.restore({
          id: 't1',
          stationId: 's1',
          deploymentStatus: 'folded',
          matCapacity: 4,
          hasLighting: true,
          hasPrivacyCurtain: true,
        }),
      }),
    );
    const withoutTent = Station.restore(baseStationProps());
    expect(withTent.hasSlatokiTent).toBe(true);
    expect(withoutTent.hasSlatokiTent).toBe(false);
  });

  describe('cabinPricingMix', () => {
    it('returns no_cabins when the station has none', () => {
      expect(Station.restore(baseStationProps()).cabinPricingMix()).toBe('no_cabins');
    });

    it('returns all_free when every cabin is free', () => {
      const station = Station.restore(baseStationProps({ cabins: [freeCabin('c1', 's1'), freeCabin('c2', 's1')] }));
      expect(station.cabinPricingMix()).toBe('all_free');
    });

    it('returns all_paid when every cabin is paid', () => {
      const station = Station.restore(baseStationProps({ cabins: [paidCabin('c1', 's1'), paidCabin('c2', 's1')] }));
      expect(station.cabinPricingMix()).toBe('all_paid');
    });

    it('returns mixed when cabins differ', () => {
      const station = Station.restore(baseStationProps({ cabins: [freeCabin('c1', 's1'), paidCabin('c2', 's1')] }));
      expect(station.cabinPricingMix()).toBe('mixed');
    });
  });
});
