import "../../domain/entities/cabin.dart";
import "money_dto.dart";

/// JSON mapping for the `Cabin` schema in docs/api/openapi.yaml.
class CabinDto {
  const CabinDto({
    required this.id,
    required this.code,
    required this.type,
    required this.occupancyStatus,
    required this.isPaid,
    required this.price,
  });

  factory CabinDto.fromJson(Map<String, dynamic> json) {
    return CabinDto(
      id: json["id"] as String,
      code: json["code"] as String,
      type: json["type"] as String,
      occupancyStatus: json["occupancyStatus"] as String,
      isPaid: json["isPaid"] as bool,
      price: json["price"] == null
          ? null
          : MoneyDto.fromJson(json["price"] as Map<String, dynamic>),
    );
  }

  final String id;
  final String code;

  /// Wire value: `H`/`F`/`Slatoki`/`PMR` (ERD §3.5).
  final String type;
  final String occupancyStatus;
  final bool isPaid;
  final MoneyDto? price;

  Cabin toEntity() {
    return Cabin(
      id: id,
      code: code,
      type: switch (type) {
        "H" => CabinType.men,
        "F" => CabinType.women,
        "Slatoki" => CabinType.slatoki,
        "PMR" => CabinType.pmr,
        _ => CabinType.men,
      },
      occupancyStatus: CabinOccupancyStatus.values.firstWhere(
        (v) => v.name == occupancyStatus,
        orElse: () => CabinOccupancyStatus.outOfService,
      ),
      isPaid: isPaid,
      price: price?.toEntity(),
    );
  }
}
