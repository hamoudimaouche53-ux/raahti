import { Inject, Injectable } from '@nestjs/common';
import { Alert } from '../domain/entities/alert.entity';
import { ALERT_REPOSITORY, AlertRepository } from '../domain/ports/alert.repository';
import { AlertStatus } from '../domain/value-objects/alert-status.vo';
import { AlertNotFoundException } from './alert-not-found.exception';

@Injectable()
export class AlertService {
  constructor(@Inject(ALERT_REPOSITORY) private readonly alertRepository: AlertRepository) {}

  /** GET /ops/alerts (FR-OPS-02) — sorted severity DESC, then raisedAt ASC (see PrismaAlertRepository). */
  async list(status?: AlertStatus): Promise<Alert[]> {
    return this.alertRepository.findAll(status);
  }

  /** PATCH /ops/alerts/{alertId} (FR-OPS-02). `operatorId` is the authenticated caller (JWT `sub`). */
  async updateStatus(alertId: string, status: AlertStatus, operatorId: string): Promise<Alert> {
    const alert = await this.alertRepository.findById(alertId);
    if (!alert) {
      throw new AlertNotFoundException(alertId);
    }
    alert.updateStatus(status, operatorId);
    await this.alertRepository.save(alert);
    return alert;
  }
}
