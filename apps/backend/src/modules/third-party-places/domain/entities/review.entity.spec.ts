import { InvalidReviewRatingException, ThirdPartyPlaceReview } from './review.entity';

describe('ThirdPartyPlaceReview', () => {
  it('submits a review with a valid rating and optional comment', () => {
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 4, comment: 'Calme.' });
    expect(review.rating).toBe(4);
    expect(review.comment).toBe('Calme.');
  });

  it('defaults comment to null when omitted', () => {
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 5 });
    expect(review.comment).toBeNull();
  });

  it.each([0, 6, -1, 2.5])('rejects an out-of-range or non-integer rating %p', (rating) => {
    expect(() => ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating })).toThrow(
      InvalidReviewRatingException,
    );
  });
});
