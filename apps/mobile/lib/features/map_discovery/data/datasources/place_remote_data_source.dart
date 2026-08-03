import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/entities/coordinates.dart";
import "../../domain/repositories/place_repository.dart";
import "../dtos/place_dto.dart";

/// Calls `GET {baseUrl}/v1/places/nearby` per docs/api/openapi.yaml.
/// Public (unauthenticated) endpoint — `security: []` in the contract — so
/// no auth header is sent, matching FR-USR-01's optional-account model.
///
/// [baseUrl] is injected (from `AppEnv.apiBaseUrl` via
/// `placeRemoteDataSourceProvider`) rather than read from `AppEnv` inside
/// this class — keeps this class trivially testable with a fixed URL and a
/// `package:http/testing.dart` `MockClient`, with no compile-time
/// `--dart-define` gymnastics needed in tests.
class PlaceRemoteDataSource {
  const PlaceRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<List<PlaceDto>> fetchNearbyPlaces({
    required Coordinates center,
    required double radiusMeters,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const ApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/places/nearby").replace(
      queryParameters: <String, String>{
        "lat": center.latitude.toString(),
        "lng": center.longitude.toString(),
        "radiusMeters": radiusMeters.round().toString(),
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw PlaceFetchFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 200) {
      throw PlaceFetchFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body["data"] as List<dynamic>? ?? <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(PlaceDto.fromJson)
        .toList(growable: false);
  }
}
