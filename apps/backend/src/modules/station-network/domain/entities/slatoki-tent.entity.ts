export type SlatokiTentDeploymentStatus = 'deployed' | 'folded';

export interface SlatokiTentProps {
  id: string;
  stationId: string;
  deploymentStatus: SlatokiTentDeploymentStatus;
  matCapacity: number;
  hasLighting: boolean;
  hasPrivacyCurtain: boolean;
}

/** ERD §3.3 — at most one per Station (Domain Model §3 invariant), 1:1 with a mobile station carrying Slatoki equipment (FR-SLK-05). */
export class SlatokiTent {
  private constructor(private readonly props: SlatokiTentProps) {}

  static restore(props: SlatokiTentProps): SlatokiTent {
    return new SlatokiTent(props);
  }

  get id(): string {
    return this.props.id;
  }

  get stationId(): string {
    return this.props.stationId;
  }

  get deploymentStatus(): SlatokiTentDeploymentStatus {
    return this.props.deploymentStatus;
  }

  get matCapacity(): number {
    return this.props.matCapacity;
  }

  get hasLighting(): boolean {
    return this.props.hasLighting;
  }

  get hasPrivacyCurtain(): boolean {
    return this.props.hasPrivacyCurtain;
  }
}
