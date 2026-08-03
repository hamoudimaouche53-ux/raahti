import "dart:convert";

import "package:http/http.dart" as http;

import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../domain/repositories/slatoki_place_repository.dart";
import "../dtos/slatoki_place_dto.dart";

/// Calls `GET {baseUrl}/v1/slatoki/places` per docs/api/openapi.yaml.
/// Public (unauthenticated) endpoint — `security: []` in the contract.
///
/// The API's own `filter` query parameter is deliberately never sent —
/// filtering happens client-side (`filterSlatokiPlaces()`), the same
/// ADR-0021 call the Map's search/category filters made, so switching the
/// active tab never triggers a new network request.
class SlatokiPlaceRemoteDataSource {
  const SlatokiPlaceRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<List<SlatokiPlaceDto>> fetchSlatokiPlaces({
    required Coordinates center,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const SlatokiApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/slatoki/places").replace(
      queryParameters: <String, String>{
        "lat": center.latitude.toString(),
        "lng": center.longitude.toString(),
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw SlatokiPlaceFetchFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 200) {
      throw SlatokiPlaceFetchFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body["data"] as List<dynamic>? ?? <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(SlatokiPlaceDto.fromJson)
        .toList(growable: false);
  }
}
