import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/emergency/domain/entities/emergency_facility_result.dart";
import "package:rahati/features/emergency/domain/repositories/emergency_repository.dart";
import "package:rahati/features/emergency/presentation/providers/emergency_providers.dart";
import "package:rahati/features/emergency/presentation/screens/emergency_result_screen.dart";
import "package:rahati/features/map_discovery/data/datasources/device_location_data_source.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/location_failure.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/l10n/app_localizations.dart";

Place _place() => const Place(
  id: "place-1",
  placeKind: PlaceKind.station,
  name: LocalizedText(
    fr: "Station Didouche",
    ar: "محطة ديدوش",
    en: "Didouche Station",
  ),
  position: Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.green,
  distanceMeters: 180,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: <String>[],
);

class _FakeDeviceLocationDataSource extends DeviceLocationDataSource {
  const _FakeDeviceLocationDataSource({this.failure});

  final LocationFailure? failure;

  @override
  Future<Coordinates> getCurrentPosition() async {
    final LocationFailure? f = failure;
    if (f != null) throw f;
    return const Coordinates(latitude: 36.75, longitude: 3.06);
  }
}

class _FakeEmergencyRepository implements EmergencyRepository {
  _FakeEmergencyRepository({this.result});

  final EmergencyFacilityResult? result;

  @override
  Future<EmergencyFacilityResult?> findNearestFacility({
    required Coordinates position,
  }) async => result;
}

Future<void> _pump(
  WidgetTester tester, {
  LocationFailure? locationFailure,
  EmergencyFacilityResult? result,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceLocationDataSourceProvider.overrideWithValue(
          _FakeDeviceLocationDataSource(failure: locationFailure),
        ),
        emergencyRepositoryProvider.overrideWithValue(
          _FakeEmergencyRepository(result: result),
        ),
      ],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: const Locale("fr"),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const EmergencyResultScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("discount-eligible: shows the facility, distance/ETA, and the "
      "discount badge", (tester) async {
    final EmergencyFacilityResult result = EmergencyFacilityResult(
      place: _place(),
      nearestCabinId: "cabin-1",
      discountEligible: true,
      etaMinutesOnFoot: 2,
    );
    await _pump(tester, result: result);

    expect(find.text("Station Didouche"), findsOneWidget);
    expect(find.text("180 m · 2 min à pied"), findsOneWidget);
    expect(find.text("Réduction 50% disponible"), findsOneWidget);
    expect(find.text("Aller au lieu le plus proche"), findsOneWidget);
  });

  testWidgets(
    "discount-not-eligible: shows the facility without the discount badge "
    "(not an error state)",
    (tester) async {
      final EmergencyFacilityResult result = EmergencyFacilityResult(
        place: _place(),
        nearestCabinId: "cabin-1",
        discountEligible: false,
        etaMinutesOnFoot: 2,
      );
      await _pump(tester, result: result);

      expect(find.text("Station Didouche"), findsOneWidget);
      expect(find.text("Réduction 50% disponible"), findsNothing);
      expect(find.text("Aller au lieu le plus proche"), findsOneWidget);
    },
  );

  testWidgets(
    "no-facility-found (404): shows a distinct message, not an error state",
    (tester) async {
      await _pump(tester, result: null);

      expect(
        find.text("Aucun lieu accessible trouvé à proximité."),
        findsOneWidget,
      );
      expect(find.text("Aller au lieu le plus proche"), findsNothing);
    },
  );

  testWidgets("location-service-disabled: shows a message distinct from the "
      "permission-denied state", (tester) async {
    await _pump(
      tester,
      locationFailure: const LocationServiceDisabledFailure(),
    );

    expect(
      find.text(
        "Les services de localisation sont désactivés sur cet appareil.",
      ),
      findsOneWidget,
    );
    expect(find.text("Ouvrir les paramètres"), findsNothing);
  });

  testWidgets(
    "location-permission-denied: shows a fallback message and a settings "
    "deep-link button",
    (tester) async {
      await _pump(
        tester,
        locationFailure: const LocationPermissionDeniedFailure(),
      );

      expect(
        find.text(
          "Rahati a besoin d'accéder à votre position pour trouver le "
          "lieu accessible le plus proche.",
        ),
        findsOneWidget,
      );
      expect(find.text("Ouvrir les paramètres"), findsOneWidget);
    },
  );

  testWidgets("location-permission-denied-forever also shows the same fallback "
      "as the plain permission-denied state", (tester) async {
    await _pump(
      tester,
      locationFailure: const LocationPermissionDeniedForeverFailure(),
    );

    expect(find.text("Ouvrir les paramètres"), findsOneWidget);
  });

  testWidgets("renders correctly against the dark theme", (tester) async {
    final EmergencyFacilityResult result = EmergencyFacilityResult(
      place: _place(),
      nearestCabinId: "cabin-1",
      discountEligible: true,
      etaMinutesOnFoot: 2,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceLocationDataSourceProvider.overrideWithValue(
            const _FakeDeviceLocationDataSource(),
          ),
          emergencyRepositoryProvider.overrideWithValue(
            _FakeEmergencyRepository(result: result),
          ),
        ],
        child: MaterialApp(
          theme: RahatiTheme.dark,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const EmergencyResultScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Station Didouche"), findsOneWidget);
  });
}
