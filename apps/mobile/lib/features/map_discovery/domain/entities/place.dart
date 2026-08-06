import "coordinates.dart";

/// Which physical/data source a place comes from — RAHETI-operated
/// (IoT-verified status) vs. community-declared. Mirrors
/// `PlaceSummary.placeKind` in docs/api/openapi.yaml and the distinction
/// RAH-DOC-005 §2.2 requires to stay visually explicit (never conflated).
enum PlaceKind { station, thirdPartyPlace }

/// The RAH-DOC-002 §4.2 functional pin color for a place, preserved as an
/// M3 color-role extension per ADR-0011 — resolved to an actual [Color] only
/// in the Presentation layer (`RahatiFunctionalColors`), never here.
enum PinColor { green, blue, amber, magenta }

/// A single trilingual string, per ADR-0017 (FR/AR/EN). Mirrors
/// `LocalizedText` in docs/api/openapi.yaml.
class LocalizedText {
  const LocalizedText({required this.fr, required this.ar, required this.en});

  final String fr;
  final String ar;
  final String en;

  /// Resolves the display string for a given language code, falling back to
  /// French (RAH-DOC-005's primary authored language) for an unrecognized
  /// code rather than throwing — a display-layer concern should never crash
  /// on an unexpected but harmless input.
  String forLanguageCode(String languageCode) {
    switch (languageCode) {
      case "ar":
        return ar;
      case "en":
        return en;
      default:
        return fr;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LocalizedText &&
      other.fr == fr &&
      other.ar == ar &&
      other.en == en;

  @override
  int get hashCode => Object.hash(fr, ar, en);
}

/// The unified map/list read model — a RAHETI station or a third-party
/// place — exactly as returned by `GET /places/nearby`
/// (docs/api/openapi.yaml, docs/architecture/system-architecture.md §7).
/// Implements FR-MAP-01/02, US-01.1.1.
class Place {
  const Place({
    required this.id,
    required this.placeKind,
    required this.name,
    required this.position,
    required this.pinColor,
    required this.distanceMeters,
    required this.averageRating,
    required this.reviewCount,
    required this.isFree,
    required this.tags,
  });

  final String id;
  final PlaceKind placeKind;
  final LocalizedText name;
  final Coordinates position;
  final PinColor pinColor;
  final double distanceMeters;

  /// `null` when the place has no reviews yet.
  final double? averageRating;
  final int reviewCount;
  final bool isFree;
  final List<String> tags;
}
