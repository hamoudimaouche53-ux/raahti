import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/emergency/domain/entities/emergency_facility_result.dart";
import "package:rahati/features/emergency/domain/repositories/emergency_repository.dart";
import "package:rahati/features/emergency/presentation/providers/emergency_providers.dart";
import "package:rahati/features/map_discovery/data/datasources/device_location_data_source.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/location_failure.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";

Place _place() => const Place(
  id: "place-1",
  placeKind: PlaceKind.station,
  name: LocalizedText(
    fr: "Station Didouche",
    ar: "محطة ديدوش",
    en: "Didouche Station",
  ),
  position: Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.green,
  distanceMeters: 180,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: <String>[],
);

class _FakeDeviceLocationDataSource extends DeviceLocationDataSource {
  _FakeDeviceLocationDataSource({this.position, this.failure});

  final Coordinates? position;
  final LocationFailure? failure;

  @override
  Future<Coordinates> getCurrentPosition() async {
    final LocationFailure? f = failure;
    if (f != null) throw f;
    return position!;
  }
}

/// Test double for [emergencyActivationProvider] (an
/// `AsyncNotifierProvider`, so it can't be overridden with a plain value —
/// `overrideWith` needs an `EmergencyActivationNotifier Function()`
/// factory) — same pattern as `FakeNearbyPlacesNotifier`
/// (test/support/fake_nearby_places_notifier.dart). Lets a test seed a
/// specific [EmergencyActivationState] (including an arbitrary
/// `activatedAt`) without reaching into the notifier's protected `state`
/// setter.
class _SeededEmergencyActivationNotifier extends EmergencyActivationNotifier {
  _SeededEmergencyActivationNotifier(this._seed);

  final EmergencyActivationState _seed;

  @override
  EmergencyActivationState? build() => _seed;
}

class _FakeEmergencyRepository implements EmergencyRepository {
  _FakeEmergencyRepository({this.result});

  final EmergencyFacilityResult? result;

  @override
  Future<EmergencyFacilityResult?> findNearestFacility({
    required Coordinates position,
  }) async => result;
}

void main() {
  group("EmergencyActivationNotifier", () {
    test("starts as AsyncData(null) — no active Mode Urgence session", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(emergencyActivationProvider),
        const AsyncData<EmergencyActivationState?>(null),
      );
      expect(container.read(effectiveEmergencyActivationProvider), isNull);
    });

    test("activate() sets discountEligible and an activatedAt timestamp", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(emergencyActivationProvider.notifier).activate(true);

      final EmergencyActivationState? state = container.read(
        effectiveEmergencyActivationProvider,
      );
      expect(state, isNotNull);
      expect(state!.discountEligible, isTrue);
      expect(
        DateTime.now().difference(state.activatedAt),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test("consume() clears the activation state back to null", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(emergencyActivationProvider.notifier).activate(true);
      expect(container.read(effectiveEmergencyActivationProvider), isNotNull);

      container.read(emergencyActivationProvider.notifier).consume();

      expect(container.read(effectiveEmergencyActivationProvider), isNull);
      expect(
        container.read(emergencyActivationProvider),
        const AsyncData<EmergencyActivationState?>(null),
      );
    });

    test("effectiveEmergencyActivationProvider treats an activation older "
        "than kEmergencyActivationTtl as expired (returns null)", () {
      final container = ProviderContainer(
        overrides: [
          emergencyActivationProvider.overrideWith(
            () => _SeededEmergencyActivationNotifier(
              EmergencyActivationState(
                discountEligible: true,
                activatedAt: DateTime.now().subtract(
                  kEmergencyActivationTtl + const Duration(minutes: 1),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(effectiveEmergencyActivationProvider), isNull);
    });

    test("effectiveEmergencyActivationProvider still returns a state that is "
        "within the TTL", () {
      final container = ProviderContainer(
        overrides: [
          emergencyActivationProvider.overrideWith(
            () => _SeededEmergencyActivationNotifier(
              EmergencyActivationState(
                discountEligible: false,
                activatedAt: DateTime.now().subtract(
                  const Duration(minutes: 1),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final EmergencyActivationState? state = container.read(
        effectiveEmergencyActivationProvider,
      );
      expect(state, isNotNull);
      expect(state!.discountEligible, isFalse);
    });
  });

  group("emergencyResultProvider", () {
    test("on success, activates EmergencyActivationNotifier with the result's "
        "discountEligible flag", () async {
      final EmergencyFacilityResult result = EmergencyFacilityResult(
        place: _place(),
        nearestCabinId: "cabin-1",
        discountEligible: true,
        etaMinutesOnFoot: 2,
      );
      final container = ProviderContainer(
        overrides: [
          deviceLocationDataSourceProvider.overrideWithValue(
            _FakeDeviceLocationDataSource(
              position: const Coordinates(latitude: 36.75, longitude: 3.06),
            ),
          ),
          emergencyRepositoryProvider.overrideWithValue(
            _FakeEmergencyRepository(result: result),
          ),
        ],
      );
      addTearDown(container.dispose);

      final EmergencyFacilityResult? value = await container.read(
        emergencyResultProvider.future,
      );

      expect(value, same(result));
      expect(
        container.read(effectiveEmergencyActivationProvider)?.discountEligible,
        isTrue,
      );
    });

    test("does not activate EmergencyActivationNotifier when no facility is "
        "found (null result)", () async {
      final container = ProviderContainer(
        overrides: [
          deviceLocationDataSourceProvider.overrideWithValue(
            _FakeDeviceLocationDataSource(
              position: const Coordinates(latitude: 36.75, longitude: 3.06),
            ),
          ),
          emergencyRepositoryProvider.overrideWithValue(
            _FakeEmergencyRepository(result: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final EmergencyFacilityResult? value = await container.read(
        emergencyResultProvider.future,
      );

      expect(value, isNull);
      expect(container.read(effectiveEmergencyActivationProvider), isNull);
    });

    test(
      "propagates a LocationFailure from the device location data source",
      () async {
        // Retry disabled — same rationale as every other error-state test
        // in this log (e.g. `access_session_providers_test.dart`):
        // Riverpod 3.x's default retry would otherwise keep this pending
        // (real `Future.delayed` backoff) well past this test's timeout
        // instead of surfacing as a rejected `.future`.
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            deviceLocationDataSourceProvider.overrideWithValue(
              _FakeDeviceLocationDataSource(
                failure: const LocationPermissionDeniedFailure(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await expectLater(
          () => container.read(emergencyResultProvider.future),
          throwsA(isA<LocationPermissionDeniedFailure>()),
        );
      },
    );
  });
}
