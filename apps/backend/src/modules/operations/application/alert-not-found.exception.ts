import { DomainException } from '../../../shared-kernel';

export class AlertNotFoundException extends DomainException {
  readonly code = 'OPERATIONS_ALERT_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Alert ${id} was not found.`);
  }
}
