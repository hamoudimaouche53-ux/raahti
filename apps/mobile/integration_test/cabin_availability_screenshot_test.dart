// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-04.2 (SCR-014 Cabin Availability
// Confirmation) with real on-device rendering. `accessSessionRepositoryProvider`
// is overridden with deterministic fakes (below) rather than a real
// backend — ADR-0016's hosting decision is still open, same root cause
// flagged throughout this log for every EPIC-04 story. Run with
// `--dart-define=USE_MOCK_PLACE_DETAIL=true` so `MockPlaceDetailRepository`
// (ADR-0023) supplies a station with a cabin, making the "Scanner le QR"
// entry point (US-04.1) appear on the place-detail sheet.
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";
import "package:rahati/features/access_payment/domain/repositories/access_session_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/access_session_providers.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_detail_sheet.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_marker.dart";

class _FakeNearbyPlacesNotifier extends NearbyPlacesNotifier {
  _FakeNearbyPlacesNotifier(this._build);
  final Future<PlacesSnapshot> Function() _build;

  @override
  Future<PlacesSnapshot> build() => _build();
}

/// Never resolves within this diagnostic's hold window — freezes SCR-014
/// in its `checking` state so it can be screenshotted.
class _NeverResolvingAccessSessionRepository
    implements AccessSessionRepository {
  const _NeverResolvingAccessSessionRepository();

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) {
    return Completer<AccessSession>().future;
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) {
    return Completer<AccessSession>().future;
  }
}

/// Always throws [CabinUnavailableFailure] — freezes SCR-014 in its
/// `unavailable` state (no auto-transition out of it), so it can be
/// screenshotted.
class _UnavailableAccessSessionRepository implements AccessSessionRepository {
  const _UnavailableAccessSessionRepository();

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    throw const CabinUnavailableFailure();
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) {
    throw UnimplementedError();
  }
}

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

Place _station() => Place(
  id: "s1",
  placeKind: PlaceKind.station,
  name: const LocalizedText(
    fr: "Station Didouche",
    ar: "محطة ديدوش",
    en: "Didouche Station",
  ),
  position: _center,
  pinColor: PinColor.amber,
  distanceMeters: 180,
  averageRating: 4.6,
  reviewCount: 32,
  isFree: false,
  tags: const ["women_confirmed", "wudu"],
);

List<dynamic> _positionOverrides() => [
  userPositionProvider.overrideWith((ref) async => _center),
  userPositionStreamProvider.overrideWith((ref) => Stream.value(_center)),
];

class _LightThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

class _DarkThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}

class _ArabicLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => const Locale("ar");
}

Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Navigates Map → PlaceDetailSheet → SCR-013 → submits a manually-entered
/// code, landing on SCR-014 (`CabinAvailabilityScreen`) with whichever
/// `accessSessionRepositoryProvider` override the caller configured.
Future<void> _navigateToAvailabilityScreen(
  WidgetTester tester, {
  String buttonText = "Scanner le QR",
  String manualEntryButtonText = "Saisir le code manuellement",
  String submitButtonText = "Valider",
}) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.tap(find.byType(PlaceMarker));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await _settle(tester, seconds: 2);

  await tester.scrollUntilVisible(
    find.text(buttonText),
    200,
    scrollable: find.descendant(
      of: find.byType(PlaceDetailSheet),
      matching: find.byType(Scrollable),
    ),
  );
  await _settle(tester, seconds: 1);

  await tester.tap(find.text(buttonText));
  await _settle(tester, seconds: 2);

  await tester.tap(find.text(manualEntryButtonText));
  await _settle(tester, seconds: 1);
  await tester.enterText(find.byType(TextField), "RAHETI-STATION-1-CABIN-2");
  await tester.tap(find.text(submitButtonText));
  await _settle(tester, seconds: 1);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): SCR-014 checking state", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _NeverResolvingAccessSessionRepository(),
          ),
          nearbyPlacesProvider.overrideWith(
            () => _FakeNearbyPlacesNotifier(
              () async => PlacesSnapshot(
                places: [_station()],
                lastSyncedAt: DateTime.now(),
                isFromCache: false,
              ),
            ),
          ),
        ],
        child: const RahatiApp(),
      ),
    );
    await _navigateToAvailabilityScreen(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("Dark (FR): SCR-014 unavailable state (409)", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _UnavailableAccessSessionRepository(),
          ),
          nearbyPlacesProvider.overrideWith(
            () => _FakeNearbyPlacesNotifier(
              () async => PlacesSnapshot(
                places: [_station()],
                lastSyncedAt: DateTime.now(),
                isFromCache: false,
              ),
            ),
          ),
        ],
        child: const RahatiApp(),
      ),
    );
    await _navigateToAvailabilityScreen(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("RTL (AR): SCR-014 checking state, mirrored", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _NeverResolvingAccessSessionRepository(),
          ),
          nearbyPlacesProvider.overrideWith(
            () => _FakeNearbyPlacesNotifier(
              () async => PlacesSnapshot(
                places: [_station()],
                lastSyncedAt: DateTime.now(),
                isFromCache: false,
              ),
            ),
          ),
        ],
        child: const RahatiApp(),
      ),
    );
    await _navigateToAvailabilityScreen(
      tester,
      buttonText: "مسح رمز QR",
      manualEntryButtonText: "إدخال الرمز يدويًا",
      submitButtonText: "تأكيد",
    );

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });
}
