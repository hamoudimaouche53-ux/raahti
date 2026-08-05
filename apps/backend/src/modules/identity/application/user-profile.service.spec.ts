import { LanguagePreference } from '../../../shared-kernel';
import { User } from '../domain/entities/user.entity';
import { UserRepository } from '../domain/ports/user.repository';
import { JwtClaims } from '../infrastructure/auth/jwt-claims';
import { UserProfileService } from './user-profile.service';

/**
 * In-memory fake standing in for Postgres's atomic ON CONFLICT semantics —
 * proves the application-layer *sequencing* is correct (never re-provisions,
 * never clobbers). True concurrent-request atomicity is a DB-layer guarantee
 * (ADR-0028), verified by PrismaUserRepository's upsert-with-empty-update
 * shape (prisma-user.repository.spec.ts), not re-provable without a live DB.
 */
class InMemoryUserRepository implements UserRepository {
  private readonly byId = new Map<string, User>();

  async findById(id: string): Promise<User | null> {
    return this.byId.get(id) ?? null;
  }

  async findByEmail(email: string): Promise<User | null> {
    return [...this.byId.values()].find((u) => u.email === email) ?? null;
  }

  async findByPhone(phone: string): Promise<User | null> {
    return [...this.byId.values()].find((u) => u.phone === phone) ?? null;
  }

  async save(user: User): Promise<void> {
    this.byId.set(user.id, user);
  }

  async findOrCreate(candidate: User): Promise<User> {
    const existing = this.byId.get(candidate.id);
    if (existing) {
      return existing;
    }
    this.byId.set(candidate.id, candidate);
    return candidate;
  }
}

function claims(overrides: Partial<JwtClaims> = {}): JwtClaims {
  return { sub: 'u1', email: 'a@example.com', exp: 0, iat: 0, ...overrides };
}

describe('UserProfileService', () => {
  it('provisions a new user on first call', async () => {
    const repo = new InMemoryUserRepository();
    const service = new UserProfileService(repo);

    const user = await service.getOrCreateCurrentUser(claims());

    expect(user.id).toBe('u1');
    expect(user.email).toBe('a@example.com');
  });

  it('returns the same user on a second call without re-provisioning', async () => {
    const repo = new InMemoryUserRepository();
    const service = new UserProfileService(repo);

    const first = await service.getOrCreateCurrentUser(claims());
    const second = await service.getOrCreateCurrentUser(claims());

    expect(second.id).toBe(first.id);
  });

  it('does not revert a previously-set language preference on repeat provisioning calls', async () => {
    const repo = new InMemoryUserRepository();
    const service = new UserProfileService(repo);

    await service.getOrCreateCurrentUser(claims());
    await service.updateLanguagePreference(claims(), 'ar');
    const afterUpdate = await service.getOrCreateCurrentUser(claims());

    expect(afterUpdate.preferredLanguage.equals(LanguagePreference.AR)).toBe(true);
  });

  it('provisions then immediately applies the language update when none existed yet', async () => {
    const repo = new InMemoryUserRepository();
    const service = new UserProfileService(repo);

    const updated = await service.updateLanguagePreference(claims(), 'ar');

    expect(updated.preferredLanguage.equals(LanguagePreference.AR)).toBe(true);
  });
});
