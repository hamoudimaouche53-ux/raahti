import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../constants/env.dart";

/// Initializes Supabase (Auth, Storage, Realtime, Postgres — ADR-0005) once,
/// before `runApp`. Must be awaited in `main()`.
///
/// No-op when [AppEnv.isSupabaseConfigured] is `false`: no Supabase project
/// has been provisioned yet (ADR-0016 hosting decision is still open), so
/// the app boots in a backend-less mode for local UI development, CI, and
/// widget tests rather than throwing on missing credentials.
Future<void> bootstrapSupabase() async {
  if (!AppEnv.isSupabaseConfigured) {
    return;
  }
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
  );
}

/// Exposes the initialized [SupabaseClient] to the widget tree.
///
/// Throws only if a widget reads this provider before [bootstrapSupabase]
/// ran and Supabase *is* configured — a programming error, not a runtime
/// condition to design around. No feature reads this provider yet; it is
/// foundation-level dependency-injection wiring (docs/architecture/
/// system-architecture.md §3) for the first feature that needs Supabase.
final Provider<SupabaseClient> supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Whether a Supabase project is configured for this build — read by the UI
/// layer to decide whether to show a "backend not configured" affordance
/// instead of attempting network calls.
final Provider<bool> isSupabaseConfiguredProvider = Provider<bool>(
  (ref) => AppEnv.isSupabaseConfigured,
);
