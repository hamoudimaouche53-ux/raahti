import { AccessSession } from '../entities/access-session.entity';

export const ACCESS_SESSION_REPOSITORY = Symbol('ACCESS_SESSION_REPOSITORY');

export interface AccessSessionRepository {
  save(session: AccessSession): Promise<AccessSession>;
  findById(id: string): Promise<AccessSession | null>;
  /** ERD §3.10 "idx_access_session_cabin_status" — used by the availability check (FR-PAY-02). */
  findActiveByCabinId(cabinId: string): Promise<AccessSession | null>;
}
