import "place.dart" show LocalizedText, PlaceKind;

/// A rider's review of a place — `Review`/`MyReviewListItem` in
/// docs/api/openapi.yaml, `REVIEW` in docs/erd/erd.md §3.15 (SCR-007/
/// SCR-023, US-05.2).
///
/// Lives in `map_discovery`, not `profile` — `POST
/// /places/{placeType}/{placeId}/reviews` is tagged `Places` in the API
/// contract, and a review is fundamentally about a place (submitted from
/// its detail sheet, SCR-007). `profile` imports this type for SCR-023
/// ("My Reviews"), the same one-directional dependency this codebase
/// already established for `access_payment` (`profile` sits above both
/// `map_discovery` and `access_payment` in the dependency graph, never
/// the reverse).
///
/// [placeKind]/[placeId]/[placeName] mirror `GET /users/me/reviews`'s
/// `MyReviewListItem` schema — reusing [PlaceKind]/[LocalizedText] (the
/// same types [Place]/[Favorite] already use), not a new bilingual type.
/// The wire `Review` schema (the `POST`/`PATCH .../reviews` response) has
/// no such fields — `RestReviewRepository` denormalizes them onto this
/// entity at the DTO→entity boundary, same "narrower aggregate, enriched
/// for its screen" pattern `Favorite.placeName`/`Visit.placeName` already
/// established.
class Review {
  const Review({
    required this.id,
    required this.placeKind,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final PlaceKind placeKind;
  final String placeId;
  final LocalizedText placeName;

  /// 1–5, per `ReviewCreateRequest`'s documented `minimum`/`maximum`.
  final int rating;
  final String? comment;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Review &&
      other.id == id &&
      other.placeKind == placeKind &&
      other.placeId == placeId &&
      other.placeName == placeName &&
      other.rating == rating &&
      other.comment == comment &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    placeKind,
    placeId,
    placeName,
    rating,
    comment,
    createdAt,
  );
}
