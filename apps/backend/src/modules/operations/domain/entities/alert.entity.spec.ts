import { Alert, InvalidAlertStatusTransitionException } from './alert.entity';

function raiseAlert(overrides: Partial<{ type: 'fire' | 'sos' | 'technical_anomaly' | 'preventive_maintenance'; severity: 'critical' | 'high' | 'medium' | 'low' }> = {}) {
  return Alert.raise({ id: 'a1', stationId: 's1', type: overrides.type ?? 'fire', severity: overrides.severity ?? 'critical' });
}

describe('Alert', () => {
  it('starts open, unacknowledged, unresolved', () => {
    const alert = raiseAlert();
    expect(alert.status).toBe('open');
    expect(alert.acknowledgedBy).toBeNull();
    expect(alert.resolvedAt).toBeNull();
    expect(alert.isActive).toBe(true);
  });

  it('keeps type/severity fixed at raise (immutable per Domain Model §10)', () => {
    const alert = raiseAlert({ type: 'sos', severity: 'high' });
    expect(alert.type).toBe('sos');
    expect(alert.severity).toBe('high');
  });

  describe('updateStatus', () => {
    it('acknowledges, recording the acknowledging operator', () => {
      const alert = raiseAlert();
      alert.updateStatus('acknowledged', 'operator-1');
      expect(alert.status).toBe('acknowledged');
      expect(alert.acknowledgedBy).toBe('operator-1');
    });

    it('allows acknowledged -> in_progress -> resolved', () => {
      const alert = raiseAlert();
      alert.updateStatus('acknowledged', 'operator-1');
      alert.updateStatus('in_progress', 'operator-1');
      expect(alert.status).toBe('in_progress');
      alert.updateStatus('resolved', 'operator-1');
      expect(alert.status).toBe('resolved');
      expect(alert.resolvedAt).not.toBeNull();
      expect(alert.isActive).toBe(false);
    });

    it('allows acknowledged -> resolved directly (e.g. false alarm)', () => {
      const alert = raiseAlert();
      alert.updateStatus('acknowledged', 'operator-1');
      alert.updateStatus('resolved', 'operator-1');
      expect(alert.status).toBe('resolved');
      expect(alert.resolvedAt).not.toBeNull();
    });

    it('rejects open -> in_progress (must acknowledge first)', () => {
      const alert = raiseAlert();
      expect(() => alert.updateStatus('in_progress', 'operator-1')).toThrow(InvalidAlertStatusTransitionException);
    });

    it('rejects open -> resolved (must acknowledge first)', () => {
      const alert = raiseAlert();
      expect(() => alert.updateStatus('resolved', 'operator-1')).toThrow(InvalidAlertStatusTransitionException);
    });

    it('rejects any transition once resolved', () => {
      const alert = raiseAlert();
      alert.updateStatus('acknowledged', 'operator-1');
      alert.updateStatus('resolved', 'operator-1');
      expect(() => alert.updateStatus('acknowledged', 'operator-1')).toThrow(InvalidAlertStatusTransitionException);
    });

    it('does not overwrite acknowledgedBy on a later transition', () => {
      const alert = raiseAlert();
      alert.updateStatus('acknowledged', 'operator-1');
      alert.updateStatus('in_progress', 'operator-2');
      expect(alert.acknowledgedBy).toBe('operator-1');
    });
  });
});
