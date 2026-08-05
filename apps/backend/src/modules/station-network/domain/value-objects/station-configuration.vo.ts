import { DomainException } from '../../../../shared-kernel';

export type StationConfiguration = 'fixe' | 'mobile' | 'event';

const VALID: readonly StationConfiguration[] = ['fixe', 'mobile', 'event'];

export class InvalidStationConfigurationException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_CONFIGURATION';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized station configuration (expected fixe|mobile|event).`);
  }
}

export function assertStationConfiguration(value: string): asserts value is StationConfiguration {
  if (!VALID.includes(value as StationConfiguration)) {
    throw new InvalidStationConfigurationException(value);
  }
}
