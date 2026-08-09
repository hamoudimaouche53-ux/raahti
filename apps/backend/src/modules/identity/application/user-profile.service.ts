import { Inject, Injectable } from '@nestjs/common';
import { LanguagePreference } from '../../../shared-kernel';
import { AuthenticatedPrincipal } from '../../../platform/auth';
import { User } from '../domain/entities/user.entity';
import { USER_REPOSITORY, UserRepository } from '../domain/ports/user.repository';

@Injectable()
export class UserProfileService {
  constructor(@Inject(USER_REPOSITORY) private readonly userRepository: UserRepository) {}

  /** GET /users/me — JIT-provisions the local row on first call (ADR-0028). */
  async getOrCreateCurrentUser(claims: AuthenticatedPrincipal): Promise<User> {
    const candidate = User.create({
      id: claims.sub,
      email: claims.email || null,
      // Supabase issues "" (not absent/null) for phone on email-only signups;
      // `??` doesn't catch that, and User.phone is @unique — every phone-less
      // user would collide on the empty string. Normalize falsy to null.
      phone: claims.phone || null,
    });
    return this.userRepository.findOrCreate(candidate);
  }

  /** PATCH /users/me — currently only the language toggle (UserUpdateRequest, openapi.yaml). */
  async updateLanguagePreference(claims: AuthenticatedPrincipal, preferredLanguage: string): Promise<User> {
    const current = await this.getOrCreateCurrentUser(claims);
    const updated = User.create({
      id: current.id,
      email: current.email,
      phone: current.phone,
      preferredLanguage: LanguagePreference.of(preferredLanguage),
      diabeticVerificationStatus: current.diabeticVerificationStatus,
      isActive: current.isActive,
    });
    await this.userRepository.save(updated);
    return updated;
  }
}
