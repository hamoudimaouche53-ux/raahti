import { DomainException } from '../../../shared-kernel';

/** Thrown when the authenticated caller is not the owner of the access session they're acting on. */
export class AccessSessionForbiddenException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_ACCESS_SESSION_FORBIDDEN';
  readonly status = 403;

  constructor(accessSessionId: string) {
    super(`Caller is not permitted to act on access session ${accessSessionId}.`);
  }
}
