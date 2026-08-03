import "../../domain/entities/payment_method.dart";
import "../../domain/entities/payment_method_type.dart";

/// JSON mapping for the `PaymentMethod` schema in docs/api/openapi.yaml.
class PaymentMethodDto {
  const PaymentMethodDto({
    required this.id,
    required this.methodType,
    required this.providerRef,
    required this.isDefault,
  });

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDto(
      id: json["id"] as String,
      methodType: json["methodType"] as String,
      providerRef: json["providerRef"] as String,
      isDefault: json["isDefault"] as bool,
    );
  }

  final String id;

  /// Wire value is `snake_case` (`mobile_wallet`), not the Dart enum's
  /// `camelCase` name — mapped explicitly below, same discipline as
  /// `AccessSessionDto.status`.
  final String methodType;
  final String providerRef;
  final bool isDefault;

  PaymentMethod toEntity() {
    return PaymentMethod(
      id: id,
      methodType: switch (methodType) {
        "card" => PaymentMethodType.card,
        "mobile_wallet" => PaymentMethodType.mobileWallet,
        "subscription" => PaymentMethodType.subscription,
        _ => PaymentMethodType.card,
      },
      providerRef: providerRef,
      isDefault: isDefault,
    );
  }
}
