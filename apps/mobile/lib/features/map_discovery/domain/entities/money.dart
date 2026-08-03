/// A monetary amount, mirroring the `Money` schema in
/// docs/api/openapi.yaml — amount kept as a decimal string (never a
/// `double`) to avoid float-rounding error, per the API contract's own
/// documented rationale.
class Money {
  const Money({required this.amount, required this.currency});

  final String amount;
  final String currency;

  /// Parsed only for display formatting — never for arithmetic (this app
  /// never computes totals/discounts; that belongs to EPIC-04's Access &
  /// Payment domain, not map discovery).
  double get amountAsDouble => double.parse(amount);

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}
