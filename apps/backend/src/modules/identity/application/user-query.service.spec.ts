import { LanguagePreference } from '../../../shared-kernel';
import { User } from '../domain/entities/user.entity';
import { UserRepository } from '../domain/ports/user.repository';
import { UserQueryService } from './user-query.service';

function createRepoMock(): jest.Mocked<UserRepository> {
  return { findById: jest.fn(), findByEmail: jest.fn(), findByPhone: jest.fn(), save: jest.fn(), findOrCreate: jest.fn() };
}

describe('UserQueryService', () => {
  it('returns the user when found', async () => {
    const repo = createRepoMock();
    const user = User.create({ id: 'u1', email: 'a@example.com', preferredLanguage: LanguagePreference.AR });
    repo.findById.mockResolvedValue(user);
    const service = new UserQueryService(repo);

    const result = await service.findById('u1');

    expect(result?.id).toBe('u1');
  });

  it('returns null when not found', async () => {
    const repo = createRepoMock();
    repo.findById.mockResolvedValue(null);
    const service = new UserQueryService(repo);

    expect(await service.findById('missing')).toBeNull();
  });
});
