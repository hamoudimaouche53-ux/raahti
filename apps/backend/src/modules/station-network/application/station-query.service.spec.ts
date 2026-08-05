import { GeoPosition } from '../../../shared-kernel';
import { Station } from '../domain/entities/station.entity';
import { StationRepository } from '../domain/ports/station.repository';
import { StationReviewRepository } from '../domain/ports/station-review.repository';
import { StationNotFoundException } from './station-not-found.exception';
import { StationQueryService } from './station-query.service';

function aStation(id = 's1'): Station {
  return Station.restore({
    id,
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
  });
}

function createRepoMock(): jest.Mocked<StationRepository> {
  return { findById: jest.fn(), searchNearby: jest.fn() };
}

function createReviewRepoMock(): jest.Mocked<StationReviewRepository> {
  return { save: jest.fn(), aggregateByStationId: jest.fn() };
}

describe('StationQueryService', () => {
  it('returns the station when found', async () => {
    const repo = createRepoMock();
    repo.findById.mockResolvedValue(aStation());
    const service = new StationQueryService(repo, createReviewRepoMock());

    const station = await service.getById('s1');

    expect(station.id).toBe('s1');
  });

  it('throws StationNotFoundException when missing', async () => {
    const repo = createRepoMock();
    repo.findById.mockResolvedValue(null);
    const service = new StationQueryService(repo, createReviewRepoMock());

    await expect(service.getById('missing')).rejects.toThrow(StationNotFoundException);
  });

  it('delegates getRatingAggregate to the review repository', async () => {
    const reviewRepo = createReviewRepoMock();
    reviewRepo.aggregateByStationId.mockResolvedValue({ averageRating: 4.5, reviewCount: 2 });
    const service = new StationQueryService(createRepoMock(), reviewRepo);

    const aggregate = await service.getRatingAggregate('s1');

    expect(aggregate).toEqual({ averageRating: 4.5, reviewCount: 2 });
    expect(reviewRepo.aggregateByStationId).toHaveBeenCalledWith('s1');
  });

  describe('searchNearby', () => {
    it('maps a repository search result into a place-summary-shaped item', async () => {
      const repo = createRepoMock();
      repo.searchNearby.mockResolvedValue({
        data: [
          {
            id: 's1',
            code: 'ST-001',
            configuration: 'fixe',
            status: 'active',
            position: GeoPosition.of(36.75, 3.05),
            distanceMeters: 120,
            hasSlatokiTent: true,
            cabinPricingMix: 'all_free',
            averageRating: 4.2,
            reviewCount: 5,
          },
        ],
        nextCursor: 'cursor-1',
      });
      const service = new StationQueryService(repo, createReviewRepoMock());

      const page = await service.searchNearby({
        position: GeoPosition.of(36.75, 3.05),
        radiusMeters: 2000,
        types: [],
        limit: 30,
      });

      expect(page.data).toEqual([
        {
          id: 's1',
          placeKind: 'station',
          name: { fr: 'ST-001', ar: 'ST-001', en: 'ST-001' },
          position: { lat: 36.75, lng: 3.05 },
          pinColor: 'magenta',
          distanceMeters: 120,
          isFree: true,
          averageRating: 4.2,
          reviewCount: 5,
          tags: [],
          hasSlatokiTent: true,
        },
      ]);
      expect(page.nextCursor).toBe('cursor-1');
    });
  });
});
