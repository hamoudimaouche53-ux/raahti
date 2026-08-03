// End-to-end smoke test — runs the real app on a real device (no provider
// overrides, no mocks) through Splash → auto-navigate → Map. Complements
// the widget tests in test/ (which use fakes/overrides for speed and
// determinism); this is the one place that exercises the actual
// GoRouter navigation timer, the actual `geolocator` permission flow, and
// the actual `flutter_map` tile-layer widget together.
//
// Traces to: SCR-001 → SCR-003 navigation flow
// (docs/design/user-flows.md §1), US-01.1.1.
//
// Run with a connected device/emulator:
//   flutter test integration_test/app_test.dart -d <deviceId>
// Location permission should be pre-granted (e.g. via
// `adb shell pm grant com.raahti.rahati android.permission.ACCESS_FINE_LOCATION`)
// so the native OS permission dialog — which Flutter's test framework
// cannot drive — never appears.
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/features/app_shell/presentation/screens/splash_screen.dart";
import "package:rahati/features/map_discovery/presentation/screens/map_screen.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("app launches on Splash and auto-navigates to Map", (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RahatiApp()));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text("RAHETI"), findsOneWidget);

    // SplashScreen auto-advances after 2s (lib/features/app_shell/presentation/screens/splash_screen.dart).
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(MapScreen), findsOneWidget);
  });
}
