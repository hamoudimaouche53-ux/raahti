import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/review_remote_data_source.dart";
import "package:rahati/features/map_discovery/domain/repositories/review_repository.dart";

void main() {
  group("ReviewRemoteDataSource.submitReview", () {
    test("throws ReviewApiNotConfiguredFailure when baseUrl is null", () {
      final source = ReviewRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.submitReview(
          placeType: "station",
          placeId: "s1",
          rating: 5,
          comment: null,
        ),
        throwsA(isA<ReviewApiNotConfiguredFailure>()),
      );
    });

    test("POSTs {baseUrl}/v1/places/{placeType}/{placeId}/reviews with the "
        "rating/comment body and parses a 201 response", () async {
      Uri? capturedUri;
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "id": "r1",
            "rating": 4,
            "comment": "Propre et rapide",
            "createdAt": "2026-08-01T10:00:00.000Z",
          }),
          201,
        );
      });
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      final dto = await source.submitReview(
        placeType: "third-party-place",
        placeId: "p1",
        rating: 4,
        comment: "Propre et rapide",
      );

      expect(
        capturedUri,
        Uri.parse(
          "https://api.raahti.dz/v1/places/third-party-place/p1/reviews",
        ),
      );
      expect(capturedBody, <String, dynamic>{
        "rating": 4,
        "comment": "Propre et rapide",
      });
      expect(dto.id, "r1");
      expect(dto.rating, 4);
      expect(dto.comment, "Propre et rapide");
    });

    test("throws ReviewRequestFailure on a non-201 response", () async {
      final client = MockClient((request) async => http.Response("", 400));
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.submitReview(
          placeType: "station",
          placeId: "s1",
          rating: 5,
          comment: null,
        ),
        throwsA(isA<ReviewRequestFailure>()),
      );
    });

    test(
      "throws ReviewRequestFailure when the network call itself fails",
      () async {
        final client = MockClient(
          (request) async => throw Exception("offline"),
        );
        final source = ReviewRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        expect(
          () => source.submitReview(
            placeType: "station",
            placeId: "s1",
            rating: 5,
            comment: null,
          ),
          throwsA(isA<ReviewRequestFailure>()),
        );
      },
    );
  });
}
