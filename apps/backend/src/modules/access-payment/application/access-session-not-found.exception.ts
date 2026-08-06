import { DomainException } from '../../../shared-kernel';

export class AccessSessionNotFoundException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_ACCESS_SESSION_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Access session ${id} was not found.`);
  }
}
