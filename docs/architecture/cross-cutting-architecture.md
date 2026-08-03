# Cross-Cutting Architecture — Caching, Notifications, Error Handling

| | |
|---|---|
| **Document ID** | RAH-DOC-028-CROSS-CUTTING |
| **Phase** | Phase 1 — System Architecture |
| **Version** | 1.0 |
| **Related** | [ADR-0015 — Caching](../adr/0015-caching-strategy.md) · [System Architecture Document](./system-architecture.md) · [API Architecture](../api/api-architecture.md) |

## Caching

Full decision rationale in [ADR-0015](../adr/0015-caching-strategy.md). Implementation-level detail:

| Endpoint class | Cache treatment |
|---|---|
| `GET /places/nearby`, `GET /third-party-places/{id}` | `Cache-Control: public, max-age=15` + `ETag` — short TTL balances NFR-PERF-01 against real-time expectations |
| `GET /stations/{id}`, `GET /stations/{id}/cabins` | `Cache-Control: no-cache` (always revalidate via `ETag`) — occupancy must never serve stale-without-check, per FR-PLC-02 |
| `GET /slatoki/places` | Same as nearby-places (§ above) |
| Reference/lookup data (tags, roles — not yet exposed as endpoints in V1 openapi.yaml) | In-process memoization, TTL 1h, invalidated on admin write |
| All `POST`/`PATCH`/`DELETE` | `Cache-Control: no-store` |
| Realtime channels (§ [API Architecture §10](../api/api-architecture.md#10-real-time-channels-non-rest)) | Not applicable — push, not cached |

## Notifications

Implements FR-CLD-03, `NotificationsModule` ([Domain Model §8](./domain-model.md#8-bounded-context-notifications)).

- **Channels**: push (FCM for Android, APNs for iOS, both behind a single `NotificationSender` port — mirrors the [ADR-0014](../adr/0014-payment-provider-abstraction.md) adapter pattern, since neither FCM nor APNs is a business-critical open vendor decision, but keeping the same pattern avoids two different extension mechanisms in the same codebase) and in-app (persisted `notification` row, read via `GET /users/me/notifications`).
- **Triggers** (event-subscription, not synchronous calls — per [Module Dependency Diagram §5, rule 4](./module-dependency-diagram.md#5-rules-enforced-ci--review)):
  - `CabinOccupancyChanged` (Station Network) → availability-follow notification to users with a matching `Favorite.notifyOnAvailable = true`.
  - `AlertRaised` (Operations) → operator push, scoped by `site_scope`.
  - `PaymentCaptured` (Access & Payment) → user payment-confirmation push + in-app.
  - `DiabeticVerificationApproved`/`Rejected` (Identity & Access) → user in-app notification.
- **Delivery guarantee**: at-least-once with idempotent client-side handling (notification `id` deduplicates on-device); a `NotificationQueued → Sent → Delivered/Failed` state machine ([ERD §3.14](../erd/erd.md#314-notification-new--supports-fr-cld-03)) with a bounded retry (3 attempts, exponential backoff) before marking `Failed` and surfacing it in the audit log (§ Security Architecture §7).
- **Localization**: notification copy is resolved server-side at send time using the recipient's `preferredLanguage` ([ERD §3.6](../erd/erd.md#36-user-account-src-ext)) against a natively-authored FR/AR template pair — never machine-translated, consistent with FR-I18N-03 applied to system-generated content too.

## Error Handling

- **Contract**: RFC 7807 `application/problem+json` for every 4xx/5xx response, per [API Architecture §7](../api/api-architecture.md#7-error-schema).
- **Exception hierarchy** (NestJS, per module): `DomainException` (raised in `domain/`, e.g. `CabinUnavailableException`) → caught by a global `HttpExceptionFilter` that maps known `DomainException` subclasses to their documented `code`/HTTP status (declared alongside each use case, not scattered ad hoc) → unmapped/unexpected exceptions become a generic `500` with a redacted `detail` (never leaking stack traces or internal identifiers to the client) plus a full server-side log entry with correlation ID (`PlatformModule`, [System Architecture §3](./system-architecture.md#3-layered-architecture--implementation-mapping)).
- **External-call resilience**: calls to the `PaymentGateway` port and any future external provider adapters use a **circuit breaker** (open after N consecutive failures, half-open retry after a cooldown) so a struggling payment provider cannot cascade into blocking the whole `AccessPaymentModule`'s thread pool — client sees a fast, honest `503`/`ProblemDetail` instead of a hung request.
- **Client-side contract**: the mobile app maps `ProblemDetail.code` to a natively-authored, localized error message (FR-I18N-03) — the server's `title`/`detail` fields are for logs/support tooling, not directly rendered to end users, keeping error copy under the same native-authoring discipline as the rest of the UI.

## Completion Status

| Item | Status |
|---|---|
| Caching implementation detail per endpoint class | ✅ Complete |
| Notification channels, triggers, delivery guarantee, localization | ✅ Complete |
| Error-handling contract, exception hierarchy, resilience pattern | ✅ Complete |

**Supporting Phase 1 document — Cross-Cutting Architecture: COMPLETE.**
