import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/core/network/authenticated_http_client.dart";

void main() {
  group("AuthenticatedHttpClient", () {
    test("attaches Authorization: Bearer <token> when a token is available", () async {
      http.Request? captured;
      final MockClient inner = MockClient((request) async {
        captured = request;
        return http.Response("{}", 200);
      });
      final client = AuthenticatedHttpClient(inner, () => "token-123");

      await client.get(Uri.parse("https://api.raahti.dz/v1/users/me"));

      expect(captured!.headers["Authorization"], "Bearer token-123");
    });

    test("sends no Authorization header when there is no session (guest)", () async {
      http.Request? captured;
      final MockClient inner = MockClient((request) async {
        captured = request;
        return http.Response("{}", 200);
      });
      final client = AuthenticatedHttpClient(inner, () => null);

      await client.get(Uri.parse("https://api.raahti.dz/v1/places/nearby"));

      expect(captured!.headers.containsKey("Authorization"), isFalse);
    });

    test("reads the token getter fresh on every request (picks up refreshed tokens)", () async {
      final List<String?> capturedHeaders = [];
      final MockClient inner = MockClient((request) async {
        capturedHeaders.add(request.headers["Authorization"]);
        return http.Response("{}", 200);
      });
      String token = "first-token";
      final client = AuthenticatedHttpClient(inner, () => token);

      await client.get(Uri.parse("https://api.raahti.dz/v1/users/me"));
      token = "refreshed-token";
      await client.get(Uri.parse("https://api.raahti.dz/v1/users/me"));

      expect(capturedHeaders, ["Bearer first-token", "Bearer refreshed-token"]);
    });

    test("preserves other headers set by the caller", () async {
      http.Request? captured;
      final MockClient inner = MockClient((request) async {
        captured = request;
        return http.Response("{}", 201);
      });
      final client = AuthenticatedHttpClient(inner, () => "token-123");

      await client.post(
        Uri.parse("https://api.raahti.dz/v1/users/me/favorites"),
        headers: <String, String>{"Content-Type": "application/json"},
        body: "{}",
      );

      expect(captured!.headers["Content-Type"], "application/json");
      expect(captured!.headers["Authorization"], "Bearer token-123");
    });

    test("close() delegates to the inner client", () async {
      bool closed = false;
      final _ClosableStub inner = _ClosableStub(() => closed = true);
      final client = AuthenticatedHttpClient(inner, () => null);

      client.close();

      expect(closed, isTrue);
    });
  });
}

class _ClosableStub extends http.BaseClient {
  _ClosableStub(this._onClose);

  final void Function() _onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }

  @override
  void close() => _onClose();
}
