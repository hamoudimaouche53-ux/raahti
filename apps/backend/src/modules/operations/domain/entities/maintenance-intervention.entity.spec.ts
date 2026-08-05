import { InvalidInterventionStatusTransitionException, MaintenanceIntervention } from './maintenance-intervention.entity';

function scheduleIntervention() {
  return MaintenanceIntervention.schedule({
    id: 'mi1',
    stationId: 's1',
    interventionType: 'refill',
    assignedTo: 'operator-1',
    scheduledAt: new Date('2026-08-10T09:00:00Z'),
  });
}

describe('MaintenanceIntervention', () => {
  it('starts scheduled, with no completion timestamp', () => {
    const intervention = scheduleIntervention();
    expect(intervention.status).toBe('scheduled');
    expect(intervention.completedAt).toBeNull();
  });

  it('defaults alertId to null when not linked to an alert (preventive maintenance)', () => {
    const intervention = scheduleIntervention();
    expect(intervention.alertId).toBeNull();
  });

  it('carries an alertId when triggered by an alert', () => {
    const intervention = MaintenanceIntervention.schedule({
      id: 'mi1',
      stationId: 's1',
      alertId: 'a1',
      interventionType: 'repair',
      assignedTo: 'operator-1',
      scheduledAt: new Date(),
    });
    expect(intervention.alertId).toBe('a1');
  });

  describe('status transitions', () => {
    it('allows scheduled -> in_progress -> completed', () => {
      const intervention = scheduleIntervention();
      intervention.start();
      expect(intervention.status).toBe('in_progress');
      intervention.complete();
      expect(intervention.status).toBe('completed');
      expect(intervention.completedAt).not.toBeNull();
    });

    it('allows scheduled -> cancelled', () => {
      const intervention = scheduleIntervention();
      intervention.cancel();
      expect(intervention.status).toBe('cancelled');
    });

    it('allows in_progress -> cancelled', () => {
      const intervention = scheduleIntervention();
      intervention.start();
      intervention.cancel();
      expect(intervention.status).toBe('cancelled');
    });

    it('rejects scheduled -> completed directly', () => {
      const intervention = scheduleIntervention();
      expect(() => intervention.complete()).toThrow(InvalidInterventionStatusTransitionException);
    });

    it('rejects any transition once completed', () => {
      const intervention = scheduleIntervention();
      intervention.start();
      intervention.complete();
      expect(() => intervention.cancel()).toThrow(InvalidInterventionStatusTransitionException);
    });

    it('rejects any transition once cancelled', () => {
      const intervention = scheduleIntervention();
      intervention.cancel();
      expect(() => intervention.start()).toThrow(InvalidInterventionStatusTransitionException);
    });
  });
});
