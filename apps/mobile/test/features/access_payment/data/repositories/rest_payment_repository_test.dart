import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/access_payment/data/datasources/payment_remote_data_source.dart";
import "package:rahati/features/access_payment/data/repositories/rest_payment_repository.dart";

void main() {
  group("RestPaymentRepository", () {
    test("requestPayment delegates to the remote data source and returns "
        "the embedded AccessSession, mapped to an entity", () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"id":"txn-1","amount":{"amount":"50","currency":"DZD"},'
          '"discountApplied":null,"status":"captured",'
          '"accessSession":{"id":"session-1","cabinId":"cabin-1",'
          '"status":"unlocked","startedAt":"2026-08-01T10:00:00.000Z",'
          '"unlockedAt":"2026-08-01T10:01:00.000Z"}}',
          200,
        );
      });
      final repository = RestPaymentRepository(
        PaymentRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.requestPayment(
        accessSessionId: "session-1",
        paymentMethodId: "pm-1",
        applyEmergencyDiscount: false,
        idempotencyKey: "key-1",
      );

      expect(result.id, "session-1");
      expect(result.cabinId, "cabin-1");
    });
  });
}
