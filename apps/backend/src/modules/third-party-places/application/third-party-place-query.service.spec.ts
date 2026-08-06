import { GeoPosition } from '../../../shared-kernel';
import { ThirdPartyPlace } from '../domain/entities/third-party-place.entity';
import { ThirdPartyPlaceRepository } from '../domain/ports/third-party-place.repository';
import { ThirdPartyPlaceReviewRepository } from '../domain/ports/third-party-place-review.repository';
import { ThirdPartyPlaceNotFoundException } from './third-party-place-not-found.exception';
import { ThirdPartyPlaceQueryService } from './third-party-place-query.service';

function aPlace(id = 'p1'): ThirdPartyPlace {
  return ThirdPartyPlace.restore({
    id,
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
  });
}

function createRepoMock(): jest.Mocked<ThirdPartyPlaceRepository> {
  return { findById: jest.fn(), searchNearby: jest.fn() };
}

function createReviewRepoMock(): jest.Mocked<ThirdPartyPlaceReviewRepository> {
  return { save: jest.fn(), findById: jest.fn(), listByUserId: jest.fn(), delete: jest.fn(), aggregateByThirdPartyPlaceId: jest.fn() };
}

describe('ThirdPartyPlaceQueryService', () => {
  it('returns the place when found', async () => {
    const repo = createRepoMock();
    repo.findById.mockResolvedValue(aPlace());
    const service = new ThirdPartyPlaceQueryService(repo, createReviewRepoMock());

    const place = await service.getById('p1');

    expect(place.id).toBe('p1');
  });

  it('throws ThirdPartyPlaceNotFoundException when missing', async () => {
    const repo = createRepoMock();
    repo.findById.mockResolvedValue(null);
    const service = new ThirdPartyPlaceQueryService(repo, createReviewRepoMock());

    await expect(service.getById('missing')).rejects.toThrow(ThirdPartyPlaceNotFoundException);
  });

  it('delegates getRatingAggregate to the review repository', async () => {
    const reviewRepo = createReviewRepoMock();
    reviewRepo.aggregateByThirdPartyPlaceId.mockResolvedValue({ averageRating: 3.5, reviewCount: 4 });
    const service = new ThirdPartyPlaceQueryService(createRepoMock(), reviewRepo);

    const aggregate = await service.getRatingAggregate('p1');

    expect(aggregate).toEqual({ averageRating: 3.5, reviewCount: 4 });
    expect(reviewRepo.aggregateByThirdPartyPlaceId).toHaveBeenCalledWith('p1');
  });

  describe('searchNearby', () => {
    it('maps a repository search result into a place-summary-shaped item', async () => {
      const repo = createRepoMock();
      repo.searchNearby.mockResolvedValue({
        data: [
          {
            id: 'p1',
            nameFr: 'Mosquée Al-Fath',
            nameAr: 'مسجد الفتح',
            placeType: 'mosque',
            position: GeoPosition.of(36.75, 3.05),
            distanceMeters: 300,
            isFree: true,
            declaredStatus: 'open',
            statusSource: 'community',
            tags: ['women_confirmed'],
            averageRating: 4.8,
            reviewCount: 10,
          },
        ],
        nextCursor: null,
      });
      const service = new ThirdPartyPlaceQueryService(repo, createReviewRepoMock());

      const page = await service.searchNearby({
        position: GeoPosition.of(36.75, 3.05),
        radiusMeters: 2000,
        types: [],
        limit: 30,
      });

      expect(page.data).toEqual([
        {
          id: 'p1',
          placeKind: 'third_party_place',
          name: { fr: 'Mosquée Al-Fath', ar: 'مسجد الفتح', en: 'Mosquée Al-Fath' },
          position: { lat: 36.75, lng: 3.05 },
          pinColor: 'magenta',
          distanceMeters: 300,
          isFree: true,
          averageRating: 4.8,
          reviewCount: 10,
          tags: ['women_confirmed'],
        },
      ]);
      expect(page.nextCursor).toBeNull();
    });
  });
});
