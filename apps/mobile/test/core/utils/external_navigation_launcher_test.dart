import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/utils/external_navigation_launcher.dart";
import "package:rahati/l10n/app_localizations.dart";
// `url_launcher_platform_interface` is already a resolved transitive
// dependency of `url_launcher` (pubspec.lock) — not added to pubspec.yaml
// per this feature's "no new pubspec dependency" constraint, so the
// analyzer's `depend_on_referenced_packages` info is expected here.
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/link.dart";
// ignore: depend_on_referenced_packages
import "package:url_launcher_platform_interface/url_launcher_platform_interface.dart";

/// Test double for `UrlLauncherPlatform.instance` — same technique the
/// `url_launcher` package's own test suite uses: extend (not implement) so
/// the base class's own token-based `PlatformInterface.verify` still
/// passes. Each entry in [_results] is consumed, in order, by successive
/// [launchUrl] calls; once exhausted, further calls return `false`.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  _FakeUrlLauncherPlatform(this._results);

  final List<bool> _results;
  final List<String> launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return _results.isEmpty ? false : _results.removeAt(0);
  }
}

Future<bool> _pumpAndLaunch(
  WidgetTester tester, {
  required double lat,
  required double lng,
  required String label,
}) async {
  late bool result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await launchExternalNavigation(
              lat: lat,
              lng: lng,
              label: label,
              context: context,
              l10n: AppLocalizations.of(context),
            );
          },
          child: const Text("go"),
        ),
      ),
    ),
  );
  await tester.tap(find.text("go"));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  late UrlLauncherPlatform original;

  setUp(() {
    original = UrlLauncherPlatform.instance;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = original;
  });

  testWidgets("tries the geo: URI first and returns true once it launches", (
    tester,
  ) async {
    final fake = _FakeUrlLauncherPlatform(<bool>[true]);
    UrlLauncherPlatform.instance = fake;

    final bool launched = await _pumpAndLaunch(
      tester,
      lat: 36.75,
      lng: 3.06,
      label: "Station Didouche",
    );

    expect(launched, isTrue);
    expect(fake.launchedUrls, hasLength(1));
    expect(fake.launchedUrls.single, startsWith("geo://36.75,3.06"));
  });

  testWidgets(
    "falls back to the OpenStreetMap web URL when the geo: URI doesn't launch",
    (tester) async {
      final fake = _FakeUrlLauncherPlatform(<bool>[false, true]);
      UrlLauncherPlatform.instance = fake;

      final bool launched = await _pumpAndLaunch(
        tester,
        lat: 36.75,
        lng: 3.06,
        label: "Station Didouche",
      );

      expect(launched, isTrue);
      expect(fake.launchedUrls, hasLength(2));
      expect(fake.launchedUrls[0], startsWith("geo:"));
      expect(fake.launchedUrls[1], contains("openstreetmap.org"));
      expect(fake.launchedUrls[1], contains("mlat=36.75"));
      expect(fake.launchedUrls[1], contains("mlon=3.06"));
    },
  );

  testWidgets(
    "returns false when neither the geo: URI nor the web fallback launches",
    (tester) async {
      final fake = _FakeUrlLauncherPlatform(<bool>[false, false]);
      UrlLauncherPlatform.instance = fake;

      final bool launched = await _pumpAndLaunch(
        tester,
        lat: 0,
        lng: 0,
        label: "x",
      );

      expect(launched, isFalse);
      expect(fake.launchedUrls, hasLength(2));
    },
  );

  testWidgets("includes the label in the geo: URI's query parameter", (
    tester,
  ) async {
    final fake = _FakeUrlLauncherPlatform(<bool>[true]);
    UrlLauncherPlatform.instance = fake;

    await _pumpAndLaunch(
      tester,
      lat: 36.75,
      lng: 3.06,
      label: "Station Didouche",
    );

    expect(fake.launchedUrls.single, contains("Station"));
  });
}
