import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "app.dart";
import "core/providers/shared_preferences_provider.dart";
import "core/providers/supabase_provider.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapSharedPreferences();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: RahatiApp()));
}
