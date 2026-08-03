import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/profile/data/repositories/rest_visit_history_repository.dart";
import "package:rahati/features/profile/domain/repositories/visit_history_repository.dart";

void main() {
  test(
    "RestVisitHistoryRepository always throws "
    "VisitHistoryEndpointNotSpecifiedFailure (no listing endpoint exists)",
    () async {
      const repo = RestVisitHistoryRepository();
      expect(
        () => repo.getVisitHistory(),
        throwsA(isA<VisitHistoryEndpointNotSpecifiedFailure>()),
      );
    },
  );
}
