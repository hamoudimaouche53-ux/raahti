import "money.dart";

/// Mirrors `Cabin.type` in docs/api/openapi.yaml (`H|F|Slatoki|PMR` in the
/// ERD, §3.5) — H/F kept as `men`/`women` in Dart for readability, the wire
/// value is still the single-letter code (see `CabinDto`).
enum CabinType { men, women, slatoki, pmr }

/// Real-time occupancy, IoT-sourced for RAHETI stations (FR-PLC-02).
enum CabinOccupancyStatus { free, occupied, outOfService }

/// A single cabin within a [StationDetail] — FR-PLC-02 (status) and
/// FR-PLC-03 (tariff). Third-party places have no cabins (a single
/// declarative status instead — see `ThirdPartyPlaceDetail`).
class Cabin {
  const Cabin({
    required this.id,
    required this.code,
    required this.type,
    required this.occupancyStatus,
    required this.isPaid,
    required this.price,
  });

  final String id;
  final String code;
  final CabinType type;
  final CabinOccupancyStatus occupancyStatus;
  final bool isPaid;

  /// `null` when [isPaid] is `false`.
  final Money? price;
}
