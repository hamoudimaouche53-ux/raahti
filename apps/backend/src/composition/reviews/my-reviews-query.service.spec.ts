import { StationQueryService, StationReviewListItem } from '../../modules/station-network/application/station-query.service';
import {
  ThirdPartyPlaceQueryService,
  ThirdPartyPlaceReviewListItem,
} from '../../modules/third-party-places/application/third-party-place-query.service';
import { MyReviewsQueryService } from './my-reviews-query.service';

function stationReview(id: string, createdAt: string): StationReviewListItem {
  return {
    id,
    placeId: 's1',
    placeName: { fr: 'ST-001', ar: 'ST-001', en: 'ST-001' },
    rating: 4,
    comment: null,
    createdAt: new Date(createdAt),
  };
}

function thirdPartyReview(id: string, createdAt: string): ThirdPartyPlaceReviewListItem {
  return {
    id,
    placeId: 'p1',
    placeName: { fr: 'Mosquée', ar: 'مسجد', en: 'Mosquée' },
    rating: 5,
    comment: null,
    createdAt: new Date(createdAt),
  };
}

describe('MyReviewsQueryService', () => {
  it('merges two sources into a single createdAt-desc-sorted page, tagging placeType', async () => {
    const stationQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.listReviewsByUserId.mockResolvedValue({
      data: [stationReview('s-r1', '2026-08-01T10:00:00.000Z')],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.listReviewsByUserId.mockResolvedValue({
      data: [thirdPartyReview('p-r1', '2026-08-02T10:00:00.000Z')],
      nextCursor: null,
    });
    const service = new MyReviewsQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.listForUser('u1', null, 10);

    expect(page.data.map((item) => item.id)).toEqual(['p-r1', 's-r1']); // newest (p-r1) first
    expect(page.data[0].placeType).toBe('third-party-place');
    expect(page.data[1].placeType).toBe('station');
    expect(page.nextCursor).toBeNull();
  });

  it('handles one source being empty', async () => {
    const stationQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.listReviewsByUserId.mockResolvedValue({
      data: [stationReview('s-r1', '2026-08-01T10:00:00.000Z')],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.listReviewsByUserId.mockResolvedValue({ data: [], nextCursor: null });
    const service = new MyReviewsQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.listForUser('u1', null, 10);

    expect(page.data.map((item) => item.id)).toEqual(['s-r1']);
    expect(page.nextCursor).toBeNull();
  });

  it('returns nextCursor null when both sources have no results at all', async () => {
    const stationQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.listReviewsByUserId.mockResolvedValue({ data: [], nextCursor: null });
    thirdPartyPlaceQueryService.listReviewsByUserId.mockResolvedValue({ data: [], nextCursor: null });
    const service = new MyReviewsQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const page = await service.listForUser('u1', null, 10);

    expect(page.data).toEqual([]);
    expect(page.nextCursor).toBeNull();
  });

  it('produces a non-null cursor and resumes correctly when a source has unconsumed leftover items', async () => {
    const stationQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<StationQueryService>;
    const thirdPartyPlaceQueryService = { listReviewsByUserId: jest.fn() } as unknown as jest.Mocked<ThirdPartyPlaceQueryService>;
    stationQueryService.listReviewsByUserId.mockResolvedValueOnce({
      data: [
        stationReview('s-r1', '2026-08-03T10:00:00.000Z'),
        stationReview('s-r2', '2026-08-01T10:00:00.000Z'),
        stationReview('s-r3', '2025-12-01T10:00:00.000Z'),
      ],
      nextCursor: null,
    });
    thirdPartyPlaceQueryService.listReviewsByUserId.mockResolvedValueOnce({
      data: [thirdPartyReview('p-r1', '2026-08-02T10:00:00.000Z')],
      nextCursor: null,
    });
    const service = new MyReviewsQueryService(stationQueryService, thirdPartyPlaceQueryService);

    const firstPage = await service.listForUser('u1', null, 2);
    expect(firstPage.data.map((item) => item.id)).toEqual(['s-r1', 'p-r1']);
    expect(firstPage.nextCursor).not.toBeNull();

    // Second page: third-party is now exhausted (fetched only p-r1, fully
    // consumed, its own nextCursor was null) and should not be re-queried;
    // station resumes after s-r1.
    stationQueryService.listReviewsByUserId.mockResolvedValueOnce({
      data: [stationReview('s-r2', '2026-08-01T10:00:00.000Z'), stationReview('s-r3', '2025-12-01T10:00:00.000Z')],
      nextCursor: null,
    });
    const secondPage = await service.listForUser('u1', firstPage.nextCursor, 2);

    expect(secondPage.data.map((item) => item.id)).toEqual(['s-r2', 's-r3']);
    expect(secondPage.nextCursor).toBeNull();
    expect(thirdPartyPlaceQueryService.listReviewsByUserId).toHaveBeenCalledTimes(1);
    const secondStationCall = stationQueryService.listReviewsByUserId.mock.calls[1];
    expect(secondStationCall[1]).not.toBeNull(); // resumed cursor, not from the beginning
  });
});
