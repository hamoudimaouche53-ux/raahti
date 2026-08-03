// Traces to: ADR-0018, docs/architecture/security-architecture.md §4
// (no secret hard-coded — configuration is dart-define-driven).
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/constants/env.dart";
import "package:rahati/core/providers/supabase_provider.dart";

void main() {
  test("isSupabaseConfiguredProvider reflects AppEnv "
      "(false by default — no project provisioned yet, see ADR-0016)", () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(isSupabaseConfiguredProvider),
      AppEnv.isSupabaseConfigured,
    );
  });

  test("no Supabase credential is hard-coded in AppEnv defaults", () {
    // Regression guard for Security Architecture §4: with no --dart-define
    // supplied (the default `flutter test` invocation), both values must be
    // empty — never a checked-in placeholder that looks like a real key.
    expect(AppEnv.supabaseUrl, isEmpty);
    expect(AppEnv.supabasePublishableKey, isEmpty);
  });
}
