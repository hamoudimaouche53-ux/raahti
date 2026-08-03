import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/place_repository.dart";
import "../dtos/station_detail_dto.dart";
import "../dtos/third_party_place_detail_dto.dart";

/// Calls `GET {baseUrl}/v1/stations/{id}` and
/// `GET {baseUrl}/v1/third-party-places/{id}` per docs/api/openapi.yaml
/// (US-01.2.2/US-01.2.3, FR-PLC-02/03). Same construction/failure pattern
/// as [PlaceRemoteDataSource] — [baseUrl] injected, no auth header (both
/// endpoints are `security: []`, public discovery).
class PlaceDetailRemoteDataSource {
  const PlaceDetailRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<StationDetailDto> fetchStationDetail(String stationId) async {
    final Map<String, dynamic> json = await _get("stations/$stationId");
    return StationDetailDto.fromJson(json);
  }

  Future<ThirdPartyPlaceDetailDto> fetchThirdPartyPlaceDetail(
    String placeId,
  ) async {
    final Map<String, dynamic> json = await _get("third-party-places/$placeId");
    return ThirdPartyPlaceDetailDto.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const ApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/$path");
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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
