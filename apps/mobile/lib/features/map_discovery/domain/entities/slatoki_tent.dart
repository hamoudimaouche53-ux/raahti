/// Mirrors `SlatokiTent.deploymentStatus` in docs/api/openapi.yaml.
enum DeploymentStatus { deployed, folded }

/// A RAHETI Slatoki tent, one-to-one with the `Station` that carries it
/// (ERD §3.3, `docs/architecture/domain-model.md#3-bounded-context-station-network`
/// — `SlatokiTent` is part of `Station`'s own aggregate boundary, not a
/// separate entity Slatoki owns; the Slatoki bounded context only *reads*
/// it, per Domain Model §4). Fetched lazily as part of [StationDetail]
/// from `GET /stations/{id}` — never carried by the map/list read model.
class SlatokiTent {
  const SlatokiTent({
    required this.deploymentStatus,
    required this.matCapacity,
    required this.hasLighting,
    required this.hasPrivacyCurtain,
  });

  final DeploymentStatus deploymentStatus;
  final int matCapacity;
  final bool hasLighting;
  final bool hasPrivacyCurtain;
}
