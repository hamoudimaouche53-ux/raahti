import { InvalidReviewRatingException, ThirdPartyPlaceReview } from '../domain/entities/review.entity';
import { ThirdPartyPlaceReviewRepository } from '../domain/ports/third-party-place-review.repository';
import { ReviewForbiddenException } from './review-forbidden.exception';
import { ReviewNotFoundException } from './review-not-found.exception';
import { ReviewService } from './review.service';

function createRepoMock(): jest.Mocked<ThirdPartyPlaceReviewRepository> {
  return {
    save: jest.fn(),
    findById: jest.fn(),
    listByUserId: jest.fn(),
    delete: jest.fn(),
    aggregateByThirdPartyPlaceId: jest.fn(),
  };
}

describe('ReviewService', () => {
  it('submits a review and persists it', async () => {
    const repo = createRepoMock();
    const service = new ReviewService(repo);

    const review = await service.submit('u1', 'p1', { rating: 5 });

    expect(review.thirdPartyPlaceId).toBe('p1');
    expect(repo.save).toHaveBeenCalledWith(review);
  });

  it('rejects an invalid rating before persisting anything', async () => {
    const repo = createRepoMock();
    const service = new ReviewService(repo);

    await expect(service.submit('u1', 'p1', { rating: -3 })).rejects.toThrow(InvalidReviewRatingException);
    expect(repo.save).not.toHaveBeenCalled();
  });

  describe('update', () => {
    it("updates the owner's own review and persists the change", async () => {
      const repo = createRepoMock();
      const existing = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 2, comment: 'Meh.' });
      repo.findById.mockResolvedValue(existing);
      const service = new ReviewService(repo);

      const updated = await service.update('u1', 'p1', 'r1', { rating: 5, comment: 'Great now.' });

      expect(updated.rating).toBe(5);
      expect(updated.comment).toBe('Great now.');
      expect(repo.save).toHaveBeenCalledWith(existing);
    });

    it('throws ReviewNotFoundException when the review does not exist', async () => {
      const repo = createRepoMock();
      repo.findById.mockResolvedValue(null);
      const service = new ReviewService(repo);

      await expect(service.update('u1', 'p1', 'missing', { rating: 5 })).rejects.toThrow(ReviewNotFoundException);
      expect(repo.save).not.toHaveBeenCalled();
    });

    it('throws ReviewNotFoundException (not Forbidden) when the review belongs to a different place', async () => {
      const repo = createRepoMock();
      const existing = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p-other', rating: 2 });
      repo.findById.mockResolvedValue(existing);
      const service = new ReviewService(repo);

      await expect(service.update('u1', 'p1', 'r1', { rating: 5 })).rejects.toThrow(ReviewNotFoundException);
    });

    it('throws ReviewForbiddenException when the caller is not the review author', async () => {
      const repo = createRepoMock();
      const existing = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'owner', thirdPartyPlaceId: 'p1', rating: 2 });
      repo.findById.mockResolvedValue(existing);
      const service = new ReviewService(repo);

      await expect(service.update('someone-else', 'p1', 'r1', { rating: 5 })).rejects.toThrow(ReviewForbiddenException);
      expect(repo.save).not.toHaveBeenCalled();
    });
  });

  describe('delete', () => {
    it("deletes the owner's own review", async () => {
      const repo = createRepoMock();
      const existing = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 2 });
      repo.findById.mockResolvedValue(existing);
      const service = new ReviewService(repo);

      await service.delete('u1', 'p1', 'r1');

      expect(repo.delete).toHaveBeenCalledWith('r1');
    });

    it('throws ReviewNotFoundException when the review does not exist', async () => {
      const repo = createRepoMock();
      repo.findById.mockResolvedValue(null);
      const service = new ReviewService(repo);

      await expect(service.delete('u1', 'p1', 'missing')).rejects.toThrow(ReviewNotFoundException);
      expect(repo.delete).not.toHaveBeenCalled();
    });

    it('throws ReviewForbiddenException when the caller is not the review author', async () => {
      const repo = createRepoMock();
      const existing = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'owner', thirdPartyPlaceId: 'p1', rating: 2 });
      repo.findById.mockResolvedValue(existing);
      const service = new ReviewService(repo);

      await expect(service.delete('someone-else', 'p1', 'r1')).rejects.toThrow(ReviewForbiddenException);
      expect(repo.delete).not.toHaveBeenCalled();
    });
  });

  describe('listByUserId', () => {
    it('delegates directly to the repository', async () => {
      const repo = createRepoMock();
      const page = { data: [], nextCursor: null };
      repo.listByUserId.mockResolvedValue(page);
      const service = new ReviewService(repo);

      const result = await service.listByUserId('u1', null, 20);

      expect(result).toBe(page);
      expect(repo.listByUserId).toHaveBeenCalledWith('u1', null, 20);
    });
  });
});
