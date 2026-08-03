import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/user_repository.dart";
import "../dtos/app_user_dto.dart";

/// Calls `GET {baseUrl}/v1/users/me` per docs/api/openapi.yaml — same
/// `baseUrl`-injected pattern as every other `*RemoteDataSource`.
class UserRemoteDataSource {
  const UserRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<AppUserDto> getCurrentUser() async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const UserApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/users/me");
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw UserRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 200) {
      throw UserRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return AppUserDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
