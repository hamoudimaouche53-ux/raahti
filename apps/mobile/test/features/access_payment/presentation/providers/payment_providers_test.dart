import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_method_repository.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/payment_providers.dart";

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({this.failure});

  final PaymentRepositoryFailure? failure;

  @override
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    final PaymentRepositoryFailure? f = failure;
    if (f != null) throw f;
    return AccessSession(
      id: accessSessionId,
      cabinId: "cabin-1",
      status: AccessSessionStatus.unlocked,
      startedAt: DateTime(2026),
      unlockedAt: DateTime(2026),
    );
  }
}

class _FakePaymentMethodRepository implements PaymentMethodRepository {
  _FakePaymentMethodRepository({List<PaymentMethod>? seed})
    : _methods = seed ?? const <PaymentMethod>[];

  final List<PaymentMethod> _methods;

  @override
  Future<List<PaymentMethod>> getSavedPaymentMethods() async => _methods;

  @override
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  }) async {
    return PaymentMethod(
      id: "new-pm",
      methodType: methodType,
      providerRef: "new-ref",
      isDefault: false,
    );
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) async {}

  @override
  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId) async {
    return _methods.first;
  }
}

void main() {
  group("PaymentNotifier", () {
    test("starts as AsyncData(null)", () {
      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(_FakePaymentRepository()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(paymentNotifierProvider),
        const AsyncData<AccessSession?>(null),
      );
    });

    test("submit() transitions to AsyncData with the updated session on "
        "success", () async {
      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(_FakePaymentRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(paymentNotifierProvider.notifier)
          .submit(accessSessionId: "session-1", paymentMethodId: "pm-1");

      final state = container.read(paymentNotifierProvider);
      expect(state.value?.status, AccessSessionStatus.unlocked);
      expect(state.hasError, isFalse);
    });

    test("submit() propagates a repository failure as AsyncError", () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          paymentRepositoryProvider.overrideWithValue(
            _FakePaymentRepository(
              failure: const PaymentDeclinedFailure("declined"),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(paymentNotifierProvider.notifier)
          .submit(accessSessionId: "session-1", paymentMethodId: "pm-1");

      final state = container.read(paymentNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<PaymentDeclinedFailure>());
    });

    test("reset() clears an AsyncError back to AsyncData(null)", () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          paymentRepositoryProvider.overrideWithValue(
            _FakePaymentRepository(
              failure: const PaymentDeclinedFailure("declined"),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(paymentNotifierProvider.notifier)
          .submit(accessSessionId: "session-1", paymentMethodId: "pm-1");
      expect(container.read(paymentNotifierProvider).hasError, isTrue);

      container.read(paymentNotifierProvider.notifier).reset();

      expect(
        container.read(paymentNotifierProvider),
        const AsyncData<AccessSession?>(null),
      );
    });
  });

  group("PaymentMethodsNotifier", () {
    test("build() fetches the saved-methods list", () async {
      final container = ProviderContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWithValue(
            _FakePaymentMethodRepository(
              seed: const [
                PaymentMethod(
                  id: "pm-1",
                  methodType: PaymentMethodType.card,
                  providerRef: "Visa",
                  isDefault: true,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(paymentMethodsProvider.future);
      expect(result, hasLength(1));
      expect(result.single.id, "pm-1");
    });

    test(
      "addMethod() appends the newly added method to the current state",
      (() async {
        final container = ProviderContainer(
          overrides: [
            paymentMethodRepositoryProvider.overrideWithValue(
              _FakePaymentMethodRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(paymentMethodsProvider.future);
        final added = await container
            .read(paymentMethodsProvider.notifier)
            .addMethod(
              methodType: PaymentMethodType.card,
              providerToken: "token-1",
            );

        expect(added.id, "new-pm");
        expect(
          container.read(paymentMethodsProvider).value?.map((m) => m.id),
          contains("new-pm"),
        );
      }),
    );
  });
}
