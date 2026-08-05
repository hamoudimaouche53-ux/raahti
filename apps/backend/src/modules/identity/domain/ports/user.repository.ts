import { Repository } from '../../../../shared-kernel';
import { User } from '../entities/user.entity';

export const USER_REPOSITORY = Symbol('USER_REPOSITORY');

export interface UserRepository extends Repository<User, string> {
  findByEmail(email: string): Promise<User | null>;
  findByPhone(phone: string): Promise<User | null>;

  /**
   * Atomically returns the existing row for `candidate.id`, or creates it from
   * `candidate` if none exists yet (ADR-0028 — JIT provisioning). Never overwrites
   * an already-existing row's fields.
   */
  findOrCreate(candidate: User): Promise<User>;
}
