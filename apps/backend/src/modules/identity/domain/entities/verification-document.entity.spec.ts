import { InvalidVerificationReviewTransitionException, VerificationDocument } from './verification-document.entity';

describe('VerificationDocument', () => {
  it('starts as pending on submission', () => {
    const doc = VerificationDocument.submit({
      id: 'd1',
      userId: 'u1',
      documentType: 'diabetic_certificate',
      storageRef: 'storage://doc1',
    });
    expect(doc.reviewStatus).toBe('pending');
    expect(doc.reviewedAt).toBeNull();
  });

  it('transitions pending -> approved', () => {
    const doc = VerificationDocument.submit({ id: 'd1', userId: 'u1', documentType: 'diabetic_certificate', storageRef: 's' });
    doc.approve('admin1');
    expect(doc.reviewStatus).toBe('approved');
    expect(doc.reviewedAt).not.toBeNull();
  });

  it('transitions pending -> rejected', () => {
    const doc = VerificationDocument.submit({ id: 'd1', userId: 'u1', documentType: 'diabetic_certificate', storageRef: 's' });
    doc.reject('admin1');
    expect(doc.reviewStatus).toBe('rejected');
  });

  it('never transitions backward once approved', () => {
    const doc = VerificationDocument.submit({ id: 'd1', userId: 'u1', documentType: 'diabetic_certificate', storageRef: 's' });
    doc.approve('admin1');
    expect(() => doc.reject('admin1')).toThrow(InvalidVerificationReviewTransitionException);
  });

  it('never transitions backward once rejected', () => {
    const doc = VerificationDocument.submit({ id: 'd1', userId: 'u1', documentType: 'diabetic_certificate', storageRef: 's' });
    doc.reject('admin1');
    expect(() => doc.approve('admin1')).toThrow(InvalidVerificationReviewTransitionException);
  });
});
