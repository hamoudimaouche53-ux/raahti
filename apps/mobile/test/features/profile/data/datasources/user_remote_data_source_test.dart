import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/profile/data/datasources/user_remote_data_source.dart";
import "package:rahati/features/profile/domain/repositories/user_repository.dart";

Map<String, dynamic> _userJson() => <String, dynamic>{
  "id": "u1",
  "email": "user@example.com",
  "phone": null,
  "preferredLanguage": "fr",
  "diabeticVerificationStatus": "none",
};

void main() {
  group("UserRemoteDataSource.getCurrentUser", () {
    test("throws UserApiNotConfiguredFailure when baseUrl is null", () {
      final source = UserRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.getCurrentUser(),
        throwsA(isA<UserApiNotConfiguredFailure>()),
      );
    });

    test("throws UserApiNotConfiguredFailure when baseUrl is empty", () {
      final source = UserRemoteDataSource(http.Client(), baseUrl: "");
      expect(
        () => source.getCurrentUser(),
        throwsA(isA<UserApiNotConfiguredFailure>()),
      );
    });

    test(
      "requests GET {baseUrl}/v1/users/me and parses an AppUserDto",
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode(_userJson()), 200);
        });
        final source = UserRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        final dto = await source.getCurrentUser();

        expect(capturedUri, Uri.parse("https://api.raahti.dz/v1/users/me"));
        expect(dto.id, "u1");
        expect(dto.email, "user@example.com");
        expect(dto.phone, isNull);
        expect(dto.preferredLanguage, "fr");
        expect(dto.diabeticVerificationStatus, "none");
      },
    );

    test("throws UserRequestFailure on a non-200 response", () async {
      final client = MockClient((request) async => http.Response("", 401));
      final source = UserRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(() => source.getCurrentUser(), throwsA(isA<UserRequestFailure>()));
    });

    test(
      "throws UserRequestFailure when the network call itself fails",
      () async {
        final client = MockClient(
          (request) async => throw Exception("offline"),
        );
        final source = UserRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        expect(
          () => source.getCurrentUser(),
          throwsA(isA<UserRequestFailure>()),
        );
      },
    );
  });
}
