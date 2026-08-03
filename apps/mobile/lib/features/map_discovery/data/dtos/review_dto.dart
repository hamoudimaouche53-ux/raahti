import "../../domain/entities/review.dart";

/// JSON mapping for the `Review` schema in docs/api/openapi.yaml.
class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      id: json["id"] as String,
      rating: json["rating"] as int,
      comment: json["comment"] as String?,
      createdAt: DateTime.parse(json["createdAt"] as String),
    );
  }

  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review toEntity() {
    return Review(
      id: id,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }
}
