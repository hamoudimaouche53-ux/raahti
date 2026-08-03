import "payment_method_type.dart";

/// A user's saved, tokenized payment method — `PaymentMethod` in
/// docs/api/openapi.yaml, `PAYMENT_METHOD` in docs/erd/erd.md §3.8.
///
/// [providerRef] is an opaque, provider-issued token (ADR-0014) — never a
/// raw card number, expiry, or CVV. This class only ever displays it
/// (e.g. "Visa se terminant par 4242", SCR-015); it never sends it to a
/// payment SDK directly — that happens behind [PaymentGateway].
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.methodType,
    required this.providerRef,
    required this.isDefault,
  });

  final String id;
  final PaymentMethodType methodType;
  final String providerRef;
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is PaymentMethod &&
      other.id == id &&
      other.methodType == methodType &&
      other.providerRef == providerRef &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, methodType, providerRef, isDefault);
}
