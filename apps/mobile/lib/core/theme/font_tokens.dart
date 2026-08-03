/// Bundled type family names, matching the `family:` keys declared in
/// `pubspec.yaml`'s `flutter.fonts` section and documented in
/// `assets/fonts/README.md`.
///
/// Source of truth: docs/design/foundations.md §2.2. `latin` covers French
/// and English (both Latin script, ADR-0017); `arabicDisplay`/`arabicBody`
/// implement the Arabic display/body typeface pairing.
abstract final class RahatiFonts {
  static const String latin = "Roboto";
  static const String arabicDisplay = "Noto Kufi Arabic";
  static const String arabicBody = "Noto Naskh Arabic";
}
