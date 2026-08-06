import { AccessSession } from '../domain/entities/access-session.entity';
import { AccessSessionRepository } from '../domain/ports/access-session.repository';
import { AccessSessionNotFoundException } from './access-session-not-found.exception';
import { AccessSessionQueryService } from './access-session-query.service';

function createRepoMock(): jest.Mocked<AccessSessionRepository> {
  return { save: jest.fn(), findById: jest.fn(), findActiveByCabinId: jest.fn() };
}

describe('AccessSessionQueryService', () => {
  it('returns the session when found', async () => {
    const repo = createRepoMock();
    const session = AccessSession.initiate({ id: 'as1', cabinId: 'c1', userId: 'u1', qrCodeScanned: 'c1' });
    repo.findById.mockResolvedValue(session);
    const service = new AccessSessionQueryService(repo);

    expect(await service.getById('as1')).toBe(session);
  });

  it('throws AccessSessionNotFoundException when missing', async () => {
    const repo = createRepoMock();
    repo.findById.mockResolvedValue(null);
    const service = new AccessSessionQueryService(repo);

    await expect(service.getById('missing')).rejects.toThrow(AccessSessionNotFoundException);
  });
});
