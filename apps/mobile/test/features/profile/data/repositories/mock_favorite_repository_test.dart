import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/profile/data/repositories/mock_favorite_repository.dart";

void main() {
  group("MockFavoriteRepository", () {
    test(
      "addFavorite is reflected in a subsequent getFavorites call",
      () async {
        final repo = MockFavoriteRepository();
        final int before = (await repo.getFavorites(languageCode: "fr")).length;
        await repo.addFavorite(
          placeKind: PlaceKind.station,
          placeId: "s3",
          notifyOnAvailable: true,
          languageCode: "fr",
        );
        final after = await repo.getFavorites(languageCode: "fr");
        expect(after.length, before + 1);
      },
    );

    test(
      "removeFavorite removes it from a subsequent getFavorites call",
      () async {
        final repo = MockFavoriteRepository();
        final first = (await repo.getFavorites(languageCode: "fr")).first;
        await repo.removeFavorite(first.id);
        final after = await repo.getFavorites(languageCode: "fr");
        expect(after.any((f) => f.id == first.id), isFalse);
      },
    );

    test("setNotifyOnAvailable toggles and persists the flag", () async {
      final repo = MockFavoriteRepository();
      final first = (await repo.getFavorites(languageCode: "fr")).first;
      final updated = await repo.setNotifyOnAvailable(
        favoriteId: first.id,
        notifyOnAvailable: !first.notifyOnAvailable,
      );
      expect(updated.notifyOnAvailable, !first.notifyOnAvailable);
      final after = await repo.getFavorites(languageCode: "fr");
      final refetched = after.firstWhere((f) => f.id == first.id);
      expect(refetched.notifyOnAvailable, !first.notifyOnAvailable);
    });
  });
}
