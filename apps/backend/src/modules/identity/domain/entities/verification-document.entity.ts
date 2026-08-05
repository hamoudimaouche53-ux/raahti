import { DomainException } from '../../../../shared-kernel';

export type VerificationReviewStatus = 'pending' | 'approved' | 'rejected';

export class InvalidVerificationReviewTransitionException extends DomainException {
  readonly code = 'IDENTITY_INVALID_VERIFICATION_REVIEW_TRANSITION';
  readonly status = 400;

  constructor(from: VerificationReviewStatus, to: VerificationReviewStatus) {
    super(`Cannot transition a verification document from "${from}" to "${to}".`);
  }
}

export interface VerificationDocumentProps {
  id: string;
  userId: string;
  documentType: string;
  storageRef: string;
  reviewStatus: VerificationReviewStatus;
  reviewedBy: string | null;
  submittedAt: Date;
  reviewedAt: Date | null;
}

/**
 * ERD §3.9. Clinical verification logic is out of scope (ADR-0010) — this entity
 * only owns the submission/review data-shape invariant: pending -> approved/rejected,
 * never backward (Domain Model §2 invariant).
 */
export class VerificationDocument {
  private constructor(private props: VerificationDocumentProps) {}

  static submit(params: { id: string; userId: string; documentType: string; storageRef: string }): VerificationDocument {
    return new VerificationDocument({
      id: params.id,
      userId: params.userId,
      documentType: params.documentType,
      storageRef: params.storageRef,
      reviewStatus: 'pending',
      reviewedBy: null,
      submittedAt: new Date(),
      reviewedAt: null,
    });
  }

  static restore(props: VerificationDocumentProps): VerificationDocument {
    return new VerificationDocument(props);
  }

  private transitionTo(next: VerificationReviewStatus, reviewerId: string): void {
    if (this.props.reviewStatus !== 'pending') {
      throw new InvalidVerificationReviewTransitionException(this.props.reviewStatus, next);
    }
    this.props = { ...this.props, reviewStatus: next, reviewedBy: reviewerId, reviewedAt: new Date() };
  }

  approve(reviewerId: string): void {
    this.transitionTo('approved', reviewerId);
  }

  reject(reviewerId: string): void {
    this.transitionTo('rejected', reviewerId);
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string {
    return this.props.userId;
  }

  get documentType(): string {
    return this.props.documentType;
  }

  get storageRef(): string {
    return this.props.storageRef;
  }

  get reviewStatus(): VerificationReviewStatus {
    return this.props.reviewStatus;
  }

  get submittedAt(): Date {
    return this.props.submittedAt;
  }

  get reviewedAt(): Date | null {
    return this.props.reviewedAt;
  }
}
