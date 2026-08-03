import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";
import "package:rahati/features/access_payment/domain/repositories/access_session_repository.dart";
import "package:rahati/features/access_payment/domain/usecases/initiate_access_session.dart";

class _FakeAccessSessionRepository implements AccessSessionRepository {
  _FakeAccessSessionRepository({this.failure});

  final AccessSessionRepositoryFailure? failure;
  int callCount = 0;
  QrCode? lastQrCode;
  String? lastIdempotencyKey;

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    callCount++;
    lastQrCode = qrCodeScanned;
    lastIdempotencyKey = idempotencyKey;
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
  group("InitiateAccessSession", () {
    test("rejects an invalid payload before touching the repository", () async {
      final repository = _FakeAccessSessionRepository();
      final useCase = InitiateAccessSession(repository);

      await expectLater(
        () => useCase(rawValue: ""),
        throwsA(isA<InvalidQrCodeFailure>()),
      );
      expect(repository.callCount, 0);
    });

    test(
      "attaches a freshly generated Idempotency-Key on a valid payload",
      () async {
        final repository = _FakeAccessSessionRepository();
        final useCase = InitiateAccessSession(repository);

        final AccessSession result = await useCase(
          rawValue: "RAHETI-STATION-1-CABIN-2",
        );

        expect(result.id, "session-1");
        expect(repository.callCount, 1);
        expect(repository.lastQrCode?.value, "RAHETI-STATION-1-CABIN-2");
        expect(repository.lastIdempotencyKey, isNotEmpty);
      },
    );

    test("generates a different Idempotency-Key per call", () async {
      final repository = _FakeAccessSessionRepository();
      final useCase = InitiateAccessSession(repository);

      await useCase(rawValue: "code-1");
      final String? firstKey = repository.lastIdempotencyKey;
      await useCase(rawValue: "code-1");
      final String? secondKey = repository.lastIdempotencyKey;

      expect(firstKey, isNot(equals(secondKey)));
    });

    test(
      "propagates a repository failure (e.g. CabinUnavailableFailure)",
      () async {
        final repository = _FakeAccessSessionRepository(
          failure: const CabinUnavailableFailure(),
        );
        final useCase = InitiateAccessSession(repository);

        await expectLater(
          () => useCase(rawValue: "RAHETI-STATION-1-CABIN-2"),
          throwsA(isA<CabinUnavailableFailure>()),
        );
      },
    );
  });
}
