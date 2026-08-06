import { StationCommandService } from '../../station-network/application/station-command.service';
import { AccessSession } from '../domain/entities/access-session.entity';
import { AccessSessionRepository } from '../domain/ports/access-session.repository';
import { AccessSessionForbiddenException } from './access-session-forbidden.exception';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';
import { CompleteAccessSessionService } from './complete-access-session.service';

function createRepoMock(): jest.Mocked<AccessSessionRepository> {
  return { save: jest.fn(), findById: jest.fn(), findActiveByCabinId: jest.fn(), listVisitHistoryForUser: jest.fn() };
}

function unlockedSession(userId = 'u1') {
  const session = AccessSession.initiate({ id: 'as1', cabinId: 'c1', userId, qrCodeScanned: 'c1' });
  session.markUnlocked();
  return session;
}

describe('CompleteAccessSessionService', () => {
  let accessSessionRepository: jest.Mocked<AccessSessionRepository>;
  let stationCommandService: jest.Mocked<StationCommandService>;
  let service: CompleteAccessSessionService;

  beforeEach(() => {
    accessSessionRepository = createRepoMock();
    accessSessionRepository.save.mockImplementation(async (session) => session);
    stationCommandService = { checkCabinAvailability: jest.fn(), setCabinOccupancy: jest.fn() } as unknown as jest.Mocked<StationCommandService>;
    service = new CompleteAccessSessionService(accessSessionRepository, stationCommandService);
  });

  it('completes the session and frees the cabin', async () => {
    accessSessionRepository.findById.mockResolvedValue(unlockedSession());

    const result = await service.execute({ accessSessionId: 'as1', callerId: 'u1' });

    expect(result.status).toBe('completed');
    expect(stationCommandService.setCabinOccupancy).toHaveBeenCalledWith('c1', 'free');
    expect(accessSessionRepository.save).toHaveBeenCalled();
  });

  it('throws AccessSessionNotFoundException when missing', async () => {
    accessSessionRepository.findById.mockResolvedValue(null);

    await expect(service.execute({ accessSessionId: 'missing', callerId: 'u1' })).rejects.toThrow(
      AccessSessionNotFoundException,
    );
  });

  it('throws AccessSessionForbiddenException when the caller is not the owner', async () => {
    accessSessionRepository.findById.mockResolvedValue(unlockedSession('someone-else'));

    await expect(service.execute({ accessSessionId: 'as1', callerId: 'u1' })).rejects.toThrow(
      AccessSessionForbiddenException,
    );
    expect(stationCommandService.setCabinOccupancy).not.toHaveBeenCalled();
  });
});
