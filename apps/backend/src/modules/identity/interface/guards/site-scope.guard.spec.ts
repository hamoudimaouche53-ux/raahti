import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { SiteScopeGuard } from './site-scope.guard';

function createContext(user?: unknown, params: Record<string, string> = {}): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => ({ user, params }) }),
  } as unknown as ExecutionContext;
}

describe('SiteScopeGuard', () => {
  const guard = new SiteScopeGuard();

  it('passes through non-operateur roles unchecked', () => {
    expect(guard.canActivate(createContext({ role: 'admin', site_scope: undefined }, { siteId: 'site-1' }))).toBe(
      true,
    );
  });

  it('passes through when the route has no :siteId param', () => {
    expect(guard.canActivate(createContext({ role: 'operateur', site_scope: 'site-1' }, {}))).toBe(true);
  });

  it('allows an operateur scoped to the requested site', () => {
    expect(
      guard.canActivate(createContext({ role: 'operateur', site_scope: 'site-1' }, { siteId: 'site-1' })),
    ).toBe(true);
  });

  it('rejects an operateur scoped to a different site', () => {
    expect(() =>
      guard.canActivate(createContext({ role: 'operateur', site_scope: 'site-1' }, { siteId: 'site-2' })),
    ).toThrow(ForbiddenException);
  });
});
