import { GeoPosition, Money } from '../../../shared-kernel';
import { Cabin } from '../domain/entities/cabin.entity';
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
  return {
    findById: jest.fn(),
    searchNearby: jest.fn(),
    findAll: jest.fn(),
    findCabinById: jest.fn(),
    updateCabinOccupancy: jest.fn(),
    findNearestAccessible: jest.fn(),
  };
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

  describe('findNearestAccessible', () => {
    it('returns null when no station is within the emergency search radius', async () => {
      const repo = createRepoMock();
      repo.findNearestAccessible.mockResolvedValue(null);
      const service = new StationQueryService(repo, createReviewRepoMock());

      const result = await service.findNearestAccessible(GeoPosition.of(36.75, 3.05));

      expect(result).toBeNull();
    });

    it('maps the winning station into a place-summary-shaped item and passes through the picked cabin id', async () => {
      const repo = createRepoMock();
      repo.findNearestAccessible.mockResolvedValue({
        station: {
          id: 's1',
          code: 'ST-001',
          configuration: 'fixe',
          status: 'active',
          position: GeoPosition.of(36.75, 3.05),
          distanceMeters: 500,
          hasSlatokiTent: false,
          cabinPricingMix: 'all_paid',
          averageRating: null,
          reviewCount: 0,
        },
        nearestCabinId: 'c1',
      });
      const service = new StationQueryService(repo, createReviewRepoMock());

      const result = await service.findNearestAccessible(GeoPosition.of(36.75, 3.05));

      expect(result).toEqual({
        place: {
          id: 's1',
          placeKind: 'station',
          name: { fr: 'ST-001', ar: 'ST-001', en: 'ST-001' },
          position: { lat: 36.75, lng: 3.05 },
          pinColor: 'blue',
          distanceMeters: 500,
          isFree: false,
          averageRating: null,
          reviewCount: 0,
          tags: [],
          hasSlatokiTent: false,
        },
        nearestCabinId: 'c1',
      });
    });

    it('calls the repository with the fixed 20km emergency search radius', async () => {
      const repo = createRepoMock();
      repo.findNearestAccessible.mockResolvedValue(null);
      const service = new StationQueryService(repo, createReviewRepoMock());
      const position = GeoPosition.of(36.75, 3.05);

      await service.findNearestAccessible(position);

      expect(repo.findNearestAccessible).toHaveBeenCalledWith(position, 20_000);
    });

    it('returns nearestCabinId null when the station has no accessible cabin', async () => {
      const repo = createRepoMock();
      repo.findNearestAccessible.mockResolvedValue({
        station: {
          id: 's1',
          code: 'ST-001',
          configuration: 'fixe',
          status: 'active',
          position: GeoPosition.of(36.75, 3.05),
          distanceMeters: 500,
          hasSlatokiTent: false,
          cabinPricingMix: 'no_cabins',
          averageRating: null,
          reviewCount: 0,
        },
        nearestCabinId: null,
      });
      const service = new StationQueryService(repo, createReviewRepoMock());

      const result = await service.findNearestAccessible(GeoPosition.of(36.75, 3.05));

      expect(result?.nearestCabinId).toBeNull();
    });
  });

  describe('listAllForFleetView', () => {
    it('projects stations/cabins into a plain summary shape (Operations FR-OPS-01)', async () => {
      const repo = createRepoMock();
      const cabin = Cabin.restore({
        id: 'c1',
        stationId: 's1',
        code: 'C-01',
        type: 'F',
        occupancyStatus: 'occupied',
        isPaid: true,
        price: Money.fromDecimalString('50.00', 'DZD'),
      });
      repo.findAll.mockResolvedValue([
        Station.restore({
          id: 's1',
          code: 'ST-001',
          configuration: 'fixe',
          position: GeoPosition.of(36.75, 3.05),
          status: 'active',
          cabinCapacity: 1,
          tankCapacityLiters: 0,
          installedAt: new Date(),
          createdAt: new Date(),
          updatedAt: new Date(),
          cabins: [cabin],
          slatokiTent: null,
        }),
      ]);
      const service = new StationQueryService(repo, createReviewRepoMock());

      const summaries = await service.listAllForFleetView();

      expect(summaries).toEqual([
        {
          stationId: 's1',
          status: 'active',
          cabins: [
            {
              id: 'c1',
              code: 'C-01',
              type: 'F',
              occupancyStatus: 'occupied',
              isPaid: true,
              price: expect.any(Money),
            },
          ],
        },
      ]);
      expect(summaries[0].cabins[0].price?.toDecimalString()).toBe('50.00');
    });
  });
});
