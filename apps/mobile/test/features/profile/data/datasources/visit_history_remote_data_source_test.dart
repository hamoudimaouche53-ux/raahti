import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/profile/data/datasources/visit_history_remote_data_source.dart";
import "package:rahati/features/profile/domain/repositories/visit_history_repository.dart";

Map<String, dynamic> _visitJson(String id, {String? amount}) =>
    <String, dynamic>{
      "id": id,
      "placeName": "Station Didouche",
      "occurredAt": "2026-08-01T09:15:00.000Z",
      "amount": amount == null
          ? null
          : <String, dynamic>{"amount": amount, "currency": "DZD"},
    };

void main() {
  group("VisitHistoryRemoteDataSource.getVisitHistory", () {
    test("throws VisitHistoryApiNotConfiguredFailure when baseUrl is null", () {
      final source = VisitHistoryRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.getVisitHistory(),
        throwsA(isA<VisitHistoryApiNotConfiguredFailure>()),
      );
    });

    test("requests GET {baseUrl}/v1/users/me/visit-history and parses a single "
        "page, including a null amount for free visits", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "data": [_visitJson("v1", amount: "50")],
            "nextCursor": null,
          }),
          200,
        );
      });
      final source = VisitHistoryRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      final visits = await source.getVisitHistory();

      expect(
        capturedUri,
        Uri.parse("https://api.raahti.dz/v1/users/me/visit-history"),
      );
      expect(visits, hasLength(1));
      expect(visits.single.id, "v1");
      expect(visits.single.amount!.amount, "50");
    });

    test(
      "follows nextCursor until exhausted, returning every visit across pages",
      () async {
        final List<Uri> capturedUris = [];
        final client = MockClient((request) async {
          capturedUris.add(request.url);
          if (request.url.queryParameters["cursor"] == null) {
            return http.Response(
              jsonEncode(<String, dynamic>{
                "data": [_visitJson("v1")],
                "nextCursor": "cursor-1",
              }),
              200,
            );
          }
          if (request.url.queryParameters["cursor"] == "cursor-1") {
            return http.Response(
              jsonEncode(<String, dynamic>{
                "data": [_visitJson("v2", amount: "20")],
                "nextCursor": null,
              }),
              200,
            );
          }
          throw StateError("Unexpected cursor: ${request.url}");
        });
        final source = VisitHistoryRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        final visits = await source.getVisitHistory();

        expect(capturedUris, hasLength(2));
        expect(visits.map((v) => v.id), ["v1", "v2"]);
      },
    );

    test("throws VisitHistoryRequestFailure on a non-200 response", () async {
      final client = MockClient((request) async => http.Response("", 401));
      final source = VisitHistoryRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.getVisitHistory(),
        throwsA(isA<VisitHistoryRequestFailure>()),
      );
    });

    test(
      "throws VisitHistoryRequestFailure when the network call itself fails",
      () async {
        final client = MockClient(
          (request) async => throw Exception("offline"),
        );
        final source = VisitHistoryRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        expect(
          () => source.getVisitHistory(),
          throwsA(isA<VisitHistoryRequestFailure>()),
        );
      },
    );
  });
}
