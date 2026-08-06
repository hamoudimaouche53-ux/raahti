import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/emergency_repository.dart";
import "../dtos/emergency_facility_result_dto.dart";

/// Calls `GET {baseUrl}/v1/emergency/nearest-facility?lat=..&lng=..` per
/// docs/api/openapi.yaml — mirrors `AccessSessionRemoteDataSource`'s exact
/// conventions (10s timeout, "not configured" check throwing this
/// feature's own failure type, non-200/404 → generic request-failure
/// exception).
class EmergencyRemoteDataSource {
  const EmergencyRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  /// Returns `null` on a `404` response ("no accessible facility found
  /// nearby") — not an exception, per [EmergencyRepository]'s own doc
  /// comment.
  Future<EmergencyFacilityResultDto?> fetchNearestFacility({
    required double lat,
    required double lng,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const EmergencyApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse(
      "$baseUrl/v1/emergency/nearest-facility",
    ).replace(queryParameters: <String, String>{"lat": "$lat", "lng": "$lng"});
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw EmergencyRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw EmergencyRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return EmergencyFacilityResultDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
