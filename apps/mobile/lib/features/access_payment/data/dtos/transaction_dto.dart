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
      id: json["id"] as String?,
      amount: json["amount"] == null
          ? null
          : MoneyDto.fromJson(json["amount"] as Map<String, dynamic>),
      discountApplied: json["discountApplied"] as String?,
      status: json["status"] as String?,
      accessSession: AccessSessionDto.fromJson(
        json["accessSession"] as Map<String, dynamic>,
      ),
    );
  }

  /// `id`/`amount`/`status` are all `null` when the backend's response
  /// carries no Transaction — the free-cabin path (ERD §"TRANSACTION":
  /// "a free-access session produces no transaction row";
  /// `TransactionResponseDto.fromDomain`, backend, leaves them
  /// unset/`undefined` in that case rather than sending placeholder
  /// values).
  final String? id;
  final MoneyDto? amount;

  /// Wire value is a decimal-percentage string (e.g. `"50"`), same
  /// string-not-double discipline as `Money.amount` — never set by any
  /// V1 flow (see `DiscountRate`'s doc comment), but parsed faithfully
  /// since the schema documents it.
  final String? discountApplied;
  final String? status;
  final AccessSessionDto accessSession;

  /// `null` when this response carried no Transaction (free-cabin path,
  /// see [id]'s doc comment) — `AccessSession` owns an *optional*
  /// `Transaction` (domain-model.md §6), so the nullability belongs here,
  /// not as placeholder values inside a always-present `Transaction`.
  Transaction? toEntity() {
    final String? transactionId = id;
    final MoneyDto? transactionAmount = amount;
    final String? transactionStatus = status;
    if (transactionId == null ||
        transactionAmount == null ||
        transactionStatus == null) {
      return null;
    }
    return Transaction(
      id: transactionId,
      amount: transactionAmount.toEntity(),
      discountApplied: discountApplied == null
          ? null
          : DiscountRate(double.parse(discountApplied!)),
      status: switch (transactionStatus) {
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
