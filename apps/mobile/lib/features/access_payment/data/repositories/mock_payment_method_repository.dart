import "../../domain/entities/payment_method.dart";
import "../../domain/entities/payment_method_type.dart";
import "../../domain/repositories/payment_method_repository.dart";

/// **Explicitly-opt-in mock adapter** for [PaymentMethodRepository] — not
/// wired by default (see `AppEnv.useMockPayment`). Same rationale as
/// `MockPlaceDetailRepository` (ADR-0023): no backend/Identity-module
/// payment-methods endpoint exists yet, so this lets SCR-015's saved-list
/// and "Ajouter un moyen de paiement" states be built and demonstrated
/// now.
///
/// Unlike `MockPlaceDetailRepository`, this class is **not** `const` /
/// stateless — [addPaymentMethod] must make the newly added method appear
/// in a subsequent [getSavedPaymentMethods] call for the demo to be
/// coherent (SCR-015's whole point is picking a method you just added).
/// A single instance is shared for the app's lifetime via
/// `payment_providers.dart`'s DI wiring, so this in-memory list persists
/// only for one app session — never written to disk, matching
/// [PaymentMethod.providerRef]'s "never real card data" discipline (every
/// value here is fabricated).
class MockPaymentMethodRepository implements PaymentMethodRepository {
  MockPaymentMethodRepository({List<PaymentMethod>? seed})
    : _methods = seed ?? _defaultSeed();

  final List<PaymentMethod> _methods;

  static List<PaymentMethod> _defaultSeed() => [
    const PaymentMethod(
      id: "mock-pm-1",
      methodType: PaymentMethodType.card,
      providerRef: "Visa •••• 4242",
      isDefault: true,
    ),
    const PaymentMethod(
      id: "mock-pm-2",
      methodType: PaymentMethodType.mobileWallet,
      providerRef: "Wallet Mobile",
      isDefault: false,
    ),
  ];

  @override
  Future<List<PaymentMethod>> getSavedPaymentMethods() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<PaymentMethod>.unmodifiable(_methods);
  }

  @override
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final PaymentMethod added = PaymentMethod(
      id: "mock-pm-${_methods.length + 1}",
      methodType: methodType,
      // The real hosted provider flow (ADR-0014/SCR-015's own wireframe
      // note: "provider-owned, not RAHATI-designed") would return a
      // masked display identifier here — this mock fabricates one from
      // the method type only, since [providerToken] is itself a mock
      // stand-in with nothing real to derive a mask from.
      providerRef: switch (methodType) {
        PaymentMethodType.card => "Visa •••• ${1000 + _methods.length}",
        PaymentMethodType.mobileWallet => "Wallet Mobile",
        PaymentMethodType.subscription => "Abonnement",
      },
      isDefault: _methods.isEmpty,
    );
    _methods.add(added);
    return added;
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _methods.removeWhere((m) => m.id == paymentMethodId);
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    PaymentMethod? newDefault;
    for (int i = 0; i < _methods.length; i++) {
      final PaymentMethod current = _methods[i];
      final bool isTarget = current.id == paymentMethodId;
      final PaymentMethod updated = PaymentMethod(
        id: current.id,
        methodType: current.methodType,
        providerRef: current.providerRef,
        isDefault: isTarget,
      );
      _methods[i] = updated;
      if (isTarget) newDefault = updated;
    }
    if (newDefault == null) {
      throw const PaymentMethodRequestFailure(
        "No saved payment method matches the given id.",
      );
    }
    return newDefault;
  }
}
