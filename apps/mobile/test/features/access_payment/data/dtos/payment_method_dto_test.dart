import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/data/dtos/payment_method_dto.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";

void main() {
  group("PaymentMethodDto", () {
    test("parses a full JSON payload", () {
      final dto = PaymentMethodDto.fromJson(<String, dynamic>{
        "id": "pm-1",
        "methodType": "mobile_wallet",
        "providerRef": "Wallet Mobile",
        "isDefault": false,
      });

      final entity = dto.toEntity();
      expect(entity.id, "pm-1");
      expect(entity.methodType, PaymentMethodType.mobileWallet);
      expect(entity.providerRef, "Wallet Mobile");
      expect(entity.isDefault, isFalse);
    });

    test("maps every wire methodType to the correct enum value", () {
      for (final entry in <String, PaymentMethodType>{
        "card": PaymentMethodType.card,
        "mobile_wallet": PaymentMethodType.mobileWallet,
        "subscription": PaymentMethodType.subscription,
      }.entries) {
        final dto = PaymentMethodDto.fromJson(<String, dynamic>{
          "id": "pm-1",
          "methodType": entry.key,
          "providerRef": "ref",
          "isDefault": false,
        });
        expect(dto.toEntity().methodType, entry.value);
      }
    });
  });
}
