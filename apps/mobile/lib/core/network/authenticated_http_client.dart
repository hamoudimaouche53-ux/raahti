import "package:http/http.dart" as http;

/// Wraps an [http.Client], attaching `Authorization: Bearer <token>` to
/// every outgoing request — the single place this app attaches auth to
/// backend requests. Constructed once behind `httpClientProvider`
/// (`map_discovery/presentation/providers/place_providers.dart`) — the one
/// provider every `*RemoteDataSource` in the app already depends on for its
/// [http.Client] — so no repository or data source needs, or should ever
/// duplicate, its own auth logic.
///
/// Takes a token-getter closure rather than a `GoTrueClient` directly: the
/// caller captures `SupabaseClient.auth` once (a stable, long-lived object)
/// and passes `() => auth.currentSession?.accessToken` — a plain getter
/// read, not a Riverpod operation, so it's safe to call on every request,
/// not just at provider-build time. This also keeps this class trivially
/// testable with a fake closure, with no Supabase types involved at all.
///
/// [_getAccessToken] should read a live value fresh on every call, not a
/// cached one: `supabase_flutter`'s `GoTrueClient` runs its own
/// auto-refresh timer (`autoRefreshToken`, on by default — see
/// `gotrue_client.dart`) that keeps `currentSession` current in place, so
/// this class needs no refresh logic of its own — it always sees whatever
/// access token is valid *right now*, already refreshed if needed.
///
/// When [_getAccessToken] returns `null` (no session — guest / signed out),
/// requests go out with no `Authorization` header at all — exactly as
/// before this class existed. Public backend endpoints (`security: []` in
/// docs/api/openapi.yaml — `/places/nearby`, `/stations/{id}`,
/// `/stations/{id}/cabins`, `/third-party-places/{id}`, `/slatoki/places`)
/// never required one and keep working unauthenticated for guests, per
/// FR-USR-01's optional-account model; protected endpoints correctly 401
/// for a guest, same as any authenticated API.
class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient(this._inner, this._getAccessToken);

  final http.Client _inner;
  final String? Function() _getAccessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final String? accessToken = _getAccessToken();
    if (accessToken != null) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
