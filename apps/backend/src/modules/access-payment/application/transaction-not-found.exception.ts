import { DomainException } from '../../../shared-kernel';

export class TransactionNotFoundException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_TRANSACTION_NOT_FOUND';
  readonly status = 404;

  constructor(id: string) {
    super(`Transaction ${id} was not found.`);
  }
}
