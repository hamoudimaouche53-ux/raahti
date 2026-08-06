import { Cabin } from '../../station-network/domain/entities/cabin.entity';
import { CabinNotFoundException } from '../../station-network/application/cabin-not-found.exception';
import { CabinUnavailableException as StationCabinUnavailableException } from '../../station-network/application/cabin-unavailable.exception';
import { StationCommandService } from '../../station-network/application/station-command.service';
import { AccessSession } from '../domain/entities/access-session.entity';
import { AccessSessionRepository, VisitHistoryPage } from '../domain/ports/access-session.repository';
import { IdempotencyRecord, IdempotencyKeyRepository } from '../domain/ports/idempotency-key.repository';
import { CabinUnavailableException } from './cabin-unavailable.exception';
import { IdempotencyService } from './idempotency.service';
import { InitiateAccessSessionService } from './initiate-access-session.service';
import { InvalidQrCodeException } from '../domain/value-objects/qr-code.vo';

const CABIN_ID = '550e8400-e29b-41d4-a716-446655440000';

class InMemoryAccessSessionRepository implements AccessSessionRepository {
  private readonly items = new Map<string, AccessSession>();

  async save(session: AccessSession): Promise<AccessSession> {
    this.items.set(session.id, session);
    return session;
  }

  async findById(id: string): Promise<AccessSession | null> {
    return this.items.get(id) ?? null;
  }

  async findActiveByCabinId(): Promise<AccessSession | null> {
    return null;
  }

  async listVisitHistoryForUser(): Promise<VisitHistoryPage> {
    return { data: [], nextCursor: null };
  }

  get size(): number {
    return this.items.size;
  }
}

class InMemoryIdempotencyKeyRepository implements IdempotencyKeyRepository {
  private readonly items = new Map<string, IdempotencyRecord>();

  async find(userId: string, key: string, endpoint: string): Promise<IdempotencyRecord | null> {
    return this.items.get(`${userId}:${key}:${endpoint}`) ?? null;
  }

  async save(userId: string, key: string, endpoint: string, responseStatus: number, responseBody: unknown): Promise<void> {
    this.items.set(`${userId}:${key}:${endpoint}`, { responseStatus, responseBody });
  }
}

function freeCabin() {
  return Cabin.restore({
    id: CABIN_ID,
    stationId: 's1',
    code: 'C-01',
    type: 'H',
    occupancyStatus: 'free',
    isPaid: false,
    price: null,
  });
}

describe('InitiateAccessSessionService', () => {
  let accessSessionRepository: InMemoryAccessSessionRepository;
  let stationCommandService: jest.Mocked<StationCommandService>;
  let idempotencyService: IdempotencyService;
  let service: InitiateAccessSessionService;

  beforeEach(() => {
    accessSessionRepository = new InMemoryAccessSessionRepository();
    stationCommandService = { checkCabinAvailability: jest.fn(), setCabinOccupancy: jest.fn() } as unknown as jest.Mocked<StationCommandService>;
    idempotencyService = new IdempotencyService(new InMemoryIdempotencyKeyRepository());
    service = new InitiateAccessSessionService(accessSessionRepository, stationCommandService, idempotencyService);
  });

  it('creates an initiated access session for an available cabin', async () => {
    stationCommandService.checkCabinAvailability.mockResolvedValue(freeCabin());

    const session = await service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-1' });

    expect(session.status).toBe('initiated');
    expect(session.cabinId).toBe(CABIN_ID);
    expect(session.userId).toBe('u1');
    expect(accessSessionRepository.size).toBe(1);
  });

  it('throws CabinUnavailableException when the cabin is not found', async () => {
    stationCommandService.checkCabinAvailability.mockRejectedValue(new CabinNotFoundException(CABIN_ID));

    await expect(service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-1' })).rejects.toThrow(
      CabinUnavailableException,
    );
  });

  it('throws CabinUnavailableException when the cabin is occupied (409)', async () => {
    stationCommandService.checkCabinAvailability.mockRejectedValue(new StationCabinUnavailableException(CABIN_ID, 'occupied'));

    await expect(service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-1' })).rejects.toThrow(
      CabinUnavailableException,
    );
  });

  it('rejects a QR payload that is not a valid UUID', async () => {
    await expect(service.execute({ qrCodeScanned: 'not-a-uuid', userId: 'u1', idempotencyKey: 'key-1' })).rejects.toThrow(
      InvalidQrCodeException,
    );
    expect(stationCommandService.checkCabinAvailability).not.toHaveBeenCalled();
  });

  it('replays the same session on a duplicate Idempotency-Key without creating a second session', async () => {
    stationCommandService.checkCabinAvailability.mockResolvedValue(freeCabin());

    const first = await service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-1' });
    const second = await service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-1' });

    expect(second.id).toBe(first.id);
    expect(accessSessionRepository.size).toBe(1);
    expect(stationCommandService.checkCabinAvailability).toHaveBeenCalledTimes(1);
  });

  it('creates a distinct session for a different Idempotency-Key', async () => {
    stationCommandService.checkCabinAvailability.mockResolvedValue(freeCabin());

    const first = await service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-1' });
    const second = await service.execute({ qrCodeScanned: CABIN_ID, userId: 'u1', idempotencyKey: 'key-2' });

    expect(second.id).not.toBe(first.id);
    expect(accessSessionRepository.size).toBe(2);
  });
});
