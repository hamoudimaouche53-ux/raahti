import { Inject, Injectable } from '@nestjs/common';
import { DomainException } from '../../../shared-kernel';
import { IDEMPOTENCY_KEY_REPOSITORY, IdempotencyKeyRepository } from '../domain/ports/idempotency-key.repository';

export class IdempotentReplayException extends DomainException {
  readonly code: string;
  readonly status: number;

  constructor(status: number, code: string, detail: string) {
    super(detail);
    this.status = status;
    this.code = code;
  }
}

export interface IdempotencyContext {
  userId: string;
  key: string;
  endpoint: string;
}

/**
 * Shared idempotency-check-then-store helper used by both
 * `InitiateAccessSessionService` and `AuthorizeAndCapturePaymentService`
 * (api-architecture.md §8 — both `POST /access-sessions` and
 * `POST /access-sessions/{id}/payments` take an `Idempotency-Key` header;
 * factored once here rather than duplicated in each service, per the task
 * spec). Dedupes on `(userId, key, endpoint)` (Risk Register R-11/R-12).
 *
 * On a cache hit for a prior SUCCESS, `replay(cachedBody)` is called to
 * reconstruct the same return shape the caller expects — deliberately a
 * fresh re-fetch via the calling service's own repository (keyed off a
 * small pointer stored in `cachedBody`, e.g. `{ accessSessionId }`) rather
 * than a byte-for-byte snapshot of the original domain entities: domain
 * entities aren't JSON-serializable by their private-constructor/props
 * shape, and a fresh `findById` accurately reflects the (unchanged, within
 * the same short idempotency window) persisted state.
 *
 * On a cache hit for a prior FAILURE (`responseStatus >= 400`), the same
 * status/code/detail is replayed via `IdempotentReplayException` — not a
 * byte-for-byte reconstruction of the original typed exception class, but
 * the client observes the same HTTP status and `ProblemDetail.code`, which
 * is the behavior the Idempotency-Key contract needs.
 */
@Injectable()
export class IdempotencyService {
  constructor(@Inject(IDEMPOTENCY_KEY_REPOSITORY) private readonly repository: IdempotencyKeyRepository) {}

  async run<T>(
    context: IdempotencyContext,
    successStatus: number,
    execute: () => Promise<{ cacheable: unknown; result: T }>,
    replay: (cachedBody: unknown) => Promise<T>,
  ): Promise<T> {
    const existing = await this.repository.find(context.userId, context.key, context.endpoint);
    if (existing) {
      if (existing.responseStatus >= 400) {
        const body = existing.responseBody as { code?: string; detail?: string } | null;
        throw new IdempotentReplayException(
          existing.responseStatus,
          body?.code ?? 'IDEMPOTENT_REPLAY',
          body?.detail ?? 'Replayed idempotent error response.',
        );
      }
      return replay(existing.responseBody);
    }

    try {
      const { cacheable, result } = await execute();
      await this.repository.save(context.userId, context.key, context.endpoint, successStatus, cacheable);
      return result;
    } catch (error) {
      if (error instanceof DomainException) {
        await this.repository.save(context.userId, context.key, context.endpoint, error.status, {
          code: error.code,
          detail: error.message,
        });
      }
      throw error;
    }
  }
}
