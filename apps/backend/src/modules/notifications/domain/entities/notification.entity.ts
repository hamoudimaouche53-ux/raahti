import { DomainException } from '../../../../shared-kernel';
import { NotificationChannel } from '../value-objects/notification-channel.vo';
import { NotificationStatus } from '../value-objects/notification-status.vo';
import { NotificationType } from '../value-objects/notification-type.vo';

export class InvalidNotificationStatusTransitionException extends DomainException {
  readonly code = 'NOTIFICATIONS_INVALID_STATUS_TRANSITION';
  readonly status = 400;

  constructor(from: NotificationStatus, to: NotificationStatus) {
    super(`Cannot transition a notification from "${from}" to "${to}".`);
  }
}

export class InconsistentReadStateException extends DomainException {
  readonly code = 'NOTIFICATIONS_INCONSISTENT_READ_STATE';
  readonly status = 400;

  constructor() {
    super('An unread notification must have readAt = null, and a read notification must have readAt set.');
  }
}

export interface NotificationProps {
  id: string;
  /** Nullable — ERD §3.14: "operator alerts may target a role, not a user". */
  userId: string | null;
  channel: NotificationChannel;
  type: NotificationType;
  relatedAlertId: string | null;
  relatedTransactionId: string | null;
  status: NotificationStatus;
  isRead: boolean;
  readAt: Date | null;
  createdAt: Date;
}

/**
 * Aggregate root of the Notifications bounded context (Domain Model §8).
 * `isRead`/`readAt` are an additive gap-fill confirmed with the user
 * (2026-08-05) — see prisma/schema.prisma's doc comment on the Notification
 * model for the full rationale.
 */
export class Notification {
  private constructor(private props: NotificationProps) {}

  static queue(params: {
    id: string;
    userId: string | null;
    channel: NotificationChannel;
    type: NotificationType;
    relatedAlertId?: string | null;
    relatedTransactionId?: string | null;
  }): Notification {
    return new Notification({
      id: params.id,
      userId: params.userId,
      channel: params.channel,
      type: params.type,
      relatedAlertId: params.relatedAlertId ?? null,
      relatedTransactionId: params.relatedTransactionId ?? null,
      status: 'queued',
      isRead: false,
      readAt: null,
      createdAt: new Date(),
    });
  }

  static restore(props: NotificationProps): Notification {
    if (props.isRead !== (props.readAt !== null)) {
      throw new InconsistentReadStateException();
    }
    return new Notification(props);
  }

  /** PATCH /users/me/notifications/{id} — idempotent: readAt is set once, never advanced on repeat calls. */
  markAsRead(): void {
    if (this.props.isRead) {
      return;
    }
    this.props = { ...this.props, isRead: true, readAt: new Date() };
  }

  markSent(): void {
    this.transitionTo('sent', ['queued']);
  }

  markDelivered(): void {
    this.transitionTo('delivered', ['sent']);
  }

  markFailed(): void {
    this.transitionTo('failed', ['queued', 'sent']);
  }

  private transitionTo(next: NotificationStatus, allowedFrom: NotificationStatus[]): void {
    if (!allowedFrom.includes(this.props.status)) {
      throw new InvalidNotificationStatusTransitionException(this.props.status, next);
    }
    this.props = { ...this.props, status: next };
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string | null {
    return this.props.userId;
  }

  get channel(): NotificationChannel {
    return this.props.channel;
  }

  get type(): NotificationType {
    return this.props.type;
  }

  get relatedAlertId(): string | null {
    return this.props.relatedAlertId;
  }

  get relatedTransactionId(): string | null {
    return this.props.relatedTransactionId;
  }

  get status(): NotificationStatus {
    return this.props.status;
  }

  get isRead(): boolean {
    return this.props.isRead;
  }

  get readAt(): Date | null {
    return this.props.readAt;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }
}
