import { GeoPosition } from '../../../shared-kernel';
import { StationPlaceSearchItem, StationQueryService } from '../../station-network/application/station-query.service';
import {
  ThirdPartyPlacePlaceSearchItem,
  ThirdPartyPlaceQueryService,
} from '../../third-party-places/application/third-party-place-query.service';
import { SlatokiQueryService } from './slatoki-query.service';

function stationItem(overrides: Partial<StationPlaceSearchItem> = {}): StationPlaceSearchItem {
  return {
    id: 's1',
    placeKind: 'station',
    name: { fr: 'ST-001', ar: 'ST-001', en: 'ST-001' },
    position: { lat: 36.75, lng: 3.05 },
    pinColor: 'magenta',
    distanceMeters: 100,
    isFree: true,
    averageRating: null,
    reviewCount: 0,
    tags: [],
    hasSlatokiTent: true,
    ...overrides,
  };
}

function placeItem(overrides: Partial<ThirdPartyPlacePlaceSearchItem> = {}): ThirdPartyPlacePlaceSearchItem {
  return {
    id: 'p1',
    placeKind: 'third_party_place',
    name: { fr: 'Mosquée', ar: 'مسجد', en: 'Mosquée' },
    position: { lat: 36.76, lng: 3.06 },
    pinColor: 'blue',
    distanceMeters: 200,
    isFree: true,
    averageRating: null,
    reviewCount: 0,
    tags: ['prayer', 'wudu'],
    ...overrides,
  };
}

function createServices(stationData: StationPlaceSearchItem[], placeData: ThirdPartyPlacePlaceSearchItem[]) {
  const stationQueryService = {
    searchNearby: jest.fn().mockResolvedValue({ data: stationData, nextCursor: null }),
  } as unknown as jest.Mocked<StationQueryService>;
  const thirdPartyPlaceQueryService = {
    searchNearby: jest.fn().mockResolvedValue({ data: placeData, nextCursor: null }),
  } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
  return { stationQueryService, thirdPartyPlaceQueryService };
}

const POSITION = GeoPosition.of(36.75, 3.05);

describe('SlatokiQueryService', () => {
  it('includes a station only when it has a Slatoki tent', async () => {
    const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
      [stationItem({ id: 'with-tent', hasSlatokiTent: true }), stationItem({ id: 'no-tent', hasSlatokiTent: false })],
      [],
    );
    const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const results = await service.searchPlaces({ position: POSITION });

    expect(results.map((r) => r.id)).toEqual(['with-tent']);
  });

  it('marks every Slatoki-tented station as verified_confirmed', async () => {
    const { stationQueryService, thirdPartyPlaceQueryService } = createServices([stationItem()], []);
    const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const [result] = await service.searchPlaces({ position: POSITION });

    expect(result.womenVerificationLevel).toBe('verified_confirmed');
  });

  it('includes a third-party place only when tagged prayer or wudu', async () => {
    const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
      [],
      [
        placeItem({ id: 'prayer-only', tags: ['prayer'] }),
        placeItem({ id: 'wudu-only', tags: ['wudu'] }),
        placeItem({ id: 'neither', tags: ['pmr', 'open_now'] }),
      ],
    );
    const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const results = await service.searchPlaces({ position: POSITION });

    expect(results.map((r) => r.id).sort()).toEqual(['prayer-only', 'wudu-only']);
  });

  it('marks a third-party place verified_confirmed only when tagged women_confirmed, else generic', async () => {
    const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
      [],
      [
        placeItem({ id: 'verified', tags: ['prayer', 'women_confirmed'] }),
        placeItem({ id: 'generic', tags: ['prayer'] }),
      ],
    );
    const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const results = await service.searchPlaces({ position: POSITION });

    expect(results.find((r) => r.id === 'verified')?.womenVerificationLevel).toBe('verified_confirmed');
    expect(results.find((r) => r.id === 'generic')?.womenVerificationLevel).toBe('generic');
  });

  describe('filter', () => {
    it('prayer_only matches a place with the prayer tag, capability-style (extra tags do not exclude it)', async () => {
      const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
        [],
        [placeItem({ id: 'both', tags: ['prayer', 'wudu'] })],
      );
      const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

      const results = await service.searchPlaces({ position: POSITION, filter: 'prayer_only' });

      expect(results.map((r) => r.id)).toEqual(['both']);
    });

    it('wudu_only excludes a place tagged prayer only', async () => {
      const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
        [],
        [placeItem({ id: 'prayer-only', tags: ['prayer'] })],
      );
      const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

      const results = await service.searchPlaces({ position: POSITION, filter: 'wudu_only' });

      expect(results).toEqual([]);
    });

    it('prayer_and_wudu requires both tags on a third-party place', async () => {
      const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
        [],
        [placeItem({ id: 'both', tags: ['prayer', 'wudu'] }), placeItem({ id: 'prayer-only', tags: ['prayer'] })],
      );
      const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

      const results = await service.searchPlaces({ position: POSITION, filter: 'prayer_and_wudu' });

      expect(results.map((r) => r.id)).toEqual(['both']);
    });

    it('a Slatoki-tented station always matches every filter value (full prayer+ablution facility)', async () => {
      const { stationQueryService, thirdPartyPlaceQueryService } = createServices([stationItem()], []);
      const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

      for (const filter of ['prayer_only', 'wudu_only', 'prayer_and_wudu'] as const) {
        const results = await service.searchPlaces({ position: POSITION, filter });
        expect(results).toHaveLength(1);
      }
    });
  });

  it('merges and sorts stations and third-party places together by distance', async () => {
    const { stationQueryService, thirdPartyPlaceQueryService } = createServices(
      [stationItem({ id: 'far-station', distanceMeters: 500 })],
      [
        placeItem({ id: 'near-place', distanceMeters: 50 }),
        placeItem({ id: 'mid-place', distanceMeters: 250 }),
      ],
    );
    const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const results = await service.searchPlaces({ position: POSITION });

    expect(results.map((r) => r.id)).toEqual(['near-place', 'mid-place', 'far-station']);
  });

  it('queries both sources with the same fixed position (no client-configurable radius/pagination for this endpoint)', async () => {
    const { stationQueryService, thirdPartyPlaceQueryService } = createServices([], []);
    const service = new SlatokiQueryService(stationQueryService, thirdPartyPlaceQueryService);

    await service.searchPlaces({ position: POSITION });

    expect(stationQueryService.searchNearby).toHaveBeenCalledWith(
      expect.objectContaining({ position: POSITION, types: [] }),
    );
    expect(thirdPartyPlaceQueryService.searchNearby).toHaveBeenCalledWith(
      expect.objectContaining({ position: POSITION, types: [] }),
    );
  });
});
