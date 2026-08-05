import { GeoPosition } from '../../shared-kernel';
import { StationPlaceSearchItem, StationQueryService } from '../../modules/station-network/application/station-query.service';
import {
  ThirdPartyPlacePlaceSearchItem,
  ThirdPartyPlaceQueryService,
} from '../../modules/third-party-places/application/third-party-place-query.service';
import { PlacesQueryService } from './places-query.service';

function stationItem(id: string, distanceMeters: number): StationPlaceSearchItem {
  return {
    id,
    placeKind: 'station',
    name: { fr: id, ar: id, en: id },
    position: { lat: 36.75, lng: 3.05 },
    pinColor: 'green',
    distanceMeters,
    isFree: true,
    averageRating: null,
    reviewCount: 0,
    tags: [],
  };
}

function placeItem(id: string, distanceMeters: number): ThirdPartyPlacePlaceSearchItem {
  return {
    id,
    placeKind: 'third_party_place',
    name: { fr: id, ar: id, en: id },
    position: { lat: 36.75, lng: 3.05 },
    pinColor: 'blue',
    distanceMeters,
    isFree: false,
    averageRating: null,
    reviewCount: 0,
    tags: [],
  };
}

const CRITERIA = { position: GeoPosition.of(36.75, 3.05), radiusMeters: 2000, types: [], limit: 3 };

describe('PlacesQueryService', () => {
  it('merges two sources into a single distance-sorted page', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.searchNearby.mockResolvedValue({
      data: [stationItem('s1', 10), stationItem('s2', 50)],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValue({
      data: [placeItem('p1', 20), placeItem('p2', 100)],
      nextCursor: null,
    });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.searchNearby({ ...CRITERIA, limit: 3 });

    expect(page.data.map((item) => item.id)).toEqual(['s1', 'p1', 's2']);
  });

  it('returns nextCursor null when both sources are exhausted with everything consumed', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.searchNearby.mockResolvedValue({ data: [stationItem('s1', 10)], nextCursor: null });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValue({ data: [placeItem('p1', 20)], nextCursor: null });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.searchNearby({ ...CRITERIA, limit: 10 });

    expect(page.data).toHaveLength(2);
    expect(page.nextCursor).toBeNull();
  });

  it('returns nextCursor null when both sources have no results at all', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.searchNearby.mockResolvedValue({ data: [], nextCursor: null });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValue({ data: [], nextCursor: null });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.searchNearby(CRITERIA);

    expect(page.data).toEqual([]);
    expect(page.nextCursor).toBeNull();
  });

  it('produces a non-null cursor when a source has unconsumed leftover items', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    // 3 stations fetched (limit=3), but only the closest one is taken because
    // the third-party place at distance 15 also makes the cut ahead of s2/s3.
    stationQueryService.searchNearby.mockResolvedValue({
      data: [stationItem('s1', 10), stationItem('s2', 200), stationItem('s3', 300)],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValue({ data: [placeItem('p1', 15)], nextCursor: null });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.searchNearby({ ...CRITERIA, limit: 2 });

    expect(page.data.map((item) => item.id)).toEqual(['s1', 'p1']);
    expect(page.nextCursor).not.toBeNull();
  });

  it('resumes a partially-drained source from exactly where it left off (no loss, no duplicate)', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.searchNearby.mockResolvedValueOnce({
      data: [stationItem('s1', 10), stationItem('s2', 200), stationItem('s3', 300)],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValueOnce({ data: [placeItem('p1', 15)], nextCursor: null });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const firstPage = await service.searchNearby({ ...CRITERIA, limit: 2 });
    expect(firstPage.data.map((item) => item.id)).toEqual(['s1', 'p1']);

    // Second page: the third-party source is now exhausted (fetched only p1,
    // fully consumed, its own nextCursor was null) and should NOT be re-queried;
    // the station source resumes after s1.
    stationQueryService.searchNearby.mockResolvedValueOnce({
      data: [stationItem('s2', 200), stationItem('s3', 300)],
      nextCursor: null,
    });
    const secondPage = await service.searchNearby({ ...CRITERIA, limit: 2, cursor: firstPage.nextCursor });

    expect(secondPage.data.map((item) => item.id)).toEqual(['s2', 's3']);
    expect(secondPage.nextCursor).toBeNull();
    expect(thirdPartyPlaceQueryService.searchNearby).toHaveBeenCalledTimes(1); // not re-queried once exhausted
    // The resumed station query must have been given a cursor pointing after s1, not the beginning.
    const secondStationCall = stationQueryService.searchNearby.mock.calls[1][0];
    expect(secondStationCall.cursor).not.toBeNull();
  });

  it('keeps a source at its original cursor when none of its fetched items were consumed this page', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    // All 2 station items are farther than all 2 third-party items — station side is entirely unconsumed this page.
    stationQueryService.searchNearby.mockResolvedValueOnce({
      data: [stationItem('s1', 500), stationItem('s2', 600)],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValueOnce({
      data: [placeItem('p1', 10), placeItem('p2', 20)],
      nextCursor: 'tpp-more',
    });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.searchNearby({ ...CRITERIA, limit: 2 });

    expect(page.data.map((item) => item.id)).toEqual(['p1', 'p2']);
    expect(page.nextCursor).not.toBeNull();

    stationQueryService.searchNearby.mockResolvedValueOnce({
      data: [stationItem('s1', 500), stationItem('s2', 600)],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValueOnce({ data: [], nextCursor: null });
    await service.searchNearby({ ...CRITERIA, limit: 2, cursor: page.nextCursor });
    const secondStationCall = stationQueryService.searchNearby.mock.calls[1][0];
    // Station was never touched, so it must be re-queried from the same (null) starting point, not skipped.
    expect(secondStationCall.cursor).toBeNull();
  });

  it('marks a source exhausted after a filter combination that yields zero results (e.g. type=[rahati_unit] for third-party places), and never re-queries it on the next page', async () => {
    const stationQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { searchNearby: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    // Station side has more than fits in one page, so the merge must return a
    // non-null cursor even though third-party is fully (and permanently) empty.
    stationQueryService.searchNearby.mockResolvedValueOnce({
      data: [stationItem('s1', 10), stationItem('s2', 20)],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.searchNearby.mockResolvedValue({ data: [], nextCursor: null });
    const service = new PlacesQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.searchNearby({ ...CRITERIA, types: ['rahati_unit'], limit: 1 });
    expect(page.data.map((item) => item.id)).toEqual(['s1']);
    expect(page.nextCursor).not.toBeNull();
    expect(thirdPartyPlaceQueryService.searchNearby).toHaveBeenCalledTimes(1);

    stationQueryService.searchNearby.mockResolvedValueOnce({ data: [stationItem('s2', 20)], nextCursor: null });
    const secondPage = await service.searchNearby({ ...CRITERIA, types: ['rahati_unit'], limit: 1, cursor: page.nextCursor });

    expect(secondPage.data.map((item) => item.id)).toEqual(['s2']);
    // Still only ever called once — the second page must not re-query an already-exhausted source.
    expect(thirdPartyPlaceQueryService.searchNearby).toHaveBeenCalledTimes(1);
  });
});
