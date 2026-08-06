import { Inject, Injectable } from '@nestjs/common';
import { AccessSession } from '../domain/entities/access-session.entity';
import { ACCESS_SESSION_REPOSITORY, AccessSessionRepository } from '../domain/ports/access-session.repository';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';

/** GET /access-sessions/{sessionId} (FR-PAY-05 status polling fallback). */
@Injectable()
export class AccessSessionQueryService {
  constructor(@Inject(ACCESS_SESSION_REPOSITORY) private readonly accessSessionRepository: AccessSessionRepository) {}

  async getById(id: string): Promise<AccessSession> {
    const session = await this.accessSessionRepository.findById(id);
    if (!session) {
      throw new AccessSessionNotFoundException(id);
    }
    return session;
  }
}
