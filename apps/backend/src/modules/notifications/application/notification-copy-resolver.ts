import { Injectable } from '@nestjs/common';
import { LanguagePreference } from '../../../shared-kernel';
import { NotificationCopy } from '../infrastructure/channels/notification-sender.port';
import { NotificationType } from '../domain/value-objects/notification-type.vo';

/**
 * cross-cutting-architecture.md — Notifications: "notification copy is
 * resolved server-side at send time using the recipient's preferredLanguage
 * ... against a natively-authored FR/AR template pair — never machine-
 * translated". Bilingual (fr|ar), not trilingual — matches the shipped
 * mobile scope and User.preferredLanguage's enum (same drift already flagged
 * for BilingualText elsewhere in Phase 4).
 */
@Injectable()
export class NotificationCopyResolver {
  private static readonly TEMPLATES: Record<NotificationType, Record<'fr' | 'ar', NotificationCopy>> = {
    availability: {
      fr: { title: 'Disponibilité', body: 'Un lieu que vous suivez est maintenant disponible.' },
      ar: { title: 'التوفر', body: 'المكان الذي تتابعه أصبح متاحًا الآن.' },
    },
    operator_alert: {
      fr: { title: 'Alerte opérateur', body: 'Nouvelle alerte sur votre site.' },
      ar: { title: 'تنبيه المشغل', body: 'تنبيه جديد في موقعك.' },
    },
    payment_confirmation: {
      fr: { title: 'Paiement confirmé', body: 'Votre paiement a été confirmé.' },
      ar: { title: 'تم تأكيد الدفع', body: 'تم تأكيد دفعتك.' },
    },
  };

  resolve(type: NotificationType, language: LanguagePreference): NotificationCopy {
    return NotificationCopyResolver.TEMPLATES[type][language.code];
  }
}
