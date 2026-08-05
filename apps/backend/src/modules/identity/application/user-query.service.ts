import { Inject, Injectable } from '@nestjs/common';
import { User } from '../domain/entities/user.entity';
import { USER_REPOSITORY, UserRepository } from '../domain/ports/user.repository';

/**
 * Exported application-layer query surface for this module — the only thing
 * another module may depend on (module-dependency-diagram.md §5 rule 1).
 * Added when NotificationsModule became the first real cross-module consumer
 * of Identity data (needs a recipient's `preferredLanguage` for server-side
 * notification-copy localization, cross-cutting-architecture.md — Notifications).
 * IdentityModule previously exported its raw repository tokens directly,
 * which nothing had consumed yet but would have violated this same rule the
 * moment a consumer showed up — fixed here rather than compounded.
 */
@Injectable()
export class UserQueryService {
  constructor(@Inject(USER_REPOSITORY) private readonly userRepository: UserRepository) {}

  async findById(userId: string): Promise<User | null> {
    return this.userRepository.findById(userId);
  }
}
