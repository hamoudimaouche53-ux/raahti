import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/profile/data/repositories/mock_auth_repository.dart";
import "package:rahati/features/profile/domain/repositories/auth_repository.dart";

void main() {
  group("MockAuthRepository", () {
    test("starts signed out (null) by default", () async {
      final repo = MockAuthRepository();
      final String? first = await repo.watchCurrentUserId().first;
      expect(first, isNull);
    });

    test("signInWithPassword flips watchCurrentUserId to non-null", () async {
      final repo = MockAuthRepository();
      final Future<String?> next = repo
          .watchCurrentUserId()
          .skip(1)
          .first;
      await repo.signInWithPassword(email: "a@b.com", password: "x");
      expect(await next, isNotNull);
    });

    test("signUpWithPassword also flips watchCurrentUserId", () async {
      final repo = MockAuthRepository();
      final Future<String?> next = repo
          .watchCurrentUserId()
          .skip(1)
          .first;
      await repo.signUpWithPassword(email: "a@b.com", password: "x");
      expect(await next, isNotNull);
    });

    test("signOut flips watchCurrentUserId back to null", () async {
      final repo = MockAuthRepository(initialUserId: "mock-user-1");
      final Future<String?> next = repo
          .watchCurrentUserId()
          .skip(1)
          .first;
      await repo.signOut();
      expect(await next, isNull);
    });

    test("declineAuth=true throws AuthRequestFailure on sign in", () async {
      final repo = MockAuthRepository(declineAuth: true);
      expect(
        () => repo.signInWithPassword(email: "a@b.com", password: "x"),
        throwsA(isA<AuthRequestFailure>()),
      );
    });

    test("declineAuth=true throws AuthRequestFailure on sign up", () async {
      final repo = MockAuthRepository(declineAuth: true);
      expect(
        () => repo.signUpWithPassword(email: "a@b.com", password: "x"),
        throwsA(isA<AuthRequestFailure>()),
      );
    });
  });
}
