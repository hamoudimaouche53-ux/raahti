import { CanActivate, ExecutionContext, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { DomainException } from '../../shared-kernel';

export const RATE_LIMIT_KEY = 'rateLimit';

export interface RateLimitOptions {
  limit: number;
  windowMs: number;
}

/**
 * Applies a per-route token-bucket rate limit (api-architecture.md §9:
 * "generous for read endpoints, strict for payment-initiation endpoints...
 * the architectural hook (a RateLimitGuard applied via decorator) is fixed
 * now" — exact thresholds are "a Phase 4 tuning exercise"). Mirrors how
 * `@Roles()` (platform/auth/roles.decorator.ts) attaches metadata read back
 * by a guard via `Reflector`.
 */
export const RateLimit = (limit: number, windowMs: number): MethodDecorator & ClassDecorator =>
  SetMetadata(RATE_LIMIT_KEY, { limit, windowMs } satisfies RateLimitOptions);

export class RateLimitExceededException extends DomainException {
  readonly code = 'RATE_LIMIT_EXCEEDED';
  readonly status = 429;

  constructor() {
    super('Too many requests — please retry later.');
  }
}

interface Bucket {
  tokens: number;
  lastRefillAt: number;
}

/**
 * Hand-rolled, in-memory token-bucket `CanActivate` — no `@nestjs/throttler`
 * or other new dependency, per this pass's explicit constraint; built with
 * what's already installed. In-memory only (a single process's `Map`) —
 * correct for this modular monolith's current single-instance deployment;
 * would need a shared store (e.g. Redis) behind the same `CanActivate`
 * contract if ever horizontally scaled, out of scope here. Keyed on the
 * authenticated caller's `sub` (falls back to remote IP for the — currently
 * unreachable, since every route this guard is applied to sits behind the
 * global `JwtAuthGuard` — unauthenticated case). Each bucket refills
 * continuously at `limit / windowMs` tokens per millisecond, capped at
 * `limit`; one token is spent per allowed request.
 */
@Injectable()
export class RateLimitGuard implements CanActivate {
  private readonly buckets = new Map<string, Bucket>();

  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const options = this.reflector.getAllAndOverride<RateLimitOptions>(RATE_LIMIT_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!options) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const principal = (request as unknown as { user?: { sub?: string } }).user;
    const callerKey = principal?.sub ?? request.ip ?? 'unknown';
    // Keyed on (caller, route) — not caller alone — so two independently
    // `@RateLimit`-decorated routes (e.g. POST /access-sessions and
    // POST /access-sessions/{id}/payments) each get their own bucket per
    // caller instead of sharing one combined pool.
    const key = `${callerKey}:${context.getClass().name}.${context.getHandler().name}`;

    const now = Date.now();
    const existing = this.buckets.get(key) ?? { tokens: options.limit, lastRefillAt: now };
    const elapsedMs = now - existing.lastRefillAt;
    const refillRatePerMs = options.limit / options.windowMs;
    const tokens = Math.min(options.limit, existing.tokens + elapsedMs * refillRatePerMs);

    if (tokens < 1) {
      this.buckets.set(key, { tokens, lastRefillAt: now });
      throw new RateLimitExceededException();
    }

    this.buckets.set(key, { tokens: tokens - 1, lastRefillAt: now });
    return true;
  }
}
