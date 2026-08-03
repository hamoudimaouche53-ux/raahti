import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/payment_method_repository.dart";
import "../dtos/payment_method_dto.dart";

/// Calls `GET`/`POST {baseUrl}/v1/users/me/payment-methods` per
/// docs/api/openapi.yaml — same `baseUrl`-injected pattern as
/// `AccessSessionRemoteDataSource`.
class PaymentMethodRemoteDataSource {
  const PaymentMethodRemoteDataSource(
    this._client, {
    required this._baseUrl,
  });

  final http.Client _client;
  final String? _baseUrl;

  Future<List<PaymentMethodDto>> getSavedPaymentMethods() async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const PaymentMethodApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/users/me/payment-methods");
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw PaymentMethodRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 200) {
      throw PaymentMethodRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body["data"] as List<dynamic>? ?? <dynamic>[];
    return data
        .map((e) => PaymentMethodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentMethodDto> addPaymentMethod({
    required String methodType,
    required String providerToken,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const PaymentMethodApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/users/me/payment-methods");
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{"Content-Type": "application/json"},
            body: jsonEncode(<String, String>{
              "methodType": methodType,
              "providerToken": providerToken,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw PaymentMethodRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 201) {
      throw PaymentMethodRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return PaymentMethodDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
