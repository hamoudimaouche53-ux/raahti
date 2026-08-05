import { InvalidReviewRatingException, StationReview } from './review.entity';

describe('StationReview', () => {
  it('submits a review with a valid rating and optional comment', () => {
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 4, comment: 'Clean.' });
    expect(review.rating).toBe(4);
    expect(review.comment).toBe('Clean.');
  });

  it('defaults comment to null when omitted', () => {
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 5 });
    expect(review.comment).toBeNull();
  });

  it.each([0, 6, -1, 1.5])('rejects an out-of-range or non-integer rating %p', (rating) => {
    expect(() => StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating })).toThrow(
      InvalidReviewRatingException,
    );
  });

  it.each([1, 2, 3, 4, 5])('accepts every valid rating %p', (rating) => {
    expect(() => StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating })).not.toThrow();
  });
});
