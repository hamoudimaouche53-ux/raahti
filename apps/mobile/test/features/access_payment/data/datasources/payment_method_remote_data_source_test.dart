import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/access_payment/data/datasources/payment_method_remote_data_source.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_method_repository.dart";

// Plain ASCII, not the real UI's "Visa •••• 4242" — `http.Response`'s
// default `latin1` encoding (no explicit charset here) can't represent
// U+2022 BULLET, which is irrelevant to what these tests actually check
// (DTO field pass-through), so the fixture sidesteps it.
Map<String, dynamic> _paymentMethodJson() => <String, dynamic>{
  "id": "pm-1",
  "methodType": "card",
  "providerRef": "Visa ...4242",
  "isDefault": true,
};

void main() {
  group("PaymentMethodRemoteDataSource.getSavedPaymentMethods", () {
    test(
      "throws PaymentMethodApiNotConfiguredFailure when baseUrl is null",
      () {
        final source = PaymentMethodRemoteDataSource(
          http.Client(),
          baseUrl: null,
        );
        expect(
          () => source.getSavedPaymentMethods(),
          throwsA(isA<PaymentMethodApiNotConfiguredFailure>()),
        );
      },
    );

    test("GETs {baseUrl}/v1/users/me/payment-methods and parses the "
        "{data: [...]} envelope", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "data": <Map<String, dynamic>>[_paymentMethodJson()],
          }),
          200,
        );
      });
      final source = PaymentMethodRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dtos = await source.getSavedPaymentMethods();

      expect(capturedUri?.path, "/v1/users/me/payment-methods");
      expect(dtos, hasLength(1));
      expect(dtos.single.id, "pm-1");
    });

    test("throws PaymentMethodRequestFailure on a non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final source = PaymentMethodRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.getSavedPaymentMethods(),
        throwsA(isA<PaymentMethodRequestFailure>()),
      );
    });
  });

  group("PaymentMethodRemoteDataSource.addPaymentMethod", () {
    test(
      "POSTs the method type and provider token, parses a 201 response",
      (() async {
        Uri? capturedUri;
        String? capturedBody;
        final client = MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;
          return http.Response(jsonEncode(_paymentMethodJson()), 201);
        });
        final source = PaymentMethodRemoteDataSource(
          client,
          baseUrl: "http://test.local",
        );

        final dto = await source.addPaymentMethod(
          methodType: "card",
          providerToken: "mock-token-1",
        );

        expect(capturedUri?.path, "/v1/users/me/payment-methods");
        expect(jsonDecode(capturedBody!), <String, dynamic>{
          "methodType": "card",
          "providerToken": "mock-token-1",
        });
        expect(dto.id, "pm-1");
      }),
    );

    test("throws PaymentMethodRequestFailure on a non-201 response", () {
      final client = MockClient(
        (request) async => http.Response("bad request", 400),
      );
      final source = PaymentMethodRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.addPaymentMethod(
          methodType: "card",
          providerToken: "mock-token-1",
        ),
        throwsA(isA<PaymentMethodRequestFailure>()),
      );
    });
  });
}
