import "place.dart";

/// Mirrors `ThirdPartyPlaceDetail.placeType` in docs/api/openapi.yaml.
enum ThirdPartyPlaceType { mosque, business, gasStation, other }

/// A single declarative status — third-party places have no cabins/IoT, so
/// there is one status for the whole place, not a per-cabin list
/// (RAH-DOC-005 §2.2's explicit RAHETI-vs-declared distinction).
enum DeclaredStatus { open, closed, unknown }

/// Who declared [DeclaredStatus] — shown so the UI can visually distinguish
/// this from IoT-verified [StationDetail] status (SCR-006).
enum StatusSource { community, ownerDeclared }

/// The full third-party place detail (US-01.2.2, partial — declarative
/// status only, no cabins/tariff since third-party places have neither),
/// fetched lazily from `GET /third-party-places/{id}`.
class ThirdPartyPlaceDetail {
  const ThirdPartyPlaceDetail({
    required this.summary,
    required this.placeType,
    required this.declaredStatus,
    required this.statusSource,
  });

  final Place summary;
  final ThirdPartyPlaceType placeType;
  final DeclaredStatus declaredStatus;
  final StatusSource statusSource;
}
