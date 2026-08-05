import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/review_repository.dart";
import "../dtos/review_dto.dart";

/// Calls `POST {baseUrl}/v1/places/{placeType}/{placeId}/reviews` per
/// docs/api/openapi.yaml — same `baseUrl`-injected pattern as every other
/// `*RemoteDataSource`. [placeType]'s wire value is hyphenated
/// (`third-party-place`), not the Dart enum's `camelCase` name — mapped
/// explicitly by the caller ([RestReviewRepository]), same discipline
/// `PaymentMethodDto.methodType` already applies to its own wire enum.
class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<ReviewDto> submitReview({
    required String placeType,
    required String placeId,
    required int rating,
    required String? comment,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const ReviewApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse("$baseUrl/v1/places/$placeType/$placeId/reviews");
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{"Content-Type": "application/json"},
            body: jsonEncode(<String, dynamic>{
              "rating": rating,
              "comment": comment,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ReviewRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode != 201) {
      throw ReviewRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return ReviewDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
