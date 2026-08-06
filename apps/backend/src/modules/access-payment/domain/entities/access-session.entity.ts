import { DomainException } from '../../../../shared-kernel';
import { AccessSessionStatus } from '../value-objects/access-session-status.vo';

export class InvalidAccessSessionStatusTransitionException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_INVALID_ACCESS_SESSION_STATUS_TRANSITION';
  readonly status = 400;

  constructor(from: AccessSessionStatus, to: AccessSessionStatus) {
    super(`Cannot transition an access session from "${from}" to "${to}".`);
  }
}

export interface AccessSessionProps {
  id: string;
  cabinId: string;
  userId: string | null;
  status: AccessSessionStatus;
  qrCodeScanned: string;
  startedAt: Date;
  unlockedAt: Date | null;
  closedAt: Date | null;
}

/**
 * Aggregate root of the Access & Payment bounded context (Domain Model §6):
 * "owns the QR-scan-to-unlock journey and the transactional record of
 * payment... owns its optional Transaction". `userId` is nullable —
 * `AccessSessionCreateRequest`/openapi.yaml never documents a guest-access
 * path being blocked, and FR-USR-01's optional-account model (same
 * precedent as Notification.userId) means an unauthenticated scan is not
 * structurally impossible even though every route in this module currently
 * sits behind the global JwtAuthGuard — flagged as forward-compatible
 * modeling, not a currently-reachable path.
 *
 * Transition graph (Domain Model §6 doesn't specify the exact graph, only
 * the 6 status values and one invariant: "UnlockOrderIssued may only follow
 * either a free-cabin AccessSessionInitiated or a PaymentCaptured — never
 * precede payment for a paid cabin"): `initiated` can go straight to
 * `unlocked` (the free-cabin path, skipping payment_pending entirely) or to
 * `payment_pending` (the paid-cabin path) or `cancelled`. `unlocked` can go
 * to `in_use` or straight to `completed` (manual "J'ai terminé" — ADR-0030 —
 * can arrive before any `in_use` transition is ever issued, since nothing in
 * this pass calls `markInUse` from an HTTP entry point; kept for domain
 * completeness, same treatment as Operations' `Alert.raise()`/
 * `MaintenanceIntervention.start()`).
 */
export class AccessSession {
  private static readonly TRANSITIONS: Readonly<Record<AccessSessionStatus, readonly AccessSessionStatus[]>> = {
    initiated: ['payment_pending', 'unlocked', 'cancelled'],
    payment_pending: ['unlocked', 'cancelled'],
    unlocked: ['in_use', 'completed'],
    in_use: ['completed'],
    completed: [],
    cancelled: [],
  };

  private constructor(private props: AccessSessionProps) {}

  static initiate(params: { id: string; cabinId: string; userId: string | null; qrCodeScanned: string }): AccessSession {
    return new AccessSession({
      id: params.id,
      cabinId: params.cabinId,
      userId: params.userId,
      status: 'initiated',
      qrCodeScanned: params.qrCodeScanned,
      startedAt: new Date(),
      unlockedAt: null,
      closedAt: null,
    });
  }

  static restore(props: AccessSessionProps): AccessSession {
    return new AccessSession(props);
  }

  /** Paid-cabin path, immediately before POST /access-sessions/{id}/payments attempts payment. */
  markPaymentPending(): void {
    this.transitionTo('payment_pending');
  }

  /** Either the free-cabin direct path or the post-capture paid path — both converge here (Domain Model §6 invariant). */
  markUnlocked(): void {
    this.transitionTo('unlocked');
    this.props = { ...this.props, unlockedAt: new Date() };
  }

  /** Domain completeness — no HTTP entry point issues this transition in this pass (see class doc comment). */
  markInUse(): void {
    this.transitionTo('in_use');
  }

  /** POST /access-sessions/{id}/complete (ADR-0030's manual "J'ai terminé" path). */
  complete(): void {
    this.transitionTo('completed');
    this.props = { ...this.props, closedAt: new Date() };
  }

  cancel(): void {
    this.transitionTo('cancelled');
  }

  private transitionTo(next: AccessSessionStatus): void {
    const allowed = AccessSession.TRANSITIONS[this.props.status];
    if (!allowed.includes(next)) {
      throw new InvalidAccessSessionStatusTransitionException(this.props.status, next);
    }
    this.props = { ...this.props, status: next };
  }

  get id(): string {
    return this.props.id;
  }

  get cabinId(): string {
    return this.props.cabinId;
  }

  get userId(): string | null {
    return this.props.userId;
  }

  get status(): AccessSessionStatus {
    return this.props.status;
  }

  get qrCodeScanned(): string {
    return this.props.qrCodeScanned;
  }

  get startedAt(): Date {
    return this.props.startedAt;
  }

  get unlockedAt(): Date | null {
    return this.props.unlockedAt;
  }

  get closedAt(): Date | null {
    return this.props.closedAt;
  }
}
