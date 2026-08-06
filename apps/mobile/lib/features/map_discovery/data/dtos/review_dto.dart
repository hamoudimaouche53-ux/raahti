import "../../domain/entities/place.dart" show LocalizedText, PlaceKind;
import "../../domain/entities/review.dart";

/// JSON mapping for the `Review` schema in docs/api/openapi.yaml — the
/// `POST .../reviews` / `PATCH .../reviews/{reviewId}` response shape.
/// That schema carries no place fields (they're already-known path
/// params) — [toEntity] takes [placeKind]/[placeId]/[placeName] as
/// resolved inputs, mirroring `FavoriteDto.toEntity`'s own
/// denormalization pattern.
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

  Review toEntity({
    required PlaceKind placeKind,
    required String placeId,
    required LocalizedText placeName,
  }) {
    return Review(
      id: id,
      placeKind: placeKind,
      placeId: placeId,
      placeName: placeName,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }
}

/// JSON mapping for the `MyReviewListItem` schema in docs/api/openapi.yaml
/// — the `GET /users/me/reviews` row shape. Unlike [ReviewDto], this one
/// carries `placeType`/`placeId`/`placeName` resolved server-side, so
/// [toEntity] needs no extra inputs.
class MyReviewListItemDto {
  const MyReviewListItemDto({
    required this.id,
    required this.placeKind,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory MyReviewListItemDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> name = json["placeName"] as Map<String, dynamic>;
    return MyReviewListItemDto(
      id: json["id"] as String,
      placeKind: json["placeType"] == "station"
          ? PlaceKind.station
          : PlaceKind.thirdPartyPlace,
      placeId: json["placeId"] as String,
      placeName: LocalizedText(
        fr: name["fr"] as String,
        ar: name["ar"] as String,
        // Same tolerate-a-missing-`en` fallback `PlaceDto` already applies.
        en: (name["en"] as String?) ?? name["fr"] as String,
      ),
      rating: json["rating"] as int,
      comment: json["comment"] as String?,
      createdAt: DateTime.parse(json["createdAt"] as String),
    );
  }

  final String id;
  final PlaceKind placeKind;
  final String placeId;
  final LocalizedText placeName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review toEntity() {
    return Review(
      id: id,
      placeKind: placeKind,
      placeId: placeId,
      placeName: placeName,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }
}
