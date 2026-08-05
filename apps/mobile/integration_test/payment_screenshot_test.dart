// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-04.3 (SCR-015 Payment Method Selection,
// SCR-016 Payment Processing, SCR-018 Payment Failed) with real on-device
// rendering. `accessSessionRepositoryProvider`/`paymentMethodRepositoryProvider`/
// `paymentRepositoryProvider` are all overridden with deterministic fakes
// (below) rather than a real backend — ADR-0016's hosting decision is
// still open, same root cause flagged throughout this log for every
// EPIC-04 story. Run with `--dart-define=USE_MOCK_PLACE_DETAIL=true` so
// `MockPlaceDetailRepository` (ADR-0023) supplies a station with a paid
// cabin (`s1-cabin-2`, 50 DZD), matching the fake `AccessSession` below.
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";
import "package:rahati/features/access_payment/domain/repositories/access_session_repository.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_method_repository.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/access_session_providers.dart";
import "package:rahati/features/access_payment/presentation/providers/payment_providers.dart";
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

/// Immediately resolves with an `initiated` (paid) session for
/// `MockPlaceDetailRepository`'s paid cabin (`s1-cabin-2`, 50 DZD) —
/// takes SCR-013/014 straight through to SCR-015 without ever needing a
/// real backend.
class _PaidAccessSessionRepository implements AccessSessionRepository {
  const _PaidAccessSessionRepository();

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    return AccessSession(
      id: "session-1",
      cabinId: "s1-cabin-2",
      status: AccessSessionStatus.initiated,
      startedAt: DateTime.now(),
      unlockedAt: null,
    );
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) {
    return Completer<AccessSession>().future;
  }
}

class _FakePaymentMethodRepository implements PaymentMethodRepository {
  const _FakePaymentMethodRepository();

  @override
  Future<List<PaymentMethod>> getSavedPaymentMethods() async => const [
    PaymentMethod(
      id: "pm-1",
      methodType: PaymentMethodType.card,
      providerRef: "Visa •••• 4242",
      isDefault: true,
    ),
    PaymentMethod(
      id: "pm-2",
      methodType: PaymentMethodType.mobileWallet,
      providerRef: "Wallet Mobile",
      isDefault: false,
    ),
  ];

  @override
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  }) {
    return Completer<PaymentMethod>().future;
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) {
    return Completer<void>().future;
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId) {
    return Completer<PaymentMethod>().future;
  }
}

/// Always throws [PaymentDeclinedFailure] — freezes SCR-018 in its
/// payment-declined state (no auto-transition out of it), so it can be
/// screenshotted.
class _DeclinedPaymentRepository implements PaymentRepository {
  const _DeclinedPaymentRepository();

  @override
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    throw const PaymentDeclinedFailure(
      "Mock gateway declined this payment for the screenshot diagnostic.",
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
/// code → SCR-014 (auto-resolves `initiated`/paid) → SCR-015 (Payment
/// Method Selection Sheet), which this diagnostic leaves open.
Future<void> _navigateToPaymentMethodSheet(
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
  // SCR-014 (checking, briefly) -> SCR-015 (this diagnostic's target).
  await _settle(tester, seconds: 3);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): SCR-015 Payment Method Selection Sheet", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _PaidAccessSessionRepository(),
          ),
          paymentMethodRepositoryProvider.overrideWithValue(
            const _FakePaymentMethodRepository(),
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
    await _navigateToPaymentMethodSheet(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("Dark (FR): SCR-018 payment-declined state", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _PaidAccessSessionRepository(),
          ),
          paymentMethodRepositoryProvider.overrideWithValue(
            const _FakePaymentMethodRepository(),
          ),
          paymentRepositoryProvider.overrideWithValue(
            const _DeclinedPaymentRepository(),
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
    await _navigateToPaymentMethodSheet(tester);
    // SCR-015 is open with the default method pre-selected — pay, which
    // routes through SCR-016 (brief) to SCR-018 (this test's target).
    await tester.tap(find.text("Payer 50 DZD"));
    await _settle(tester, seconds: 2);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("RTL (AR): SCR-015 Payment Method Selection Sheet, mirrored", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          accessSessionRepositoryProvider.overrideWithValue(
            const _PaidAccessSessionRepository(),
          ),
          paymentMethodRepositoryProvider.overrideWithValue(
            const _FakePaymentMethodRepository(),
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
    await _navigateToPaymentMethodSheet(
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
