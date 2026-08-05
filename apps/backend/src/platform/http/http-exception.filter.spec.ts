import { ArgumentsHost, ForbiddenException } from '@nestjs/common';
import { DomainException } from '../../shared-kernel';
import { HttpExceptionFilter } from './http-exception.filter';

class CabinUnavailableException extends DomainException {
  readonly code = 'ACCESS_SESSION_CABIN_UNAVAILABLE';
  readonly status = 409;

  constructor() {
    super('Cabin C-014 at station ST-002 transitioned to occupied before payment could complete.');
  }
}

function createHost(url = '/v1/access-sessions/9f2e'): { host: ArgumentsHost; json: jest.Mock; status: jest.Mock } {
  const json = jest.fn();
  const contentType = jest.fn().mockReturnValue({ json });
  const status = jest.fn().mockReturnValue({ contentType });
  const response = { status, setHeader: jest.fn() };
  const request = { originalUrl: url, headers: {} };
  const host = {
    switchToHttp: () => ({
      getResponse: () => response,
      getRequest: () => request,
    }),
  } as unknown as ArgumentsHost;
  return { host, json, status };
}

describe('HttpExceptionFilter', () => {
  it('maps a DomainException to its declared RFC 7807 shape', () => {
    const filter = new HttpExceptionFilter();
    const { host, json, status } = createHost();

    filter.catch(new CabinUnavailableException(), host);

    expect(status).toHaveBeenCalledWith(409);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'ACCESS_SESSION_CABIN_UNAVAILABLE',
        status: 409,
        instance: '/v1/access-sessions/9f2e',
      }),
    );
  });

  it('maps a NestJS HttpException to RFC 7807', () => {
    const filter = new HttpExceptionFilter();
    const { host, json, status } = createHost();

    filter.catch(new ForbiddenException('insufficient role'), host);

    expect(status).toHaveBeenCalledWith(403);
    expect(json.mock.calls[0][0].detail).toBe('insufficient role');
  });

  it('redacts unexpected errors to a generic 500 with no stack/internal detail', () => {
    const filter = new HttpExceptionFilter();
    const { host, json, status } = createHost();

    filter.catch(new Error('leaked internal state: db password xyz'), host);

    expect(status).toHaveBeenCalledWith(500);
    const body = json.mock.calls[0][0];
    expect(body.code).toBe('INTERNAL_SERVER_ERROR');
    expect(body.detail).not.toContain('db password');
  });
});
