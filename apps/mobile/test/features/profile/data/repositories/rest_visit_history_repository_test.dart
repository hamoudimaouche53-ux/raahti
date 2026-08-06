import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/profile/data/datasources/visit_history_remote_data_source.dart";
import "package:rahati/features/profile/data/repositories/rest_visit_history_repository.dart";

void main() {
  test("RestVisitHistoryRepository maps every VisitHistoryItemDto returned by "
      "the remote data source to a Visit", () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          "data": [
            <String, dynamic>{
              "id": "v1",
              "placeName": "Station Didouche",
              "occurredAt": "2026-08-01T09:15:00.000Z",
              "amount": <String, dynamic>{"amount": "50", "currency": "DZD"},
            },
            <String, dynamic>{
              "id": "v2",
              "placeName": "Station El Djazair",
              "occurredAt": "2026-07-20T14:30:00.000Z",
              "amount": null,
            },
          ],
          "nextCursor": null,
        }),
        200,
      );
    });
    final repo = RestVisitHistoryRepository(
      VisitHistoryRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
    );

    final visits = await repo.getVisitHistory();

    expect(visits, hasLength(2));
    expect(visits[0].id, "v1");
    expect(visits[0].placeName, "Station Didouche");
    expect(visits[0].amount!.amount, "50");
    expect(visits[1].id, "v2");
    expect(visits[1].amount, isNull);
  });
}
