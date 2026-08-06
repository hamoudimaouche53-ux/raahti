import { DomainException } from '../../../shared-kernel';
import { IdempotencyKeyRepository } from '../domain/ports/idempotency-key.repository';
import { IdempotencyService, IdempotentReplayException } from './idempotency.service';

class TestException extends DomainException {
  readonly code = 'TEST_EXCEPTION';
  readonly status = 409;
  constructor() {
    super('boom');
  }
}

function createRepoMock(): jest.Mocked<IdempotencyKeyRepository> {
  return { find: jest.fn(), save: jest.fn() };
}

describe('IdempotencyService', () => {
  it('executes and caches on a cache miss', async () => {
    const repo = createRepoMock();
    repo.find.mockResolvedValue(null);
    const service = new IdempotencyService(repo);
    const execute = jest.fn().mockResolvedValue({ cacheable: { accessSessionId: 'as1' }, result: 'created' });
    const replay = jest.fn();

    const result = await service.run({ userId: 'u1', key: 'k1', endpoint: 'E' }, 201, execute, replay);

    expect(result).toBe('created');
    expect(execute).toHaveBeenCalledTimes(1);
    expect(replay).not.toHaveBeenCalled();
    expect(repo.save).toHaveBeenCalledWith('u1', 'k1', 'E', 201, { accessSessionId: 'as1' });
  });

  it('replays via the replay callback on a cache hit for a prior success, without re-executing', async () => {
    const repo = createRepoMock();
    repo.find.mockResolvedValue({ responseStatus: 201, responseBody: { accessSessionId: 'as1' } });
    const service = new IdempotencyService(repo);
    const execute = jest.fn();
    const replay = jest.fn().mockResolvedValue('cached-session');

    const result = await service.run({ userId: 'u1', key: 'k1', endpoint: 'E' }, 201, execute, replay);

    expect(result).toBe('cached-session');
    expect(execute).not.toHaveBeenCalled();
    expect(replay).toHaveBeenCalledWith({ accessSessionId: 'as1' });
  });

  it('caches a DomainException failure and rethrows it on the first call', async () => {
    const repo = createRepoMock();
    repo.find.mockResolvedValue(null);
    const service = new IdempotencyService(repo);
    const execute = jest.fn().mockRejectedValue(new TestException());

    await expect(service.run({ userId: 'u1', key: 'k1', endpoint: 'E' }, 200, execute, jest.fn())).rejects.toThrow(
      TestException,
    );
    expect(repo.save).toHaveBeenCalledWith('u1', 'k1', 'E', 409, { code: 'TEST_EXCEPTION', detail: 'boom' });
  });

  it('replays a cached failure as IdempotentReplayException with the same status/code', async () => {
    const repo = createRepoMock();
    repo.find.mockResolvedValue({ responseStatus: 409, responseBody: { code: 'TEST_EXCEPTION', detail: 'boom' } });
    const service = new IdempotencyService(repo);

    await expect(service.run({ userId: 'u1', key: 'k1', endpoint: 'E' }, 200, jest.fn(), jest.fn())).rejects.toThrow(
      IdempotentReplayException,
    );
    await expect(service.run({ userId: 'u1', key: 'k1', endpoint: 'E' }, 200, jest.fn(), jest.fn())).rejects.toMatchObject({
      status: 409,
      code: 'TEST_EXCEPTION',
    });
  });

  it('does not cache non-DomainException errors', async () => {
    const repo = createRepoMock();
    repo.find.mockResolvedValue(null);
    const service = new IdempotencyService(repo);
    const execute = jest.fn().mockRejectedValue(new Error('unexpected'));

    await expect(service.run({ userId: 'u1', key: 'k1', endpoint: 'E' }, 200, execute, jest.fn())).rejects.toThrow(
      'unexpected',
    );
    expect(repo.save).not.toHaveBeenCalled();
  });
});
