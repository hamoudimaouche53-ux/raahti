import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/adapters/mock_payment_gateway_adapter.dart";
import "../../data/datasources/payment_method_remote_data_source.dart";
import "../../data/datasources/payment_remote_data_source.dart";
import "../../data/repositories/mock_payment_method_repository.dart";
import "../../data/repositories/mock_payment_repository.dart";
import "../../data/repositories/rest_payment_method_repository.dart";
import "../../data/repositories/rest_payment_repository.dart";
import "../../domain/entities/access_session.dart";
import "../../domain/entities/payment_method.dart";
import "../../domain/entities/payment_method_type.dart";
import "../../domain/gateways/payment_gateway.dart";
import "../../domain/repositories/payment_method_repository.dart";
import "../../domain/repositories/payment_repository.dart";
import "../../domain/usecases/request_payment.dart";

/// DI wiring, mirroring `access_session_providers.dart`'s composition-root
/// pattern.
final Provider<PaymentRemoteDataSource> paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>(
      (ref) => PaymentRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

final Provider<PaymentMethodRemoteDataSource>
paymentMethodRemoteDataSourceProvider = Provider<PaymentMethodRemoteDataSource>(
  (ref) => PaymentMethodRemoteDataSource(
    ref.watch(httpClientProvider),
    baseUrl: AppEnv.apiBaseUrl,
  ),
);

/// ADR-0014's mandated mock adapter — a single shared instance for the
/// app's lifetime (not `const`-per-call), same discipline as every other
/// singleton-scoped provider here.
final Provider<PaymentGateway> paymentGatewayProvider =
    Provider<PaymentGateway>((ref) => MockPaymentGatewayAdapter());

/// The swap point between real and mock payment data (US-04.3 — see
/// `MockPaymentRepository`'s doc comment and `AppEnv.useMockPayment`,
/// `false` by default).
final Provider<PaymentRepository> paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) {
      if (AppEnv.useMockPayment) {
        return MockPaymentRepository(ref.watch(paymentGatewayProvider));
      }
      return RestPaymentRepository(ref.watch(paymentRemoteDataSourceProvider));
    });

/// Same swap point for saved payment methods. `MockPaymentMethodRepository`
/// is stateful (in-memory) — `ref.watch` (not `.read`) on a `Provider`
/// still only constructs it once per `ProviderContainer`, so the same
/// instance (and its in-memory additions) persists for the app session.
final Provider<PaymentMethodRepository> paymentMethodRepositoryProvider =
    Provider<PaymentMethodRepository>((ref) {
      if (AppEnv.useMockPayment) {
        return MockPaymentMethodRepository();
      }
      return RestPaymentMethodRepository(
        ref.watch(paymentMethodRemoteDataSourceProvider),
      );
    });

final Provider<RequestPayment> requestPaymentProvider =
    Provider<RequestPayment>(
      (ref) => RequestPayment(ref.watch(paymentRepositoryProvider)),
    );

/// One-shot submission state for SCR-016 — same shape as
/// `QrScanNotifier` (`access_session_providers.dart`): `null` before any
/// attempt, [AsyncLoading] in flight, [AsyncError] on
/// [PaymentDeclinedFailure]/[UnlockFailedRefundedFailure]/any other
/// [PaymentRepositoryFailure] (checked via `error is`, not a message
/// string), [AsyncData] with the updated [AccessSession] on success.
class PaymentNotifier extends AsyncNotifier<AccessSession?> {
  @override
  AccessSession? build() => null;

  Future<void> submit({
    required String accessSessionId,
    required String paymentMethodId,
  }) async {
    state = const AsyncLoading<AccessSession?>();
    final RequestPayment useCase = ref.read(requestPaymentProvider);
    state = await AsyncValue.guard(
      () => useCase(
        accessSessionId: accessSessionId,
        paymentMethodId: paymentMethodId,
      ),
    );
  }

  /// Clears a terminal ([AsyncError]) state so a retry (re-opening
  /// SCR-015 with a different method) starts from a clean slate.
  void reset() => state = const AsyncData<AccessSession?>(null);
}

final AsyncNotifierProvider<PaymentNotifier, AccessSession?>
paymentNotifierProvider =
    AsyncNotifierProvider<PaymentNotifier, AccessSession?>(PaymentNotifier.new);

/// SCR-015's saved-methods list. `AsyncNotifier` (not a plain
/// `FutureProvider`) because [addPaymentMethod] needs to mutate this
/// state in place (appending the newly added method) rather than forcing
/// callers to `ref.invalidate` and re-fetch.
class PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethod>> {
  @override
  Future<List<PaymentMethod>> build() {
    return ref.read(paymentMethodRepositoryProvider).getSavedPaymentMethods();
  }

  /// Appends the newly added method to the current list — SCR-015's
  /// "Ajouter un moyen de paiement" flow expects the new method to appear
  /// (and be selectable) immediately, without a full list re-fetch.
  Future<PaymentMethod> addMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  }) async {
    final PaymentMethod added = await ref
        .read(paymentMethodRepositoryProvider)
        .addPaymentMethod(methodType: methodType, providerToken: providerToken);
    final List<PaymentMethod> current = state.value ?? const <PaymentMethod>[];
    state = AsyncData<List<PaymentMethod>>([...current, added]);
    return added;
  }
}

final AsyncNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>
paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>(
      PaymentMethodsNotifier.new,
    );
