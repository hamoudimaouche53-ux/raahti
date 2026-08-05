import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/profile/data/datasources/user_remote_data_source.dart";
import "package:rahati/features/profile/data/repositories/rest_user_repository.dart";
import "package:rahati/features/profile/domain/entities/app_user.dart";
import "package:rahati/features/profile/domain/entities/diabetic_verification_status.dart";
import "package:rahati/features/profile/domain/entities/language_preference.dart";

void main() {
  group("RestUserRepository.getCurrentUser", () {
    test("maps the remote AppUserDto into an AppUser entity", () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            "id": "u1",
            "email": "user@example.com",
            "phone": null,
            "preferredLanguage": "ar",
            "diabeticVerificationStatus": "verified",
          }),
          200,
        );
      });
      final repo = RestUserRepository(
        UserRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
      );

      final AppUser user = await repo.getCurrentUser();

      expect(
        user,
        const AppUser(
          id: "u1",
          email: "user@example.com",
          phone: null,
          preferredLanguage: LanguagePreference.ar,
          diabeticVerificationStatus: DiabeticVerificationStatus.verified,
        ),
      );
    });
  });
}
