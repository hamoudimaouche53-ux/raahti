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

  it('update() mutates rating and comment in place', () => {
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 3, comment: 'Correct.' });

    review.update(5, 'Actually excellent.');

    expect(review.rating).toBe(5);
    expect(review.comment).toBe('Actually excellent.');
    expect(review.id).toBe('r1');
    expect(review.userId).toBe('u1');
    expect(review.stationId).toBe('s1');
  });

  it('update() defaults comment to null when omitted', () => {
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 3, comment: 'Old.' });

    review.update(4);

    expect(review.comment).toBeNull();
  });

  it.each([0, 6, -1, 1.5])('update() rejects an out-of-range or non-integer rating %p', (rating) => {
    const review = StationReview.submit({ id: 'r1', userId: 'u1', stationId: 's1', rating: 3 });
    expect(() => review.update(rating)).toThrow(InvalidReviewRatingException);
    expect(review.rating).toBe(3); // rejected update leaves the review unchanged
  });
});
