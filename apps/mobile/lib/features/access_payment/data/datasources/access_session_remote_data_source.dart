import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/access_session_repository.dart";
import "../dtos/access_session_dto.dart";

/// Calls `POST {baseUrl}/v1/access-sessions` and
/// `GET {baseUrl}/v1/access-sessions/{id}` per docs/api/openapi.yaml —
/// same `baseUrl`-injected, `AppEnv.apiBaseUrl`-backed pattern as
/// `SlatokiPlaceRemoteDataSource`/`PlaceRemoteDataSource`.
///
/// Per ADR-0008, both calls are strictly online — no offline write-queue
/// fallback (unlike `map_discovery`'s cached reads).
class AccessSessionRemoteDataSource {
  const AccessSessionRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<AccessSessionDto> initiateAccessSession({
    required String qrCodeScanned,
    required String idempotencyKey,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const AccessPaymentApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/access-sessions");
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              "Content-Type": "application/json",
              "Idempotency-Key": idempotencyKey,
            },
            body: jsonEncode(<String, String>{"qrCodeScanned": qrCodeScanned}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AccessSessionRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode == 409) {
      throw const CabinUnavailableFailure();
    }
    if (response.statusCode != 201) {
      throw AccessSessionRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return AccessSessionDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AccessSessionDto> fetchAccessSession(String accessSessionId) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const AccessPaymentApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/access-sessions/$accessSessionId");
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AccessSessionRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 200) {
      throw AccessSessionRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return AccessSessionDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
