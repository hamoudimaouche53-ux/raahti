import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";
import "package:rahati/features/access_payment/domain/repositories/access_session_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/access_session_providers.dart";

class _FakeAccessSessionRepository implements AccessSessionRepository {
  _FakeAccessSessionRepository({this.failure});

  final AccessSessionRepositoryFailure? failure;

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    final AccessSessionRepositoryFailure? f = failure;
    if (f != null) throw f;
    return AccessSession(
      id: "session-1",
      cabinId: "cabin-1",
      status: AccessSessionStatus.initiated,
      startedAt: DateTime(2026),
      unlockedAt: null,
    );
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) {
    throw UnimplementedError();
  }
}

void main() {
  group("QrScanNotifier", () {
    test("starts as AsyncData(null)", () {
      final container = ProviderContainer(
        overrides: [
          accessSessionRepositoryProvider.overrideWithValue(
            _FakeAccessSessionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(qrScanNotifierProvider),
        const AsyncData<AccessSession?>(null),
      );
    });

    test(
      "submit() transitions to AsyncData with the created session on success",
      () async {
        final container = ProviderContainer(
          overrides: [
            accessSessionRepositoryProvider.overrideWithValue(
              _FakeAccessSessionRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(qrScanNotifierProvider.notifier)
            .submit("RAHETI-STATION-1-CABIN-2");

        final AsyncValue<AccessSession?> state = container.read(
          qrScanNotifierProvider,
        );
        expect(state.value?.id, "session-1");
        expect(state.hasError, isFalse);
      },
    );

    test("submit() with an invalid payload transitions to AsyncError "
        "(InvalidQrCodeFailure), without calling the repository", () async {
      // Retry disabled — same rationale as every other error-state test in
      // this log (Riverpod 3.x's default retry would otherwise keep this
      // in AsyncLoading for real seconds before surfacing as AsyncError).
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          accessSessionRepositoryProvider.overrideWithValue(
            _FakeAccessSessionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(qrScanNotifierProvider.notifier).submit("");

      final AsyncValue<AccessSession?> state = container.read(
        qrScanNotifierProvider,
      );
      expect(state.hasError, isTrue);
      expect(state.error, isA<InvalidQrCodeFailure>());
    });

    test("submit() propagates a repository failure as AsyncError", () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          accessSessionRepositoryProvider.overrideWithValue(
            _FakeAccessSessionRepository(
              failure: const CabinUnavailableFailure(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(qrScanNotifierProvider.notifier)
          .submit("RAHETI-STATION-1-CABIN-2");

      final AsyncValue<AccessSession?> state = container.read(
        qrScanNotifierProvider,
      );
      expect(state.hasError, isTrue);
      expect(state.error, isA<CabinUnavailableFailure>());
    });

    test("reset() clears an AsyncError back to AsyncData(null)", () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          accessSessionRepositoryProvider.overrideWithValue(
            _FakeAccessSessionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(qrScanNotifierProvider.notifier).submit("");
      expect(container.read(qrScanNotifierProvider).hasError, isTrue);

      container.read(qrScanNotifierProvider.notifier).reset();

      expect(
        container.read(qrScanNotifierProvider),
        const AsyncData<AccessSession?>(null),
      );
    });
  });
}
