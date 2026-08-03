import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/profile/domain/entities/language_preference.dart";

void main() {
  group("LanguagePreference.fromWireValue", () {
    test("maps fr/ar/en", () {
      expect(LanguagePreference.fromWireValue("fr"), LanguagePreference.fr);
      expect(LanguagePreference.fromWireValue("ar"), LanguagePreference.ar);
      expect(LanguagePreference.fromWireValue("en"), LanguagePreference.en);
    });

    test("falls back to fr for an unrecognized value", () {
      expect(
        LanguagePreference.fromWireValue("de"),
        LanguagePreference.fr,
      );
    });
  });
}
