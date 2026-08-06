import { DomainException, Money } from '../../../../shared-kernel';
import { TransactionStatus } from '../value-objects/transaction-status.vo';

export class InvalidTransactionStatusTransitionException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_INVALID_TRANSACTION_STATUS_TRANSITION';
  readonly status = 400;

  constructor(from: TransactionStatus, to: TransactionStatus) {
    super(`Cannot transition a transaction from "${from}" to "${to}".`);
  }
}

export interface TransactionProps {
  id: string;
  userId: string;
  accessSessionId: string | null;
  paymentMethodId: string | null;
  amount: Money;
  /** Percentage (0-100), ERD §3.10 `discount_applied` — see DiscountRate VO. Null when no discount applied. */
  discountApplied: number | null;
  status: TransactionStatus;
  providerRef: string | null;
  createdAt: Date;
}

/**
 * Separate aggregate from `AccessSession` (Domain Model §6: "AccessSession
 * (owns its optional Transaction)" — the Transaction entity itself is a
 * distinct aggregate root per ERD §3.10's own reasoning: "a free-access
 * session produces no transaction row, while a subscription transaction may
 * exist without a specific access session", hence `accessSessionId` is
 * nullable here too, mirroring the schema).
 */
export class Transaction {
  private static readonly TRANSITIONS: Readonly<Record<TransactionStatus, readonly TransactionStatus[]>> = {
    pending: ['authorized', 'failed'],
    authorized: ['captured', 'failed'],
    captured: ['refunded'],
    failed: [],
    refunded: [],
  };

  private constructor(private props: TransactionProps) {}

  static pending(params: {
    id: string;
    userId: string;
    accessSessionId?: string | null;
    paymentMethodId?: string | null;
    amount: Money;
    discountApplied?: number | null;
  }): Transaction {
    return new Transaction({
      id: params.id,
      userId: params.userId,
      accessSessionId: params.accessSessionId ?? null,
      paymentMethodId: params.paymentMethodId ?? null,
      amount: params.amount,
      discountApplied: params.discountApplied ?? null,
      status: 'pending',
      providerRef: null,
      createdAt: new Date(),
    });
  }

  static restore(props: TransactionProps): Transaction {
    return new Transaction(props);
  }

  /** PaymentGateway.authorize() succeeded — ADR-0014. */
  authorize(providerRef: string): void {
    this.transitionTo('authorized');
    this.props = { ...this.props, providerRef };
  }

  /** PaymentGateway.capture() succeeded. */
  capture(): void {
    this.transitionTo('captured');
  }

  /** PaymentGateway.authorize()/capture() declined or errored (402 PaymentDeclinedException). */
  fail(): void {
    this.transitionTo('failed');
  }

  /** Risk R-12 refund-on-unlock-failure path (ADR-0014) — PaymentGateway.refund() succeeded. */
  refund(): void {
    this.transitionTo('refunded');
  }

  private transitionTo(next: TransactionStatus): void {
    const allowed = Transaction.TRANSITIONS[this.props.status];
    if (!allowed.includes(next)) {
      throw new InvalidTransactionStatusTransitionException(this.props.status, next);
    }
    this.props = { ...this.props, status: next };
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string {
    return this.props.userId;
  }

  get accessSessionId(): string | null {
    return this.props.accessSessionId;
  }

  get paymentMethodId(): string | null {
    return this.props.paymentMethodId;
  }

  get amount(): Money {
    return this.props.amount;
  }

  get discountApplied(): number | null {
    return this.props.discountApplied;
  }

  get status(): TransactionStatus {
    return this.props.status;
  }

  get providerRef(): string | null {
    return this.props.providerRef;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }
}
