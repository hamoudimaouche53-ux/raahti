import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/datasources/emergency_remote_data_source.dart";
import "../../data/repositories/rest_emergency_repository.dart";
import "../../domain/entities/emergency_facility_result.dart";
import "../../domain/repositories/emergency_repository.dart";
import "../../domain/usecases/find_nearest_emergency_facility.dart";

/// DI wiring, mirroring `access_session_providers.dart`'s composition-root
/// pattern — reuses [httpClientProvider] and [deviceLocationDataSourceProvider]
/// (both `map_discovery`-owned infra providers) rather than duplicating
/// them; this feature reading `map_discovery`-owned infra providers is the
/// same already-accepted precedent `access_session_providers.dart`'s own
/// doc comment describes.
final Provider<EmergencyRemoteDataSource> emergencyRemoteDataSourceProvider =
    Provider<EmergencyRemoteDataSource>(
      (ref) => EmergencyRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

final Provider<EmergencyRepository> emergencyRepositoryProvider =
    Provider<EmergencyRepository>(
      (ref) =>
          RestEmergencyRepository(ref.watch(emergencyRemoteDataSourceProvider)),
    );

final Provider<FindNearestEmergencyFacility>
findNearestEmergencyFacilityProvider = Provider<FindNearestEmergencyFacility>(
  (ref) => FindNearestEmergencyFacility(ref.watch(emergencyRepositoryProvider)),
);

/// A general "the user recently went through Mode Urgence (SCR-011) and
/// was found eligible" signal — deliberately **not** tied to
/// [EmergencyFacilityResult.nearestCabinId] or any specific
/// `AccessSession`. The backend independently re-verifies eligibility at
/// payment time regardless of which cabin is eventually scanned
/// (ADR-0031) — this flag being "stale" or applying to a station other
/// than the one SCR-011 originally found is harmless by design, not a
/// security concern. This is a deliberate simplification, flagged here.
class EmergencyActivationState {
  const EmergencyActivationState({
    required this.discountEligible,
    required this.activatedAt,
  });

  final bool discountEligible;
  final DateTime activatedAt;
}

/// A generous TTL judgment call — no doc specifies this constant. Bounds
/// how long a Mode Urgence activation stays "live" so a truly stale flag
/// (e.g. from a session days ago that was never consumed) doesn't
/// silently apply to an unrelated later payment.
const Duration kEmergencyActivationTtl = Duration(minutes: 60);

/// Raw activation state — `null` means "no active Mode Urgence session".
/// [activate] is called once SCR-011 successfully loads a result (see
/// [emergencyResultProvider]); [consume] is called by the payment flow
/// once it has read and used the flag (`PaymentNotifier.submit`), clearing
/// it so it doesn't leak into an unrelated later payment.
class EmergencyActivationNotifier
    extends AsyncNotifier<EmergencyActivationState?> {
  @override
  EmergencyActivationState? build() => null;

  void activate(bool discountEligible) {
    state = AsyncData<EmergencyActivationState?>(
      EmergencyActivationState(
        discountEligible: discountEligible,
        activatedAt: DateTime.now(),
      ),
    );
  }

  void consume() => state = const AsyncData<EmergencyActivationState?>(null);
}

final AsyncNotifierProvider<
  EmergencyActivationNotifier,
  EmergencyActivationState?
>
emergencyActivationProvider =
    AsyncNotifierProvider<
      EmergencyActivationNotifier,
      EmergencyActivationState?
    >(EmergencyActivationNotifier.new);

/// [emergencyActivationProvider]'s state, with [kEmergencyActivationTtl]
/// applied at read time — every consumer (`PaymentNotifier`,
/// `PaymentMethodSelectionSheet`) reads this, never the raw notifier
/// state directly, so the TTL check lives in exactly one place.
final Provider<EmergencyActivationState?> effectiveEmergencyActivationProvider =
    Provider<EmergencyActivationState?>((ref) {
      final EmergencyActivationState? state = ref
          .watch(emergencyActivationProvider)
          .value;
      if (state == null) return null;
      if (DateTime.now().difference(state.activatedAt) >
          kEmergencyActivationTtl) {
        return null;
      }
      return state;
    });

/// SCR-011's result lookup — gets the device's current position (via
/// [deviceLocationDataSourceProvider], per its own "SCR-011's established
/// fallback pattern" doc comment) and calls
/// [findNearestEmergencyFacilityProvider]. `AsyncError` carries either a
/// `LocationFailure` subtype (service disabled/permission denied) or an
/// [EmergencyRepositoryFailure] subtype — the screen matches on `error is`
/// for a specific message, same discipline as every other
/// failure-typed `AsyncValue` in this app.
///
/// On a non-null result, calls [EmergencyActivationNotifier.activate] as
/// a side effect from within this provider's own async computation — not
/// from a widget's `build()` — which Riverpod allows (only synchronous
/// side effects during widget build are disallowed).
final FutureProvider<EmergencyFacilityResult?> emergencyResultProvider =
    FutureProvider<EmergencyFacilityResult?>((ref) async {
      final Coordinates position = await ref
          .watch(deviceLocationDataSourceProvider)
          .getCurrentPosition();
      final EmergencyFacilityResult? result = await ref
          .watch(findNearestEmergencyFacilityProvider)
          .call(position: position);
      if (result != null) {
        ref
            .read(emergencyActivationProvider.notifier)
            .activate(result.discountEligible);
      }
      return result;
    });
