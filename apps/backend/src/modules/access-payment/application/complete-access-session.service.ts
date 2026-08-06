import { Inject, Injectable } from '@nestjs/common';
import { StationCommandService } from '../../station-network/application/station-command.service';
import { AccessSession } from '../domain/entities/access-session.entity';
import { ACCESS_SESSION_REPOSITORY, AccessSessionRepository } from '../domain/ports/access-session.repository';
import { AccessSessionForbiddenException } from './access-session-forbidden.exception';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';

export interface CompleteAccessSessionParams {
  accessSessionId: string;
  callerId: string;
}

/**
 * POST /access-sessions/{id}/complete — ADR-0030's manual "J'ai terminé"
 * path (no automatic door-sensor/IoT integration exists yet). Frees the
 * cabin synchronously via StationCommandService (module-dependency-diagram.md
 * §5 rule 4).
 */
@Injectable()
export class CompleteAccessSessionService {
  constructor(
    @Inject(ACCESS_SESSION_REPOSITORY) private readonly accessSessionRepository: AccessSessionRepository,
    private readonly stationCommandService: StationCommandService,
  ) {}

  async execute(params: CompleteAccessSessionParams): Promise<AccessSession> {
    const session = await this.accessSessionRepository.findById(params.accessSessionId);
    if (!session) {
      throw new AccessSessionNotFoundException(params.accessSessionId);
    }
    if (session.userId !== params.callerId) {
      throw new AccessSessionForbiddenException(params.accessSessionId);
    }

    session.complete();
    await this.stationCommandService.setCabinOccupancy(session.cabinId, 'free');
    return this.accessSessionRepository.save(session);
  }
}
