import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";

void main() {
  group("LocalizedText.forLanguageCode", () {
    const text = LocalizedText(
      fr: "Station Didouche",
      ar: "محطة ديدوش",
      en: "Didouche Station",
    );

    test("returns French for 'fr'", () {
      expect(text.forLanguageCode("fr"), "Station Didouche");
    });

    test("returns Arabic for 'ar'", () {
      expect(text.forLanguageCode("ar"), "محطة ديدوش");
    });

    test("returns English for 'en'", () {
      expect(text.forLanguageCode("en"), "Didouche Station");
    });

    test("falls back to French for an unrecognized code", () {
      expect(text.forLanguageCode("de"), "Station Didouche");
    });
  });
}
