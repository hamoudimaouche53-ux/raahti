import "../../domain/entities/payment_method.dart";
import "../../domain/entities/payment_method_type.dart";
import "../../domain/repositories/payment_method_repository.dart";
import "../datasources/payment_method_remote_data_source.dart";

/// [PaymentMethodRepository] implementation backed by the REST API.
class RestPaymentMethodRepository implements PaymentMethodRepository {
  const RestPaymentMethodRepository(this._remote);

  final PaymentMethodRemoteDataSource _remote;

  @override
  Future<List<PaymentMethod>> getSavedPaymentMethods() async {
    final dtos = await _remote.getSavedPaymentMethods();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  }) async {
    final dto = await _remote.addPaymentMethod(
      methodType: switch (methodType) {
        PaymentMethodType.card => "card",
        PaymentMethodType.mobileWallet => "mobile_wallet",
        PaymentMethodType.subscription => "subscription",
      },
      providerToken: providerToken,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    throw const PaymentMethodEndpointNotSpecifiedFailure();
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId) async {
    throw const PaymentMethodEndpointNotSpecifiedFailure();
  }
}
