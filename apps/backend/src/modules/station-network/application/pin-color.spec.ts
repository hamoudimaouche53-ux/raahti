import { GeoPosition, Money } from '../../../shared-kernel';
import { Cabin } from '../domain/entities/cabin.entity';
import { SlatokiTent } from '../domain/entities/slatoki-tent.entity';
import { Station } from '../domain/entities/station.entity';
import { deriveStationPinColor } from './pin-color';

function baseStation(overrides: Partial<Parameters<typeof Station.restore>[0]> = {}): Station {
  return Station.restore({
    id: 's1',
    code: 'ST-001',
    configuration: 'fixe',
    position: GeoPosition.of(36.75, 3.05),
    status: 'active',
    cabinCapacity: 0,
    tankCapacityLiters: 0,
    installedAt: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
    cabins: [],
    slatokiTent: null,
    ...overrides,
  });
}

describe('deriveStationPinColor', () => {
  it('returns magenta when the station has a Slatoki tent, regardless of cabins', () => {
    const station = baseStation({
      slatokiTent: SlatokiTent.restore({
        id: 't1',
        stationId: 's1',
        deploymentStatus: 'deployed',
        matCapacity: 4,
        hasLighting: true,
        hasPrivacyCurtain: true,
      }),
      cabins: [Cabin.restore({ id: 'c1', stationId: 's1', code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, price: null })],
    });
    expect(deriveStationPinColor(station)).toBe('magenta');
  });

  it('returns green when every cabin is free', () => {
    const station = baseStation({
      cabins: [Cabin.restore({ id: 'c1', stationId: 's1', code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, price: null })],
    });
    expect(deriveStationPinColor(station)).toBe('green');
  });

  it('returns amber when the station has no cabins yet', () => {
    expect(deriveStationPinColor(baseStation())).toBe('amber');
  });

  it('returns amber for a mixed free/paid cabin set', () => {
    const station = baseStation({
      cabins: [
        Cabin.restore({ id: 'c1', stationId: 's1', code: 'C-01', type: 'H', occupancyStatus: 'free', isPaid: false, price: null }),
        Cabin.restore({
          id: 'c2',
          stationId: 's1',
          code: 'C-02',
          type: 'F',
          occupancyStatus: 'free',
          isPaid: true,
          price: Money.fromDecimalString('30.00', 'DZD'),
        }),
      ],
    });
    expect(deriveStationPinColor(station)).toBe('amber');
  });
});
