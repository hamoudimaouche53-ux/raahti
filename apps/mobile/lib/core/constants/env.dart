/// Build-time environment configuration, injected via `--dart-define`.
///
/// No secret is ever hard-coded here, per docs/architecture/security-architecture.md
/// §4 (Secrets Management). Example run command once a Supabase project and
/// a deployed backend API exist (see docs/adr/0016-hosting-provider-selection.md,
/// still open — no backend has been implemented yet in this conversation,
/// Phase 4 has not started):
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=xxxx \
///   --dart-define=API_BASE_URL=https://api.raahti.dz
/// ```
///
/// When unset (e.g. local UI-only development, CI, widget tests), all
/// values default to the empty string and the corresponding `isXConfigured`
/// flag is `false` — callers ([bootstrapSupabase],
/// `PlaceRemoteDataSource`) skip/fail gracefully rather than throwing an
/// unhandled error.
abstract final class AppEnv {
  static const String supabaseUrl = String.fromEnvironment("SUPABASE_URL");
  static const String supabasePublishableKey = String.fromEnvironment(
    "SUPABASE_PUBLISHABLE_KEY",
  );

  /// Backend API base URL (docs/api/api-architecture.md), e.g.
  /// `https://api.raahti.dz` — the client appends `/v1/...` per endpoint.
  /// No trailing slash.
  static const String apiBaseUrl = String.fromEnvironment("API_BASE_URL");

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;

  /// Opt-in only, `false` by default — swaps the place-detail sheet's data
  /// source from `RestPlaceDetailRepository` (real `GET /stations/{id}` /
  /// `GET /third-party-places/{id}` calls) to `MockPlaceDetailRepository`
  /// (deterministic, clearly-labeled sample cabin/status data) for
  /// demoing US-01.2.2/US-01.2.3 before a backend is deployed
  /// (ADR-0016 still open). Never affects `PlaceRepository` (the map's
  /// own nearby-places fetch, which has a real offline cache instead —
  /// ADR-0008/ADR-0022) — this flag is scoped to detail-sheet data only.
  /// Example: `flutter run --dart-define=USE_MOCK_PLACE_DETAIL=true`.
  static const bool useMockPlaceDetail = bool.fromEnvironment(
    "USE_MOCK_PLACE_DETAIL",
  );

  /// Opt-in only, `false` by default — swaps `PaymentRepository`/
  /// `PaymentMethodRepository`'s data source from the REST
  /// implementations (real `POST /access-sessions/{id}/payments` /
  /// `GET`/`POST /users/me/payment-methods` calls) to
  /// `MockPaymentRepository`/`MockPaymentMethodRepository` for demoing
  /// SCR-015/016/018 (US-04.3) before a backend is deployed (ADR-0016
  /// still open). `MockPaymentRepository` orchestrates
  /// `MockPaymentGatewayAdapter` directly (ADR-0014's mandated mock
  /// adapter), simulating server-side authorize/capture locally.
  /// Example: `flutter run --dart-define=USE_MOCK_PAYMENT=true`.
  static const bool useMockPayment = bool.fromEnvironment("USE_MOCK_PAYMENT");

  /// Opt-in only, `false` by default — swaps `AuthRepository`/
  /// `UserRepository`/`FavoriteRepository`/`VisitHistoryRepository`'s data
  /// source from the real/REST implementations to their `Mock*`
  /// counterparts, for demoing EPIC-05 (SCR-020/021/022/023/026/027/030)
  /// before either a real Supabase project ([isSupabaseConfigured]) or a
  /// deployed backend ([isApiConfigured]) exists. Unlike
  /// [useMockPlaceDetail]/[useMockPayment] (each scoped to one feature's
  /// data), this one flag covers every EPIC-05 port — they're all facets
  /// of the same "demo a signed-in account" scenario, never meaningfully
  /// toggled independently (same reasoning `MockCabinRealtimeRepository`'s
  /// doc comment already applied to reusing `useMockPlaceDetail`).
  /// Example: `flutter run --dart-define=USE_MOCK_AUTH=true`.
  static const bool useMockAuth = bool.fromEnvironment("USE_MOCK_AUTH");
}
