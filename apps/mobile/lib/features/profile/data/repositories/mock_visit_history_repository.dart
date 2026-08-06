import "../../../access_payment/domain/entities/money.dart";
import "../../domain/entities/visit.dart";
import "../../domain/repositories/visit_history_repository.dart";

/// **Explicitly-opt-in mock adapter** for [VisitHistoryRepository] —
/// gated by `AppEnv.useMockAuth`, for demoing SCR-021 without a deployed
/// backend. Returns a fixed, clearly-fabricated list spanning two months,
/// so SCR-021's month-grouped section-header layout has something to
/// group.
class MockVisitHistoryRepository implements VisitHistoryRepository {
  const MockVisitHistoryRepository();

  @override
  Future<List<Visit>> getVisitHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final DateTime now = DateTime.now();
    return [
      Visit(
        id: "mock-visit-1",
        placeName: "Station Didouche",
        occurredAt: DateTime(now.year, now.month, 2, 9, 15),
        amount: const Money(amount: "50", currency: "DZD"),
      ),
      Visit(
        id: "mock-visit-2",
        placeName: "Station El Djazair",
        occurredAt: DateTime(now.year, now.month, 8, 14, 30),
        amount: null,
      ),
      Visit(
        id: "mock-visit-3",
        placeName: "Station Didouche",
        occurredAt: DateTime(now.year, now.month - 1, 20, 18, 45),
        amount: const Money(amount: "50", currency: "DZD"),
      ),
    ];
  }
}
