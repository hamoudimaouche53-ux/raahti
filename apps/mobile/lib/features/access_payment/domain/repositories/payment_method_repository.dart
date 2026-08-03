import "../entities/payment_method.dart";
import "../entities/payment_method_type.dart";

sealed class PaymentMethodRepositoryFailure implements Exception {
  const PaymentMethodRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentMethodApiNotConfiguredFailure
    extends PaymentMethodRepositoryFailure {
  const PaymentMethodApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

class PaymentMethodRequestFailure extends PaymentMethodRepositoryFailure {
  const PaymentMethodRequestFailure(super.message);
}

/// **API contract gap** (added Feature 19, EPIC-05) — docs/api/openapi.yaml
/// only specifies `GET`/`POST /users/me/payment-methods`; there is no
/// `DELETE`/`PATCH` for an individual saved method.
/// [RestPaymentMethodRepository.deletePaymentMethod]/`setDefault` both
/// always throw this — distinct from [PaymentMethodApiNotConfiguredFailure]
/// ("would work once deployed"), this means "wouldn't work even against a
/// deployed backend." Flagged in the implementation log's API Contract
/// Gaps section; natural shapes would be
/// `DELETE /users/me/payment-methods/{id}` and
/// `PATCH /users/me/payment-methods/{id}`.
class PaymentMethodEndpointNotSpecifiedFailure
    extends PaymentMethodRepositoryFailure {
  const PaymentMethodEndpointNotSpecifiedFailure()
    : super(
        "No endpoint is specified in docs/api/openapi.yaml for removing "
        "or setting the default on an existing payment method.",
      );
}

/// Repository port for `GET`/`POST /users/me/payment-methods`, plus
/// deletion/default-selection (SCR-022, US-05.2, added Feature 19). These
/// endpoints are tagged `Identity` rather than `AccessPayment` in
/// docs/api/openapi.yaml — this port lives in `access_payment` rather
/// than `profile` because `PaymentMethod` is the same entity SCR-015's
/// payment-selection sheet already depends on (Feature 15); `profile`
/// imports this port and entity for SCR-022, the same one-directional
/// dependency already established for `map_discovery` → `access_payment`.
abstract interface class PaymentMethodRepository {
  Future<List<PaymentMethod>> getSavedPaymentMethods();

  /// [providerToken] is a client-obtained token from the (currently mock,
  /// per ADR-0014/ADR-0026) tokenization flow —
  /// `PaymentGateway.tokenizePaymentMethod`'s result — never a raw
  /// card/wallet value.
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  });

  /// Always throws [PaymentMethodEndpointNotSpecifiedFailure] in
  /// [RestPaymentMethodRepository] — see that failure's own doc comment.
  Future<void> deletePaymentMethod(String paymentMethodId);

  /// Always throws [PaymentMethodEndpointNotSpecifiedFailure] in
  /// [RestPaymentMethodRepository] — see that failure's own doc comment.
  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId);
}
