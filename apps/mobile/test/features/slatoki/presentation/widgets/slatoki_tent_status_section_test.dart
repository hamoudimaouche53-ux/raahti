import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/slatoki_tent.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_tent_status_card.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_tent_status_section.dart";
import "package:rahati/l10n/app_localizations.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Place _stationPlace(String id) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: _center,
  pinColor: PinColor.amber,
  distanceMeters: 90,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: const <String>[],
);

StationDetail _stationDetail(String id, {SlatokiTent? slatokiTent}) =>
    StationDetail(
      summary: _stationPlace(id),
      configuration: StationConfiguration.fixed,
      status: StationOperationalStatus.active,
      cabins: const <Cabin>[],
      slatokiTent: slatokiTent,
    );

Widget _wrap(String placeId, {required dynamic override}) {
  return ProviderScope(
    overrides: [override],
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SlatokiTentStatusSection(
          placeId: placeId,
          placeName: "Tente RAHETI Didouche",
        ),
      ),
    ),
  );
}

void main() {
  testWidgets("loading: shows the place name and a loading label", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        "s1",
        override: stationDetailProvider(
          "s1",
        ).overrideWith((ref) => Completer<StationDetail>().future),
      ),
    );
    await tester.pump();

    expect(find.text("Tente RAHETI Didouche"), findsOneWidget);
    expect(find.text("Chargement des détails…"), findsOneWidget);
  });

  testWidgets("error: shows an inline error line", (WidgetTester tester) async {
    // Retry disabled: Riverpod 3.x's default FutureProvider retry
    // (exponential backoff, up to 10 attempts — see
    // slatoki_screen_test.dart's "not configured" test for the full
    // rationale) would otherwise keep this in `AsyncLoading` for several
    // real seconds before surfacing as `AsyncError`.
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        stationDetailProvider(
          "s1",
        ).overrideWith((ref) => Future<StationDetail>.error("boom")),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: RahatiTheme.light,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SlatokiTentStatusSection(
              placeId: "s1",
              placeName: "Tente RAHETI Didouche",
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text("Impossible de charger les détails de ce lieu."),
      findsOneWidget,
    );
  });

  testWidgets(
    "data with a SlatokiTent: renders the full SlatokiTentStatusCard",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          "s1",
          override: stationDetailProvider("s1").overrideWith(
            (ref) async => _stationDetail(
              "s1",
              slatokiTent: const SlatokiTent(
                deploymentStatus: DeploymentStatus.deployed,
                matCapacity: 4,
                hasLighting: true,
                hasPrivacyCurtain: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SlatokiTentStatusCard), findsOneWidget);
      expect(find.text("Déployée"), findsOneWidget);
    },
  );

  testWidgets(
    "data with no SlatokiTent (defensive fallback): shows just the name, "
    "no crash",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          "s1",
          override: stationDetailProvider(
            "s1",
          ).overrideWith((ref) async => _stationDetail("s1")),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("Tente RAHETI Didouche"), findsOneWidget);
      expect(find.byType(SlatokiTentStatusCard), findsNothing);
    },
  );
}
