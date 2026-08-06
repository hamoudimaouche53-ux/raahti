// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-04.4 (SCR-017 Unlock Confirmation / Access
// Active) with real on-device rendering. `accessSessionRepositoryProvider`
// is overridden with a deterministic fake (below) resolving a free
// cabin's `AccessSession` (status `unlocked`) directly — the shortest
// real path to SCR-017 (skips SCR-015/016 entirely per US-04.2's
// free-cabin contract). Run with `--dart-define=USE_MOCK_PLACE_DETAIL=true`
// so `MockPlaceDetailRepository` (ADR-0023) supplies a station with a
// free cabin (`s1-cabin-1`), matching the fake `AccessSession` below.
//
// The `unlocking` (animating) state lasts only ~1.6s — too brief to
// reliably hit via on-device automation overhead (the same reasoning
// this log has already applied to other sub-2s transitions) — so all
// three captures below show the settled "Session en cours" state, SCR-017's
// primary, long-lived content, held open by this diagnostic's HOLD_START
// pattern the same way every other screenshot in this log is.
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
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

/// Immediately resolves with an `unlocked` (free-cabin) session for
/// `MockPlaceDetailRepository`'s free cabin (`s1-cabin-1`) — takes
/// SCR-013/014 straight through to SCR-017 without ever needing SCR-015/016
/// or a real backend.
class _FreeAccessSessionRepository implements AccessSessionRepository {
  const _FreeAccessSessionRepository();

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    return AccessSession(
      id: "session-1",
      cabinId: "s1-cabin-1",
      status: AccessSessionStatus.unlocked,
      startedAt: DateTime.now(),
      unlockedAt: DateTime.now(),
    );
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) {
    return Completer<AccessSession>().future;
  }

  @override
  Future<AccessSession> completeAccessSession(String accessSessionId) async {
    return AccessSession(
      id: accessSessionId,
      cabinId: "s1-cabin-1",
      status: AccessSessionStatus.completed,
      startedAt: DateTime.now(),
      unlockedAt: DateTime.now(),
    );
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
/// code → SCR-014 (auto-resolves `unlocked`/free) → SCR-017 (Unlock
/// Confirmation), settled well past its ~1.6s animation.
Future<void> _navigateToUnlockConfirmation(
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
  await tester.enterText(find.byType(TextField), "RAHETI-STATION-1-CABIN-1");
  await tester.tap(find.text(submitButtonText));
  // SCR-014 (checking, briefly) -> SCR-017, well past its ~1.6s animation.
  await _settle(tester, seconds: 4);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): SCR-017 unlocked/Session en cours state", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _FreeAccessSessionRepository(),
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
    await _navigateToUnlockConfirmation(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("Dark (FR): SCR-017 unlocked/Session en cours state", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _FreeAccessSessionRepository(),
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
    await _navigateToUnlockConfirmation(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("RTL (AR): SCR-017 unlocked/Session en cours state, mirrored", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _FreeAccessSessionRepository(),
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
    await _navigateToUnlockConfirmation(
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
