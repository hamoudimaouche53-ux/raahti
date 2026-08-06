import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/access_payment/data/datasources/access_session_remote_data_source.dart";
import "package:rahati/features/access_payment/domain/repositories/access_session_repository.dart";

Map<String, dynamic> _accessSessionJson() => <String, dynamic>{
  "id": "session-1",
  "cabinId": "cabin-1",
  "status": "initiated",
  "startedAt": "2026-08-01T10:00:00.000Z",
  "unlockedAt": null,
};

void main() {
  group("AccessSessionRemoteDataSource.initiateAccessSession", () {
    test(
      "throws AccessPaymentApiNotConfiguredFailure when baseUrl is null",
      () {
        final source = AccessSessionRemoteDataSource(
          http.Client(),
          baseUrl: null,
        );
        expect(
          () => source.initiateAccessSession(
            qrCodeScanned: "code",
            idempotencyKey: "key-1",
          ),
          throwsA(isA<AccessPaymentApiNotConfiguredFailure>()),
        );
      },
    );

    test("POSTs {baseUrl}/v1/access-sessions with the Idempotency-Key header "
        "and JSON body, and parses a 201 response", () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;
      String? capturedBody;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        capturedBody = request.body;
        return http.Response(jsonEncode(_accessSessionJson()), 201);
      });
      final source = AccessSessionRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dto = await source.initiateAccessSession(
        qrCodeScanned: "RAHETI-STATION-1-CABIN-2",
        idempotencyKey: "key-1",
      );

      expect(capturedUri?.path, "/v1/access-sessions");
      expect(capturedHeaders?["Idempotency-Key"], "key-1");
      expect(jsonDecode(capturedBody!), <String, dynamic>{
        "qrCodeScanned": "RAHETI-STATION-1-CABIN-2",
      });
      expect(dto.id, "session-1");
      expect(dto.status, "initiated");
    });

    test("throws CabinUnavailableFailure on a 409 response", () {
      final client = MockClient(
        (request) async => http.Response("cabin unavailable", 409),
      );
      final source = AccessSessionRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.initiateAccessSession(
          qrCodeScanned: "code",
          idempotencyKey: "key-1",
        ),
        throwsA(isA<CabinUnavailableFailure>()),
      );
    });

    test(
      "throws AccessSessionRequestFailure on any other non-201 response",
      () {
        final client = MockClient(
          (request) async => http.Response("server error", 500),
        );
        final source = AccessSessionRemoteDataSource(
          client,
          baseUrl: "http://test.local",
        );

        expect(
          () => source.initiateAccessSession(
            qrCodeScanned: "code",
            idempotencyKey: "key-1",
          ),
          throwsA(isA<AccessSessionRequestFailure>()),
        );
      },
    );
  });

  group("AccessSessionRemoteDataSource.fetchAccessSession", () {
    test(
      "GETs {baseUrl}/v1/access-sessions/{id} and parses a 200 response",
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode(_accessSessionJson()), 200);
        });
        final source = AccessSessionRemoteDataSource(
          client,
          baseUrl: "http://test.local",
        );

        final dto = await source.fetchAccessSession("session-1");

        expect(capturedUri?.path, "/v1/access-sessions/session-1");
        expect(dto.id, "session-1");
      },
    );

    test("throws AccessSessionRequestFailure on a non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("not found", 404),
      );
      final source = AccessSessionRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchAccessSession("session-1"),
        throwsA(isA<AccessSessionRequestFailure>()),
      );
    });
  });

  group("AccessSessionRemoteDataSource.completeAccessSession", () {
    test("POSTs {baseUrl}/v1/access-sessions/{id}/complete and parses a 200 "
        "response", () async {
      Uri? capturedUri;
      String? capturedMethod;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedMethod = request.method;
        return http.Response(jsonEncode(_accessSessionJson()), 200);
      });
      final source = AccessSessionRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dto = await source.completeAccessSession("session-1");

      expect(capturedMethod, "POST");
      expect(capturedUri?.path, "/v1/access-sessions/session-1/complete");
      expect(dto.id, "session-1");
    });

    test("throws AccessSessionRequestFailure on a non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final source = AccessSessionRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.completeAccessSession("session-1"),
        throwsA(isA<AccessSessionRequestFailure>()),
      );
    });

    test(
      "throws AccessPaymentApiNotConfiguredFailure when baseUrl is null",
      () {
        final source = AccessSessionRemoteDataSource(
          http.Client(),
          baseUrl: null,
        );
        expect(
          () => source.completeAccessSession("session-1"),
          throwsA(isA<AccessPaymentApiNotConfiguredFailure>()),
        );
      },
    );
  });
}
