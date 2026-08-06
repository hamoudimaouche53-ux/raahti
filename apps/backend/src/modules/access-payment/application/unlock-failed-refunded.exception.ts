import { DomainException } from '../../../shared-kernel';

/**
 * Risk R-12 / ADR-0014 / Sequence Diagrams §1's "Unlock times out / fails"
 * branch — maps to `502 ProblemDetail{code: UNLOCK_FAILED_REFUNDED}`
 * exactly as the sequence diagram documents. Used uniformly for both the
 * paid-cabin path (payment was captured, then refunded, because the unlock
 * order failed) and the free-cabin path (no payment ever existed, but the
 * unlock order still failed) — the sequence diagram's failure branch sits
 * after the paid/free split rejoins, with no distinct free-cabin failure
 * code documented, so this exception (and its "refunded" wording) is reused
 * for both; a free-cabin failure simply has nothing to refund. Flagged as a
 * judgment call, not a silently invented second code.
 */
export class UnlockFailedRefundedException extends DomainException {
  readonly code = 'UNLOCK_FAILED_REFUNDED';
  readonly status = 502;

  constructor(accessSessionId: string) {
    super(`Unlock order failed for access session ${accessSessionId}.`);
  }
}
