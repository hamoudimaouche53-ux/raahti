import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/profile/data/repositories/mock_visit_history_repository.dart";

void main() {
  test("MockVisitHistoryRepository returns visits spanning two months", () async {
    const repo = MockVisitHistoryRepository();
    final visits = await repo.getVisitHistory();
    expect(visits.length, greaterThanOrEqualTo(3));
    expect(visits.any((v) => v.amount == null), isTrue);
    expect(visits.any((v) => v.amount != null), isTrue);
  });
}
