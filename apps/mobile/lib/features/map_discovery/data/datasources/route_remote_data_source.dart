import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/entities/coordinates.dart";
import "../../domain/repositories/route_repository.dart";
import "../dtos/route_dto.dart";

/// Calls `GET {baseUrl}/v1/routes/walking` per docs/api/openapi.yaml.
/// Public (unauthenticated) endpoint — `security: []` in the contract, same
/// as `PlaceRemoteDataSource`'s `/places/nearby` — so no auth header is
/// sent.
///
/// [baseUrl] is injected (from `AppEnv.apiBaseUrl` via
/// `routeRemoteDataSourceProvider`), same reasoning as
/// `PlaceRemoteDataSource`'s own doc comment — trivially testable with a
/// fixed URL and a `package:http/testing.dart` `MockClient`.
class RouteRemoteDataSource {
  const RouteRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<RouteDto> fetchWalkingRoute({
    required Coordinates origin,
    required Coordinates destination,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const RouteApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/routes/walking").replace(
      queryParameters: <String, String>{
        "originLat": origin.latitude.toString(),
        "originLng": origin.longitude.toString(),
        "destLat": destination.latitude.toString(),
        "destLng": destination.longitude.toString(),
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw RouteFetchFailure("Could not reach the backend: $e");
    }

    if (response.statusCode == 404) {
      throw const RouteNotFoundFailure();
    }
    if (response.statusCode != 200) {
      throw RouteFetchFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    return RouteDto.fromJson(body);
  }
}
