import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/data/dtos/access_session_dto.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";

void main() {
  group("AccessSessionDto", () {
    test("parses a full JSON payload", () {
      final dto = AccessSessionDto.fromJson(<String, dynamic>{
        "id": "session-1",
        "cabinId": "cabin-1",
        "status": "payment_pending",
        "startedAt": "2026-08-01T10:00:00.000Z",
        "unlockedAt": null,
      });

      final entity = dto.toEntity();
      expect(entity.id, "session-1");
      expect(entity.cabinId, "cabin-1");
      expect(entity.status, AccessSessionStatus.paymentPending);
      expect(entity.startedAt, DateTime.parse("2026-08-01T10:00:00.000Z"));
      expect(entity.unlockedAt, isNull);
    });

    test("parses unlockedAt when present", () {
      final dto = AccessSessionDto.fromJson(<String, dynamic>{
        "id": "session-1",
        "cabinId": "cabin-1",
        "status": "unlocked",
        "startedAt": "2026-08-01T10:00:00.000Z",
        "unlockedAt": "2026-08-01T10:00:05.000Z",
      });

      expect(
        dto.toEntity().unlockedAt,
        DateTime.parse("2026-08-01T10:00:05.000Z"),
      );
    });

    test("maps every snake_case wire status to the correct enum value", () {
      const cases = <String, AccessSessionStatus>{
        "initiated": AccessSessionStatus.initiated,
        "payment_pending": AccessSessionStatus.paymentPending,
        "unlocked": AccessSessionStatus.unlocked,
        "in_use": AccessSessionStatus.inUse,
        "completed": AccessSessionStatus.completed,
        "cancelled": AccessSessionStatus.cancelled,
      };

      for (final entry in cases.entries) {
        final dto = AccessSessionDto.fromJson(<String, dynamic>{
          "id": "s",
          "cabinId": "c",
          "status": entry.key,
          "startedAt": "2026-08-01T10:00:00.000Z",
          "unlockedAt": null,
        });
        expect(dto.toEntity().status, entry.value, reason: entry.key);
      }
    });
  });
}
