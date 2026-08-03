import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/access_payment/data/datasources/payment_remote_data_source.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_repository.dart";

Map<String, dynamic> _transactionJson() => <String, dynamic>{
  "id": "txn-1",
  "amount": <String, dynamic>{"amount": "50", "currency": "DZD"},
  "discountApplied": null,
  "status": "captured",
  "accessSession": <String, dynamic>{
    "id": "session-1",
    "cabinId": "cabin-1",
    "status": "unlocked",
    "startedAt": "2026-08-01T10:00:00.000Z",
    "unlockedAt": "2026-08-01T10:01:00.000Z",
  },
};

void main() {
  group("PaymentRemoteDataSource.requestPayment", () {
    test("throws PaymentApiNotConfiguredFailure when baseUrl is null", () {
      final source = PaymentRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.requestPayment(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
          applyEmergencyDiscount: false,
          idempotencyKey: "key-1",
        ),
        throwsA(isA<PaymentApiNotConfiguredFailure>()),
      );
    });

    test(
      "POSTs {baseUrl}/v1/access-sessions/{id}/payments with the "
      "Idempotency-Key header and JSON body, and parses a 200 response",
      () async {
        Uri? capturedUri;
        Map<String, String>? capturedHeaders;
        String? capturedBody;
        final client = MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          capturedBody = request.body;
          return http.Response(jsonEncode(_transactionJson()), 200);
        });
        final source = PaymentRemoteDataSource(
          client,
          baseUrl: "http://test.local",
        );

        final dto = await source.requestPayment(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
          applyEmergencyDiscount: false,
          idempotencyKey: "key-1",
        );

        expect(capturedUri?.path, "/v1/access-sessions/session-1/payments");
        expect(capturedHeaders?["Idempotency-Key"], "key-1");
        expect(jsonDecode(capturedBody!), <String, dynamic>{
          "paymentMethodId": "pm-1",
          "applyEmergencyDiscount": false,
        });
        expect(dto.id, "txn-1");
        expect(dto.accessSession.id, "session-1");
      },
    );

    test("throws PaymentDeclinedFailure on a 402 response", () {
      final client = MockClient(
        (request) async => http.Response("declined", 402),
      );
      final source = PaymentRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.requestPayment(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
          applyEmergencyDiscount: false,
          idempotencyKey: "key-1",
        ),
        throwsA(isA<PaymentDeclinedFailure>()),
      );
    });

    test("throws UnlockFailedRefundedFailure on a 502 response", () {
      final client = MockClient(
        (request) async => http.Response("unlock failed", 502),
      );
      final source = PaymentRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.requestPayment(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
          applyEmergencyDiscount: false,
          idempotencyKey: "key-1",
        ),
        throwsA(isA<UnlockFailedRefundedFailure>()),
      );
    });

    test("throws PaymentRequestFailure on any other non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final source = PaymentRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.requestPayment(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
          applyEmergencyDiscount: false,
          idempotencyKey: "key-1",
        ),
        throwsA(isA<PaymentRequestFailure>()),
      );
    });
  });
}
