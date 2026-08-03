// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates one representative EPIC-05 secondary screen
// (SCR-026 Favorites List) with real on-device rendering, populated data,
// and an interactive Switch. Run with `--dart-define=USE_MOCK_AUTH=true`.
//
// Reduced evidence scope, same precedent Feature 17 established: SCR-021/
// 022/023/027/SCR-007 are already covered by this pass's widget tests
// (including their own Arabic-RTL rendering assertions) and share
// SCR-020/030's already-verified theme/RTL infrastructure (Scaffold,
// AppBar, ListTile, M3 components) — a full Light/Dark/RTL triad per
// secondary screen would mostly re-prove that shared infrastructure
// rather than surface new evidence. SCR-026 is captured live here because
// it's the one secondary screen with genuinely distinct interactive
// content (a live Switch reflecting `MockFavoriteRepository` state).
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";

class _LightThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

Future<void> _settle(WidgetTester tester, {int seconds = 2}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): SCR-026 Favorites List, populated", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          userPositionProvider.overrideWith((ref) async => _center),
          userPositionStreamProvider.overrideWith(
            (ref) => Stream.value(_center),
          ),
        ],
        child: const RahatiApp(),
      ),
    );
    await _settle(tester, seconds: 5);

    await tester.tap(find.text("Profil"));
    await _settle(tester, seconds: 2);

    await tester.tap(find.text("Se connecter"));
    await _settle(tester, seconds: 2);
    await tester.enterText(
      find.byType(TextField).first,
      "amina.b@example.com",
    );
    await tester.enterText(find.byType(TextField).last, "password123");
    await tester.tap(find.text("Se connecter").last);
    await _settle(tester, seconds: 2);

    await tester.tap(find.text("Favoris"));
    await _settle(tester, seconds: 2);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });
}
