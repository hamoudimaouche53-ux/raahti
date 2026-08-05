import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RequireMfaGuard } from './require-mfa.guard';

function createContext(user?: unknown): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
    getHandler: () => ({}),
    getClass: () => ({}),
  } as unknown as ExecutionContext;
}

describe('RequireMfaGuard', () => {
  it('allows any request when the route does not require MFA', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(false);
    const guard = new RequireMfaGuard(reflector);

    expect(guard.canActivate(createContext({ aal: 'aal1' }))).toBe(true);
  });

  it('allows a request with aal2 on an MFA-required route', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(true);
    const guard = new RequireMfaGuard(reflector);

    expect(guard.canActivate(createContext({ aal: 'aal2' }))).toBe(true);
  });

  it('rejects a request without aal2 on an MFA-required route', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(true);
    const guard = new RequireMfaGuard(reflector);

    expect(() => guard.canActivate(createContext({ aal: 'aal1' }))).toThrow(ForbiddenException);
    expect(() => guard.canActivate(createContext(undefined))).toThrow(ForbiddenException);
  });
});
