/// A monetary amount, mirroring the `Money` schema in
/// docs/api/openapi.yaml — amount kept as a decimal string (never a
/// `double`) to avoid float-rounding error, per the API contract's own
/// documented rationale.
///
/// Deliberately **not** the same class as `map_discovery`'s `Money` —
/// that copy is display-only by its own doc comment ("this app never
/// computes totals/discounts; that belongs to EPIC-04's Access & Payment
/// domain"). Access & Payment is the bounded context that actually owns
/// this value object per docs/architecture/domain-model.md §6, so it gets
/// its own copy here rather than a cross-feature import — same
/// feature-isolation discipline `slatoki` already applies to its own
/// repository/failure vocabulary.
class Money {
  const Money({required this.amount, required this.currency});

  final String amount;
  final String currency;

  double get amountAsDouble => double.parse(amount);

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => "$amount $currency";
}
