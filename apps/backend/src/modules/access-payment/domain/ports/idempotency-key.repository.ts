export const IDEMPOTENCY_KEY_REPOSITORY = Symbol('IDEMPOTENCY_KEY_REPOSITORY');

export interface IdempotencyRecord {
  responseStatus: number;
  responseBody: unknown;
}

/**
 * Additive gap-fill (not in the ERD — see `IdempotencyKey`'s schema.prisma
 * doc comment) backing the `Idempotency-Key` header contract shared by
 * `POST /access-sessions` and `POST /access-sessions/{id}/payments`
 * (api-architecture.md §8, Risk Register R-11/R-12). One port, one small
 * `IdempotencyService` application-layer helper (see
 * application/idempotency.service.ts) used by both write use cases, rather
 * than duplicating the check-then-store logic twice.
 */
export interface IdempotencyKeyRepository {
  find(userId: string, key: string, endpoint: string): Promise<IdempotencyRecord | null>;
  save(userId: string, key: string, endpoint: string, responseStatus: number, responseBody: unknown): Promise<void>;
}
