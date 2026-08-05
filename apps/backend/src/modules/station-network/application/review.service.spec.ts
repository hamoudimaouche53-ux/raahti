import { StationReviewRepository } from '../domain/ports/station-review.repository';
import { InvalidReviewRatingException } from '../domain/entities/review.entity';
import { ReviewService } from './review.service';

describe('ReviewService', () => {
  it('submits a review and persists it', async () => {
    const repo: jest.Mocked<StationReviewRepository> = { save: jest.fn(), aggregateByStationId: jest.fn() };
    const service = new ReviewService(repo);

    const review = await service.submit('u1', 's1', { rating: 4, comment: 'Good.' });

    expect(review.stationId).toBe('s1');
    expect(review.userId).toBe('u1');
    expect(repo.save).toHaveBeenCalledWith(review);
  });

  it('rejects an invalid rating before persisting anything', async () => {
    const repo: jest.Mocked<StationReviewRepository> = { save: jest.fn(), aggregateByStationId: jest.fn() };
    const service = new ReviewService(repo);

    await expect(service.submit('u1', 's1', { rating: 9 })).rejects.toThrow(InvalidReviewRatingException);
    expect(repo.save).not.toHaveBeenCalled();
  });
});
