/// A rider's review of a place — `Review` in docs/api/openapi.yaml,
/// `REVIEW` in docs/erd/erd.md §3.15 (SCR-007/SCR-023, US-05.2).
///
/// Lives in `map_discovery`, not `profile` — `POST
/// /places/{placeType}/{placeId}/reviews` is tagged `Places` in the API
/// contract, and a review is fundamentally about a place (submitted from
/// its detail sheet, SCR-007). `profile` imports this type for SCR-023
/// ("My Reviews"), the same one-directional dependency this codebase
/// already established for `access_payment` (`profile` sits above both
/// `map_discovery` and `access_payment` in the dependency graph, never
/// the reverse).
class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;

  /// 1–5, per `ReviewCreateRequest`'s documented `minimum`/`maximum`.
  final int rating;
  final String? comment;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Review &&
      other.id == id &&
      other.rating == rating &&
      other.comment == comment &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, rating, comment, createdAt);
}
