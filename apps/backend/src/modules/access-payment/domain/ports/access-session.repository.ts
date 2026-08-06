import { Money } from '../../../../shared-kernel';
import { AccessSession } from '../entities/access-session.entity';

export const ACCESS_SESSION_REPOSITORY = Symbol('ACCESS_SESSION_REPOSITORY');

/** One completed visit, backing GET /users/me/visit-history (EPIC-05 US-05.2). */
export interface VisitHistoryRow {
  id: string;
  cabinId: string;
  closedAt: Date;
  /** From the session's Transaction (if any) — null for free-cabin visits (Domain Model §6). */
  amount: Money | null;
}

export interface VisitHistoryPage {
  data: VisitHistoryRow[];
  nextCursor: string | null;
}

export interface AccessSessionRepository {
  save(session: AccessSession): Promise<AccessSession>;
  findById(id: string): Promise<AccessSession | null>;
  /** ERD §3.10 "idx_access_session_cabin_status" — used by the availability check (FR-PAY-02). */
  findActiveByCabinId(cabinId: string): Promise<AccessSession | null>;
  /**
   * `completed` access sessions for a user, most-recent-first, cursor-paginated
   * (api-architecture.md §6) — backs GET /users/me/visit-history (EPIC-05
   * US-05.2). Only `completed` counts as a visit; in-progress sessions
   * (`initiated`/`payment_pending`/`unlocked`/`in_use`) are excluded, a
   * judgment call (no source document specifies this) since only `completed`
   * has a meaningful `closedAt` to sort/display.
   */
  listVisitHistoryForUser(userId: string, cursor: string | null, limit: number): Promise<VisitHistoryPage>;
}
