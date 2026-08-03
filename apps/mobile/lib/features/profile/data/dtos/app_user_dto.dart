import "../../domain/entities/app_user.dart";
import "../../domain/entities/diabetic_verification_status.dart";
import "../../domain/entities/language_preference.dart";

/// JSON mapping for the `User` schema in docs/api/openapi.yaml.
class AppUserDto {
  const AppUserDto({
    required this.id,
    required this.email,
    required this.phone,
    required this.preferredLanguage,
    required this.diabeticVerificationStatus,
  });

  factory AppUserDto.fromJson(Map<String, dynamic> json) {
    return AppUserDto(
      id: json["id"] as String,
      email: json["email"] as String?,
      phone: json["phone"] as String?,
      preferredLanguage: json["preferredLanguage"] as String,
      diabeticVerificationStatus: json["diabeticVerificationStatus"] as String,
    );
  }

  final String id;
  final String? email;
  final String? phone;
  final String preferredLanguage;
  final String diabeticVerificationStatus;

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      phone: phone,
      preferredLanguage: LanguagePreference.fromWireValue(preferredLanguage),
      diabeticVerificationStatus: DiabeticVerificationStatus.fromWireValue(
        diabeticVerificationStatus,
      ),
    );
  }
}
