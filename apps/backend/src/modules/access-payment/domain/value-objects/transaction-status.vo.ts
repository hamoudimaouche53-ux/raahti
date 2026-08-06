import { DomainException } from '../../../../shared-kernel';

/** ERD §3.10. Transition graph enforced in domain/entities/transaction.entity.ts. */
export type TransactionStatus = 'pending' | 'authorized' | 'captured' | 'failed' | 'refunded';

const VALID: readonly TransactionStatus[] = ['pending', 'authorized', 'captured', 'failed', 'refunded'];

export class InvalidTransactionStatusException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_INVALID_TRANSACTION_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized transaction status (expected pending|authorized|captured|failed|refunded).`);
  }
}

export function assertTransactionStatus(value: string): asserts value is TransactionStatus {
  if (!VALID.includes(value as TransactionStatus)) {
    throw new InvalidTransactionStatusException(value);
  }
}
