/// A percentage discount applied to a [Transaction], e.g. the Mode Urgence
/// 50% diabetic-emergency discount (FR-EMG-03, `transaction.discount_applied`
/// in docs/erd/erd.md §3.10).
///
/// EPIC-04 only *carries* this value — it never computes or triggers a
/// discount itself. Mode Urgence (EPIC-03) is V1.1-scoped and not built in
/// this codebase yet (ADR-0024 precedent), so no UI path in this epic sets
/// `applyEmergencyDiscount: true` on `POST /access-sessions/{id}/payments`;
/// this type exists so the domain layer and DTOs stay contract-complete
/// and forward-compatible without inventing any V1.1 behavior.
class DiscountRate {
  factory DiscountRate(double percentage) {
    if (percentage <= 0 || percentage > 100) {
      throw ArgumentError.value(
        percentage,
        "percentage",
        "Discount percentage must be in (0, 100]",
      );
    }
    return DiscountRate._(percentage);
  }

  const DiscountRate._(this.percentage);

  /// e.g. `50` for a 50% discount.
  final double percentage;

  @override
  bool operator ==(Object other) =>
      other is DiscountRate && other.percentage == percentage;

  @override
  int get hashCode => percentage.hashCode;

  @override
  String toString() => "$percentage%";
}
