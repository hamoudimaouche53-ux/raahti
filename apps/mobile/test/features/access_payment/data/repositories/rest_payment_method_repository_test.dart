import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/access_payment/data/datasources/payment_method_remote_data_source.dart";
import "package:rahati/features/access_payment/data/repositories/rest_payment_method_repository.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_method_repository.dart";

void main() {
  group("RestPaymentMethodRepository", () {
    test("getSavedPaymentMethods delegates and maps DTOs to entities", () async {
      final client = MockClient((request) async {
        // ASCII, not the real UI's "Visa •••• 4242" — `http.Response`'s
        // default `latin1` encoding can't represent U+2022 BULLET.
        return http.Response(
          '{"data":[{"id":"pm-1","methodType":"card",'
          '"providerRef":"Visa ...4242","isDefault":true}]}',
          200,
        );
      });
      final repository = RestPaymentMethodRepository(
        PaymentMethodRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.getSavedPaymentMethods();

      expect(result, hasLength(1));
      expect(result.single.id, "pm-1");
    });

    test("addPaymentMethod converts the enum to its wire snake_case value "
        "and maps the response back to an entity", () async {
      String? capturedBody;
      final client = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(
          '{"id":"pm-2","methodType":"mobile_wallet",'
          '"providerRef":"Wallet Mobile","isDefault":false}',
          201,
        );
      });
      final repository = RestPaymentMethodRepository(
        PaymentMethodRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final result = await repository.addPaymentMethod(
        methodType: PaymentMethodType.mobileWallet,
        providerToken: "mock-token-1",
      );

      expect(capturedBody, contains('"methodType":"mobile_wallet"'));
      expect(result.id, "pm-2");
      expect(result.methodType, PaymentMethodType.mobileWallet);
    });

    test(
      "deletePaymentMethod always throws "
      "PaymentMethodEndpointNotSpecifiedFailure (no delete endpoint "
      "exists)",
      () {
        final repository = RestPaymentMethodRepository(
          PaymentMethodRemoteDataSource(
            http.Client(),
            baseUrl: "http://test.local",
          ),
        );
        expect(
          () => repository.deletePaymentMethod("pm-1"),
          throwsA(isA<PaymentMethodEndpointNotSpecifiedFailure>()),
        );
      },
    );

    test(
      "setDefaultPaymentMethod always throws "
      "PaymentMethodEndpointNotSpecifiedFailure (no update endpoint "
      "exists)",
      () {
        final repository = RestPaymentMethodRepository(
          PaymentMethodRemoteDataSource(
            http.Client(),
            baseUrl: "http://test.local",
          ),
        );
        expect(
          () => repository.setDefaultPaymentMethod("pm-1"),
          throwsA(isA<PaymentMethodEndpointNotSpecifiedFailure>()),
        );
      },
    );
  });
}
