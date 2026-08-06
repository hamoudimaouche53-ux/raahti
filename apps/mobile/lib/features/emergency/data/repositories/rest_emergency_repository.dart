import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../domain/entities/emergency_facility_result.dart";
import "../../domain/repositories/emergency_repository.dart";
import "../datasources/emergency_remote_data_source.dart";

/// [EmergencyRepository] implementation backed by the REST API — thin
/// delegate, mirrors `RestAccessSessionRepository`.
class RestEmergencyRepository implements EmergencyRepository {
  const RestEmergencyRepository(this._remote);

  final EmergencyRemoteDataSource _remote;

  @override
  Future<EmergencyFacilityResult?> findNearestFacility({
    required Coordinates position,
  }) async {
    final dto = await _remote.fetchNearestFacility(
      lat: position.latitude,
      lng: position.longitude,
    );
    return dto?.toEntity();
  }
}
