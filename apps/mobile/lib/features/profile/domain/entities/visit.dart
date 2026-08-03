import "../../../access_payment/domain/entities/money.dart";

/// One completed access session, as SCR-021 (Visit History) needs to
/// display it — place name, when, and what (if anything) was paid.
///
/// A narrower read-model than `access_payment`'s own `AccessSession`
/// (deliberately so, same "narrower than the source aggregate" pattern
/// `CabinOccupancyUpdate` already established) — `Visit` also carries a
/// resolved [placeName], which `AccessSession` never has (it only knows
/// `cabinId`), because SCR-021's wireframe requires the place name
/// directly in each list row. Reuses `access_payment`'s [Money], not
/// `map_discovery`'s — a visit's amount is the same value SCR-019 already
/// displayed for that session, not a re-derived display figure.
class Visit {
  const Visit({
    required this.id,
    required this.placeName,
    required this.occurredAt,
    required this.amount,
  });

  final String id;
  final String placeName;
  final DateTime occurredAt;

  /// `null` — free cabin, same convention `SessionCompleteArgs.amount`
  /// already uses.
  final Money? amount;

  @override
  bool operator ==(Object other) =>
      other is Visit &&
      other.id == id &&
      other.placeName == placeName &&
      other.occurredAt == occurredAt &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(id, placeName, occurredAt, amount);
}
