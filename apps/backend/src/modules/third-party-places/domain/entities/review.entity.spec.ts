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

  it('update() mutates rating and comment in place', () => {
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 3, comment: 'Bruyant.' });

    review.update(5, 'Finalement calme.');

    expect(review.rating).toBe(5);
    expect(review.comment).toBe('Finalement calme.');
    expect(review.thirdPartyPlaceId).toBe('p1');
  });

  it('update() defaults comment to null when omitted', () => {
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 3, comment: 'Old.' });

    review.update(4);

    expect(review.comment).toBeNull();
  });

  it.each([0, 6, -1, 2.5])('update() rejects an out-of-range or non-integer rating %p', (rating) => {
    const review = ThirdPartyPlaceReview.submit({ id: 'r1', userId: 'u1', thirdPartyPlaceId: 'p1', rating: 3 });
    expect(() => review.update(rating)).toThrow(InvalidReviewRatingException);
    expect(review.rating).toBe(3);
  });
});
