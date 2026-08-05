import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtVerifier } from '../../infrastructure/auth/jwt-verifier.port';
import { JwtAuthGuard } from './jwt-auth.guard';

function createContext(authorizationHeader?: string): { context: ExecutionContext; request: any } {
  const request: any = { headers: authorizationHeader ? { authorization: authorizationHeader } : {} };
  const context = {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => ({}),
    getClass: () => ({}),
  } as unknown as ExecutionContext;
  return { context, request };
}

describe('JwtAuthGuard', () => {
  let verifier: jest.Mocked<JwtVerifier>;
  let reflector: Reflector;

  beforeEach(() => {
    verifier = { verify: jest.fn() };
    reflector = new Reflector();
  });

  it('rejects a request with no token on a protected route', async () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(false);
    const guard = new JwtAuthGuard(reflector, verifier);
    const { context } = createContext();

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('allows a request with no token on a @Public() route', async () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(true);
    const guard = new JwtAuthGuard(reflector, verifier);
    const { context } = createContext();

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(verifier.verify).not.toHaveBeenCalled();
  });

  it('rejects an invalid token even on a @Public() route', async () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(true);
    verifier.verify.mockRejectedValue(new Error('bad signature'));
    const guard = new JwtAuthGuard(reflector, verifier);
    const { context } = createContext('Bearer bad-token');

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('attaches verified claims to the request and allows a valid token', async () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(false);
    const claims = { sub: 'u1', role: 'usager', exp: 0, iat: 0 } as any;
    verifier.verify.mockResolvedValue(claims);
    const guard = new JwtAuthGuard(reflector, verifier);
    const { context, request } = createContext('Bearer good-token');

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user).toBe(claims);
    expect(verifier.verify).toHaveBeenCalledWith('good-token');
  });

  it('rejects a malformed Authorization header (not "Bearer <token>")', async () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(false);
    const guard = new JwtAuthGuard(reflector, verifier);
    const { context } = createContext('Basic dXNlcjpwYXNz');

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });
});
