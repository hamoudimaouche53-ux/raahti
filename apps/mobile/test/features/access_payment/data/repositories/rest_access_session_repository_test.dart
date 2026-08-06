import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/access_payment/data/datasources/access_session_remote_data_source.dart";
import "package:rahati/features/access_payment/data/repositories/rest_access_session_repository.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";

void main() {
  group("RestAccessSessionRepository", () {
    test("initiateAccessSession delegates to the remote data source and maps "
        "the DTO to an entity", () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"id":"session-1","cabinId":"cabin-1","status":"initiated",'
          '"startedAt":"2026-08-01T10:00:00.000Z","unlockedAt":null}',
          201,
        );
      });
      final repository = RestAccessSessionRepository(
        AccessSessionRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.initiateAccessSession(
        qrCodeScanned: QrCode("RAHETI-STATION-1-CABIN-2"),
        idempotencyKey: "key-1",
      );

      expect(result.id, "session-1");
      expect(result.cabinId, "cabin-1");
    });

    test("getAccessSession delegates and maps the DTO to an entity", () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"id":"session-1","cabinId":"cabin-1","status":"unlocked",'
          '"startedAt":"2026-08-01T10:00:00.000Z",'
          '"unlockedAt":"2026-08-01T10:00:05.000Z"}',
          200,
        );
      });
      final repository = RestAccessSessionRepository(
        AccessSessionRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.getAccessSession("session-1");

      expect(result.id, "session-1");
      expect(result.unlockedAt, isNotNull);
    });

    test(
      "completeAccessSession delegates and maps the DTO to an entity",
      () async {
        final client = MockClient((request) async {
          expect(request.method, "POST");
          expect(request.url.path, "/v1/access-sessions/session-1/complete");
          return http.Response(
            '{"id":"session-1","cabinId":"cabin-1","status":"completed",'
            '"startedAt":"2026-08-01T10:00:00.000Z",'
            '"unlockedAt":"2026-08-01T10:00:05.000Z"}',
            200,
          );
        });
        final repository = RestAccessSessionRepository(
          AccessSessionRemoteDataSource(client, baseUrl: "http://test.local"),
        );

        final result = await repository.completeAccessSession("session-1");

        expect(result.id, "session-1");
      },
    );
  });
}
