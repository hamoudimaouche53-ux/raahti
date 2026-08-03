import "../../domain/entities/discount_rate.dart";
import "../../domain/entities/transaction.dart";
import "../../domain/entities/transaction_status.dart";
import "access_session_dto.dart";
import "money_dto.dart";

/// JSON mapping for the `Transaction` schema in docs/api/openapi.yaml —
/// the response body of `POST /access-sessions/{id}/payments`.
///
/// Per `Transaction`'s own doc comment, the wire schema embeds
/// `accessSession` (the opposite direction from the ERD's FK) — this DTO
/// carries it through as [accessSession] so [PaymentRepository] can
/// return the updated [AccessSession] its port contract promises, without
/// a second round-trip.
class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.amount,
    required this.discountApplied,
    required this.status,
    required this.accessSession,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json["id"] as String,
      amount: MoneyDto.fromJson(json["amount"] as Map<String, dynamic>),
      discountApplied: json["discountApplied"] as String?,
      status: json["status"] as String,
      accessSession: AccessSessionDto.fromJson(
        json["accessSession"] as Map<String, dynamic>,
      ),
    );
  }

  final String id;
  final MoneyDto amount;

  /// Wire value is a decimal-percentage string (e.g. `"50"`), same
  /// string-not-double discipline as `Money.amount` — never set by any
  /// V1 flow (see `DiscountRate`'s doc comment), but parsed faithfully
  /// since the schema documents it.
  final String? discountApplied;
  final String status;
  final AccessSessionDto accessSession;

  Transaction toEntity() {
    return Transaction(
      id: id,
      amount: amount.toEntity(),
      discountApplied: discountApplied == null
          ? null
          : DiscountRate(double.parse(discountApplied!)),
      status: switch (status) {
        "pending" => TransactionStatus.pending,
        "authorized" => TransactionStatus.authorized,
        "captured" => TransactionStatus.captured,
        "failed" => TransactionStatus.failed,
        "refunded" => TransactionStatus.refunded,
        _ => TransactionStatus.pending,
      },
      // Documented gap, same category as `AccessSession.closedAt`
      // (Feature 12): the OpenAPI `Transaction` schema doesn't expose
      // `providerRef` at all, even though the domain entity models it —
      // always `null` from this DTO until a future contract version adds
      // the field.
      providerRef: null,
    );
  }
}
