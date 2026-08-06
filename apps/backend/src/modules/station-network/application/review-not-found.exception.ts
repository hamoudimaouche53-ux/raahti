import { DomainException } from '../../../shared-kernel';

/** Also thrown when a review id exists but belongs to a different station (defense-in-depth — never leaks existence across places). */
export class ReviewNotFoundException extends DomainException {
  readonly code = 'STATION_NETWORK_REVIEW_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Review ${id} was not found.`);
  }
}
