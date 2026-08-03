import "../../domain/entities/access_session.dart";
import "../../domain/entities/access_session_status.dart";

/// JSON mapping for the `AccessSession` schema in docs/api/openapi.yaml —
/// shared by `POST /access-sessions` (201) and `GET /access-sessions/{id}`
/// (200). Field set matches the schema exactly; see
/// `AccessSession`'s own doc comment for why `qrCodeScanned`, `userId`,
/// and `transaction` are deliberately absent.
class AccessSessionDto {
  const AccessSessionDto({
    required this.id,
    required this.cabinId,
    required this.status,
    required this.startedAt,
    required this.unlockedAt,
  });

  factory AccessSessionDto.fromJson(Map<String, dynamic> json) {
    return AccessSessionDto(
      id: json["id"] as String,
      cabinId: json["cabinId"] as String,
      status: json["status"] as String,
      startedAt: json["startedAt"] as String,
      unlockedAt: json["unlockedAt"] as String?,
    );
  }

  final String id;
  final String cabinId;

  /// Wire value is `snake_case` (e.g. `payment_pending`), not the Dart
  /// enum's `camelCase` name — mapped explicitly below, same discipline
  /// as `StationDetailDto.configuration`.
  final String status;
  final String startedAt;
  final String? unlockedAt;

  AccessSession toEntity() {
    return AccessSession(
      id: id,
      cabinId: cabinId,
      status: switch (status) {
        "initiated" => AccessSessionStatus.initiated,
        "payment_pending" => AccessSessionStatus.paymentPending,
        "unlocked" => AccessSessionStatus.unlocked,
        "in_use" => AccessSessionStatus.inUse,
        "completed" => AccessSessionStatus.completed,
        "cancelled" => AccessSessionStatus.cancelled,
        _ => AccessSessionStatus.initiated,
      },
      startedAt: DateTime.parse(startedAt),
      unlockedAt: unlockedAt == null ? null : DateTime.parse(unlockedAt!),
    );
  }
}
