import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/favorite_repository.dart";
import "../dtos/favorite_dto.dart";

/// Calls `GET`/`POST {baseUrl}/v1/users/me/favorites` per
/// docs/api/openapi.yaml — same `baseUrl`-injected pattern as
/// `PaymentMethodRemoteDataSource`.
class FavoriteRemoteDataSource {
  const FavoriteRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<List<FavoriteDto>> getFavorites() async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const FavoriteApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/users/me/favorites");
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw FavoriteRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 200) {
      throw FavoriteRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body["data"] as List<dynamic>? ?? <dynamic>[];
    return data
        .map((e) => FavoriteDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FavoriteDto> addFavorite({
    required String? stationId,
    required String? thirdPartyPlaceId,
    required bool notifyOnAvailable,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const FavoriteApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/users/me/favorites");
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{"Content-Type": "application/json"},
            body: jsonEncode(<String, dynamic>{
              "stationId": stationId,
              "thirdPartyPlaceId": thirdPartyPlaceId,
              "notifyOnAvailable": notifyOnAvailable,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw FavoriteRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 201) {
      throw FavoriteRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return FavoriteDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
