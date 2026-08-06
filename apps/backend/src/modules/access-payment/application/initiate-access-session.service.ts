import { randomUUID } from 'crypto';
import { Inject, Injectable } from '@nestjs/common';
import { CabinNotFoundException as StationCabinNotFoundException } from '../../station-network/application/cabin-not-found.exception';
import { CabinUnavailableException as StationCabinUnavailableException } from '../../station-network/application/cabin-unavailable.exception';
import { StationCommandService } from '../../station-network/application/station-command.service';
import { AccessSession } from '../domain/entities/access-session.entity';
import { ACCESS_SESSION_REPOSITORY, AccessSessionRepository } from '../domain/ports/access-session.repository';
import { QrCode } from '../domain/value-objects/qr-code.vo';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';
import { CabinUnavailableException } from './cabin-unavailable.exception';
import { IdempotencyService } from './idempotency.service';

const ENDPOINT = 'POST /access-sessions';

export interface InitiateAccessSessionParams {
  qrCodeScanned: string;
  userId: string;
  idempotencyKey: string;
}

/**
 * FR-PAY-01/02 — POST /access-sessions. Resolves `cabinId` from the scanned
 * QR payload (see QrCode.toCabinId() for the V1 "QR encodes the cabin UUID
 * directly" decision), checks availability via StationCommandService (the
 * sanctioned `AccessPay -> StationNet` command dependency,
 * module-dependency-diagram.md §3), and creates the AccessSession. Never
 * creates a Transaction — that only happens in AuthorizeAndCapturePaymentService,
 * and only for a paid cabin (Domain Model §6: "a free-access session
 * produces no transaction row").
 */
@Injectable()
export class InitiateAccessSessionService {
  constructor(
    @Inject(ACCESS_SESSION_REPOSITORY) private readonly accessSessionRepository: AccessSessionRepository,
    private readonly stationCommandService: StationCommandService,
    private readonly idempotencyService: IdempotencyService,
  ) {}

  async execute(params: InitiateAccessSessionParams): Promise<AccessSession> {
    return this.idempotencyService.run<AccessSession>(
      { userId: params.userId, key: params.idempotencyKey, endpoint: ENDPOINT },
      201,
      async () => {
        const session = await this.doExecute(params);
        return { cacheable: { accessSessionId: session.id }, result: session };
      },
      async (cached) => {
        const { accessSessionId } = cached as { accessSessionId: string };
        const session = await this.accessSessionRepository.findById(accessSessionId);
        if (!session) {
          throw new AccessSessionNotFoundException(accessSessionId);
        }
        return session;
      },
    );
  }

  private async doExecute(params: InitiateAccessSessionParams): Promise<AccessSession> {
    const cabinId = QrCode.of(params.qrCodeScanned).toCabinId();

    let cabin;
    try {
      cabin = await this.stationCommandService.checkCabinAvailability(cabinId);
    } catch (error) {
      // openapi.yaml documents only a 409 for this route (no 404) — both
      // "cabin doesn't exist" and "cabin isn't free" collapse into this
      // module's own CabinUnavailableException.
      if (error instanceof StationCabinNotFoundException || error instanceof StationCabinUnavailableException) {
        throw new CabinUnavailableException(cabinId);
      }
      throw error;
    }

    const session = AccessSession.initiate({
      id: randomUUID(),
      cabinId: cabin.id,
      userId: params.userId,
      qrCodeScanned: params.qrCodeScanned,
    });
    return this.accessSessionRepository.save(session);
  }
}
