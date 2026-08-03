import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/data/dtos/transaction_dto.dart";
import "package:rahati/features/access_payment/domain/entities/transaction_status.dart";

Map<String, dynamic> _accessSessionJson() => <String, dynamic>{
  "id": "session-1",
  "cabinId": "cabin-1",
  "status": "unlocked",
  "startedAt": "2026-08-01T10:00:00.000Z",
  "unlockedAt": "2026-08-01T10:01:00.000Z",
};

void main() {
  group("TransactionDto", () {
    test("parses a full JSON payload, including the embedded accessSession", () {
      final dto = TransactionDto.fromJson(<String, dynamic>{
        "id": "txn-1",
        "amount": <String, dynamic>{"amount": "50", "currency": "DZD"},
        "discountApplied": null,
        "status": "captured",
        "accessSession": _accessSessionJson(),
      });

      final entity = dto.toEntity();
      expect(entity.id, "txn-1");
      expect(entity.amount.amount, "50");
      expect(entity.amount.currency, "DZD");
      expect(entity.discountApplied, isNull);
      expect(entity.status, TransactionStatus.captured);
      expect(entity.providerRef, isNull);
      expect(dto.accessSession.toEntity().id, "session-1");
    });

    test("parses a non-null discountApplied as a DiscountRate percentage", () {
      final dto = TransactionDto.fromJson(<String, dynamic>{
        "id": "txn-1",
        "amount": <String, dynamic>{"amount": "25", "currency": "DZD"},
        "discountApplied": "50",
        "status": "captured",
        "accessSession": _accessSessionJson(),
      });

      expect(dto.toEntity().discountApplied?.percentage, 50);
    });

    test("maps every wire status to the correct enum value", () {
      for (final entry in <String, TransactionStatus>{
        "pending": TransactionStatus.pending,
        "authorized": TransactionStatus.authorized,
        "captured": TransactionStatus.captured,
        "failed": TransactionStatus.failed,
        "refunded": TransactionStatus.refunded,
      }.entries) {
        final dto = TransactionDto.fromJson(<String, dynamic>{
          "id": "txn-1",
          "amount": <String, dynamic>{"amount": "50", "currency": "DZD"},
          "discountApplied": null,
          "status": entry.key,
          "accessSession": _accessSessionJson(),
        });
        expect(dto.toEntity().status, entry.value);
      }
    });
  });
}
