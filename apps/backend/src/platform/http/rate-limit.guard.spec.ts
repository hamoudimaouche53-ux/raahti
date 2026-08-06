import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RATE_LIMIT_KEY, RateLimitExceededException, RateLimitGuard } from './rate-limit.guard';

function createContext(user?: { sub?: string }, ip = '127.0.0.1'): ExecutionContext {
  const request = { user, ip };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => ({}),
    getClass: () => ({}),
  } as unknown as ExecutionContext;
}

describe('RateLimitGuard', () => {
  it('allows every request when no @RateLimit metadata is present', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue(undefined) } as unknown as Reflector;
    const guard = new RateLimitGuard(reflector);

    for (let i = 0; i < 100; i++) {
      expect(guard.canActivate(createContext({ sub: 'u1' }))).toBe(true);
    }
  });

  it('allows requests up to the configured limit within the window', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue({ limit: 3, windowMs: 60_000 }) } as unknown as Reflector;
    const guard = new RateLimitGuard(reflector);
    const context = createContext({ sub: 'u1' });

    expect(guard.canActivate(context)).toBe(true);
    expect(guard.canActivate(context)).toBe(true);
    expect(guard.canActivate(context)).toBe(true);
  });

  it('throws RateLimitExceededException (429) once the limit is exceeded within the window', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue({ limit: 2, windowMs: 60_000 }) } as unknown as Reflector;
    const guard = new RateLimitGuard(reflector);
    const context = createContext({ sub: 'u1' });

    guard.canActivate(context);
    guard.canActivate(context);
    expect(() => guard.canActivate(context)).toThrow(RateLimitExceededException);
  });

  it('tracks separate buckets per caller', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue({ limit: 1, windowMs: 60_000 }) } as unknown as Reflector;
    const guard = new RateLimitGuard(reflector);

    expect(guard.canActivate(createContext({ sub: 'u1' }))).toBe(true);
    expect(guard.canActivate(createContext({ sub: 'u2' }))).toBe(true);
    expect(() => guard.canActivate(createContext({ sub: 'u1' }))).toThrow(RateLimitExceededException);
  });

  it('falls back to IP when there is no authenticated principal', () => {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue({ limit: 1, windowMs: 60_000 }) } as unknown as Reflector;
    const guard = new RateLimitGuard(reflector);

    expect(guard.canActivate(createContext(undefined, '10.0.0.1'))).toBe(true);
    expect(() => guard.canActivate(createContext(undefined, '10.0.0.1'))).toThrow(RateLimitExceededException);
  });

  it('exposes the metadata key used by the @RateLimit decorator', () => {
    expect(RATE_LIMIT_KEY).toBe('rateLimit');
  });
});
