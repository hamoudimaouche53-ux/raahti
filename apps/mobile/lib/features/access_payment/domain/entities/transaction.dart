import "discount_rate.dart";
import "money.dart";
import "transaction_status.dart";

/// A payment transaction — `TRANSACTION` in docs/erd/erd.md §3.10,
/// `Transaction` in docs/api/openapi.yaml.
///
/// Modeled here as [AccessSession]'s owned child (docs/architecture/
/// domain-model.md §6: "`AccessSession` (aggregate root) owns its optional
/// `Transaction`") rather than holding a back-reference to its session —
/// the ERD's own `transaction.access_session_id` FK is a persistence-layer
/// detail (a transaction may also exist standalone, e.g. a subscription
/// charge with no session), not something this app's domain model needs
/// to represent, since EPIC-04 only ever reads a `Transaction` through the
/// `AccessSession` that owns it.
class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.discountApplied,
    required this.status,
    required this.providerRef,
  });

  final String id;
  final Money amount;

  /// `null` when no discount applied (the normal V1 case — see
  /// [DiscountRate]'s doc comment).
  final DiscountRate? discountApplied;
  final TransactionStatus status;

  /// Opaque provider transaction reference (ADR-0014) — `null` while
  /// `status == pending`, before the mock/real gateway has assigned one.
  final String? providerRef;

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.amount == amount &&
      other.discountApplied == discountApplied &&
      other.status == status &&
      other.providerRef == providerRef;

  @override
  int get hashCode =>
      Object.hash(id, amount, discountApplied, status, providerRef);
}
