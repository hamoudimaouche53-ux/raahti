import "../../domain/entities/slatoki_tent.dart";

/// JSON mapping for the `SlatokiTent` schema in docs/api/openapi.yaml.
class SlatokiTentDto {
  const SlatokiTentDto({
    required this.deploymentStatus,
    required this.matCapacity,
    required this.hasLighting,
    required this.hasPrivacyCurtain,
  });

  factory SlatokiTentDto.fromJson(Map<String, dynamic> json) {
    return SlatokiTentDto(
      deploymentStatus: json["deploymentStatus"] as String,
      matCapacity: json["matCapacity"] as int,
      hasLighting: json["hasLighting"] as bool,
      hasPrivacyCurtain: json["hasPrivacyCurtain"] as bool,
    );
  }

  final String deploymentStatus;
  final int matCapacity;
  final bool hasLighting;
  final bool hasPrivacyCurtain;

  SlatokiTent toEntity() {
    return SlatokiTent(
      deploymentStatus: switch (deploymentStatus) {
        "deployed" => DeploymentStatus.deployed,
        "folded" => DeploymentStatus.folded,
        _ => DeploymentStatus.folded,
      },
      matCapacity: matCapacity,
      hasLighting: hasLighting,
      hasPrivacyCurtain: hasPrivacyCurtain,
    );
  }
}
