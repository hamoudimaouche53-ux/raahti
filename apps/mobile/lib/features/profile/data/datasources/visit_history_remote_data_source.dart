import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/visit_history_repository.dart";
import "../dtos/visit_history_item_dto.dart";

/// Calls `GET {baseUrl}/v1/users/me/visit-history` per
/// docs/api/openapi.yaml — same `baseUrl`-injected pattern as every other
/// `*RemoteDataSource`.
///
/// Follows the backend's `cursor`/`nextCursor` pagination to completion —
/// same reasoning `FavoriteRemoteDataSource.getFavorites()` already
/// applies: this method's return type is a flat `List<VisitHistoryItemDto>`
/// (matching `VisitHistoryRepository.getVisitHistory`'s own
/// `Future<List<Visit>>` contract, not a page), so returning only the
/// first page would silently drop every visit past the backend's default
/// page size (20).
class VisitHistoryRemoteDataSource {
  const VisitHistoryRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<List<VisitHistoryItemDto>> getVisitHistory() async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const VisitHistoryApiNotConfiguredFailure();
    }

    final List<VisitHistoryItemDto> visits = [];
    String? cursor;
    do {
      final Uri uri = Uri.parse("$baseUrl/v1/users/me/visit-history").replace(
        queryParameters: cursor == null
            ? null
            : <String, String>{"cursor": cursor},
      );
      final http.Response response;
      try {
        response = await _client.get(uri).timeout(const Duration(seconds: 10));
      } catch (e) {
        throw VisitHistoryRequestFailure("Could not reach the backend: $e");
      }

      if (response.statusCode != 200) {
        throw VisitHistoryRequestFailure(
          "Backend returned HTTP ${response.statusCode} for $uri",
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data = body["data"] as List<dynamic>? ?? <dynamic>[];
      visits.addAll(
        data.map(
          (e) => VisitHistoryItemDto.fromJson(e as Map<String, dynamic>),
        ),
      );
      cursor = body["nextCursor"] as String?;
    } while (cursor != null);

    return visits;
  }
}
