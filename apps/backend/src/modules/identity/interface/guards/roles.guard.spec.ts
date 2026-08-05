import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RolesGuard } from './roles.guard';

function createContext(user?: unknown): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
    getHandler: () => ({}),
    getClass: () => ({}),
  } as unknown as ExecutionContext;
}

describe('RolesGuard', () => {
  it('allows any authenticated user when no @Roles() metadata is set', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(undefined);
    const guard = new RolesGuard(reflector);

    expect(guard.canActivate(createContext({ role: 'usager' }))).toBe(true);
  });

  it('allows a user whose role is in the required set', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['admin', 'operateur']);
    const guard = new RolesGuard(reflector);

    expect(guard.canActivate(createContext({ role: 'operateur' }))).toBe(true);
  });

  it('rejects a user whose role is not in the required set', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['admin']);
    const guard = new RolesGuard(reflector);

    expect(() => guard.canActivate(createContext({ role: 'usager' }))).toThrow(ForbiddenException);
  });

  it('rejects when there is no authenticated user at all', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['admin']);
    const guard = new RolesGuard(reflector);

    expect(() => guard.canActivate(createContext(undefined))).toThrow(ForbiddenException);
  });
});
