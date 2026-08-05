import { InvalidReviewRatingException } from '../domain/entities/review.entity';
import { ThirdPartyPlaceReviewRepository } from '../domain/ports/third-party-place-review.repository';
import { ReviewService } from './review.service';

describe('ReviewService', () => {
  it('submits a review and persists it', async () => {
    const repo: jest.Mocked<ThirdPartyPlaceReviewRepository> = {
      save: jest.fn(),
      aggregateByThirdPartyPlaceId: jest.fn(),
    };
    const service = new ReviewService(repo);

    const review = await service.submit('u1', 'p1', { rating: 5 });

    expect(review.thirdPartyPlaceId).toBe('p1');
    expect(repo.save).toHaveBeenCalledWith(review);
  });

  it('rejects an invalid rating before persisting anything', async () => {
    const repo: jest.Mocked<ThirdPartyPlaceReviewRepository> = {
      save: jest.fn(),
      aggregateByThirdPartyPlaceId: jest.fn(),
    };
    const service = new ReviewService(repo);

    await expect(service.submit('u1', 'p1', { rating: -3 })).rejects.toThrow(InvalidReviewRatingException);
    expect(repo.save).not.toHaveBeenCalled();
  });
});
