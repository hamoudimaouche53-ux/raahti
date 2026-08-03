import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

SharedPreferences? _instance;

/// Initializes the on-device key-value store used for durable app settings
/// (SCR-029's language/theme choice — US-06.1's "persists across sessions"
/// requirement). Should be awaited in `main()`, mirroring
/// `bootstrapSupabase`'s precedent in supabase_provider.dart.
Future<void> bootstrapSharedPreferences() async {
  _instance = await SharedPreferences.getInstance();
}

/// `null` until [bootstrapSharedPreferences] has run.
///
/// Deliberately nullable — unlike [supabaseClientProvider], which throws
/// when read before its bootstrap — because [ThemeModeNotifier] and
/// [LocaleNotifier] (app_settings_providers.dart) read this on every single
/// app boot, including every existing widget test that pumps `RahatiApp`
/// without calling the bootstrap. A `null` read simply falls back to
/// in-memory defaults (`ThemeMode.system` / device locale) instead of
/// persisting, keeping those tests unaffected.
final Provider<SharedPreferences?> sharedPreferencesProvider =
    Provider<SharedPreferences?>((ref) => _instance);
