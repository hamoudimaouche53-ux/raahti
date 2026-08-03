import "../../domain/entities/money.dart";

/// JSON mapping for the `Money` schema in docs/api/openapi.yaml.
class MoneyDto {
  const MoneyDto({required this.amount, required this.currency});

  factory MoneyDto.fromJson(Map<String, dynamic> json) {
    return MoneyDto(
      amount: json["amount"] as String,
      currency: json["currency"] as String,
    );
  }

  final String amount;
  final String currency;

  Money toEntity() => Money(amount: amount, currency: currency);
}
