import "../../../access_payment/data/dtos/money_dto.dart";
import "../../../access_payment/domain/entities/money.dart";
import "../../domain/entities/visit.dart";

/// JSON mapping for the `VisitHistoryItem` schema in docs/api/openapi.yaml
/// (`GET /users/me/visit-history`). Reuses `access_payment`'s [MoneyDto]
/// for [amount] — same value shape SCR-019 already parses, not a
/// re-derived display figure (see [Visit]'s own doc comment on why it
/// reuses `access_payment`'s `Money`, not `map_discovery`'s).
class VisitHistoryItemDto {
  const VisitHistoryItemDto({
    required this.id,
    required this.placeName,
    required this.occurredAt,
    required this.amount,
  });

  factory VisitHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? amountJson =
        json["amount"] as Map<String, dynamic>?;
    return VisitHistoryItemDto(
      id: json["id"] as String,
      placeName: json["placeName"] as String,
      occurredAt: DateTime.parse(json["occurredAt"] as String),
      amount: amountJson == null
          ? null
          : MoneyDto.fromJson(amountJson).toEntity(),
    );
  }

  final String id;
  final String placeName;
  final DateTime occurredAt;

  /// `null` for free-cabin visits, per the schema's own doc comment.
  final Money? amount;

  Visit toEntity() {
    return Visit(
      id: id,
      placeName: placeName,
      occurredAt: occurredAt,
      amount: amount,
    );
  }
}
