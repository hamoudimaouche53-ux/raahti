import { DomainException } from '../../../shared-kernel';

/** Thrown when the authenticated caller is not the author of the review they're acting on. */
export class ReviewForbiddenException extends DomainException {
  readonly code = 'STATION_NETWORK_REVIEW_FORBIDDEN';
  readonly status = 403;

  constructor(id: string) {
    super(`Caller is not permitted to act on review ${id}.`);
  }
}
