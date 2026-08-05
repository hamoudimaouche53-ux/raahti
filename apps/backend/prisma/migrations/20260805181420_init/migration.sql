-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "supabase_vault";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CreateEnum
CREATE TYPE "VerificationReviewStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "StationConfiguration" AS ENUM ('fixe', 'mobile', 'event');

-- CreateEnum
CREATE TYPE "StationStatus" AS ENUM ('active', 'inactive', 'maintenance');

-- CreateEnum
CREATE TYPE "CabinType" AS ENUM ('H', 'F', 'Slatoki', 'PMR');

-- CreateEnum
CREATE TYPE "OccupancyStatus" AS ENUM ('free', 'occupied', 'out_of_service');

-- CreateEnum
CREATE TYPE "SlatokiTentDeploymentStatus" AS ENUM ('deployed', 'folded');

-- CreateEnum
CREATE TYPE "PlaceType" AS ENUM ('mosque', 'business', 'gas_station', 'other');

-- CreateEnum
CREATE TYPE "DeclaredStatus" AS ENUM ('open', 'closed', 'unknown');

-- CreateEnum
CREATE TYPE "StatusSource" AS ENUM ('community', 'owner_declared');

-- CreateEnum
CREATE TYPE "PreferredLanguage" AS ENUM ('fr', 'ar');

-- CreateEnum
CREATE TYPE "DiabeticVerificationStatus" AS ENUM ('none', 'pending', 'verified', 'rejected');

-- CreateEnum
CREATE TYPE "NotificationChannel" AS ENUM ('push', 'in_app');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('availability', 'operator_alert', 'payment_confirmation');

-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('queued', 'sent', 'delivered', 'failed');

-- CreateEnum
CREATE TYPE "AlertType" AS ENUM ('fire', 'sos', 'technical_anomaly', 'preventive_maintenance');

-- CreateEnum
CREATE TYPE "AlertSeverity" AS ENUM ('critical', 'high', 'medium', 'low');

-- CreateEnum
CREATE TYPE "AlertStatus" AS ENUM ('open', 'acknowledged', 'in_progress', 'resolved');

-- CreateEnum
CREATE TYPE "InterventionType" AS ENUM ('refill', 'emptying', 'repair', 'preventive');

-- CreateEnum
CREATE TYPE "InterventionStatus" AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "TelemetryMetric" AS ENUM ('battery_level', 'water_level', 'door_sensor', 'occupancy');

-- CreateTable
CREATE TABLE "role" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "label_fr" TEXT NOT NULL,
    "label_ar" TEXT NOT NULL,

    CONSTRAINT "role_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_account" (
    "id" UUID NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "preferred_language" "PreferredLanguage" NOT NULL DEFAULT 'fr',
    "diabetic_verified_status" "DiabeticVerificationStatus" NOT NULL DEFAULT 'none',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_role" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "site_scope" TEXT,
    "granted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_role_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_document" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "document_type" TEXT NOT NULL,
    "storage_ref" TEXT NOT NULL,
    "review_status" "VerificationReviewStatus" NOT NULL DEFAULT 'pending',
    "reviewed_by" UUID,
    "submitted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_at" TIMESTAMP(3),

    CONSTRAINT "verification_document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_method" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "method_type" TEXT NOT NULL,
    "provider_ref" TEXT NOT NULL,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payment_method_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favorite" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "station_id" UUID,
    "third_party_place_id" UUID,
    "notify_on_available" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "review" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "station_id" UUID,
    "third_party_place_id" UUID,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "station" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "configuration" "StationConfiguration" NOT NULL,
    "position" geography(Point, 4326) NOT NULL,
    "status" "StationStatus" NOT NULL,
    "cabin_capacity" INTEGER NOT NULL,
    "tank_capacity_liters" INTEGER NOT NULL,
    "installed_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "station_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cabin" (
    "id" UUID NOT NULL,
    "station_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "type" "CabinType" NOT NULL,
    "occupancy_status" "OccupancyStatus" NOT NULL DEFAULT 'free',
    "is_paid" BOOLEAN NOT NULL,
    "price_amount" DECIMAL(10,2),
    "price_currency" TEXT,
    "last_status_change_at" TIMESTAMP(3),

    CONSTRAINT "cabin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "slatoki_tent" (
    "id" UUID NOT NULL,
    "station_id" UUID NOT NULL,
    "deployment_status" "SlatokiTentDeploymentStatus" NOT NULL,
    "mat_capacity" INTEGER NOT NULL,
    "has_lighting" BOOLEAN NOT NULL,
    "has_privacy_curtain" BOOLEAN NOT NULL,
    "last_updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "slatoki_tent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "third_party_place" (
    "id" UUID NOT NULL,
    "name_fr" TEXT NOT NULL,
    "name_ar" TEXT NOT NULL,
    "place_type" "PlaceType" NOT NULL,
    "position" geography(Point, 4326) NOT NULL,
    "is_free" BOOLEAN NOT NULL,
    "price_amount" DECIMAL(10,2),
    "price_currency" TEXT,
    "declared_status" "DeclaredStatus" NOT NULL,
    "status_source" "StatusSource" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "third_party_place_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tag" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "label_fr" TEXT NOT NULL,
    "label_ar" TEXT NOT NULL,

    CONSTRAINT "tag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "third_party_place_tag" (
    "third_party_place_id" UUID NOT NULL,
    "tag_id" UUID NOT NULL,
    "applied_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "third_party_place_tag_pkey" PRIMARY KEY ("third_party_place_id","tag_id")
);

-- CreateTable
CREATE TABLE "notification" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "channel" "NotificationChannel" NOT NULL,
    "type" "NotificationType" NOT NULL,
    "related_alert_id" UUID,
    "related_transaction_id" UUID,
    "status" "NotificationStatus" NOT NULL DEFAULT 'queued',
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alert" (
    "id" UUID NOT NULL,
    "station_id" UUID NOT NULL,
    "type" "AlertType" NOT NULL,
    "severity" "AlertSeverity" NOT NULL,
    "status" "AlertStatus" NOT NULL DEFAULT 'open',
    "acknowledged_by" UUID,
    "raised_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(3),

    CONSTRAINT "alert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maintenance_intervention" (
    "id" UUID NOT NULL,
    "station_id" UUID NOT NULL,
    "alert_id" UUID,
    "intervention_type" "InterventionType" NOT NULL,
    "status" "InterventionStatus" NOT NULL DEFAULT 'scheduled',
    "assigned_to" UUID NOT NULL,
    "scheduled_at" TIMESTAMP(3) NOT NULL,
    "completed_at" TIMESTAMP(3),

    CONSTRAINT "maintenance_intervention_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "telemetry_reading" (
    "id" UUID NOT NULL,
    "station_id" UUID NOT NULL,
    "cabin_id" UUID,
    "metric" "TelemetryMetric" NOT NULL,
    "value" DECIMAL(10,2) NOT NULL,
    "recorded_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "telemetry_reading_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "role_code_key" ON "role"("code");

-- CreateIndex
CREATE UNIQUE INDEX "user_account_email_key" ON "user_account"("email");

-- CreateIndex
CREATE UNIQUE INDEX "user_account_phone_key" ON "user_account"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "user_role_user_id_role_id_site_scope_key" ON "user_role"("user_id", "role_id", "site_scope");

-- CreateIndex
CREATE UNIQUE INDEX "favorite_user_id_station_id_key" ON "favorite"("user_id", "station_id");

-- CreateIndex
CREATE UNIQUE INDEX "favorite_user_id_third_party_place_id_key" ON "favorite"("user_id", "third_party_place_id");

-- CreateIndex
CREATE INDEX "review_station_id_idx" ON "review"("station_id");

-- CreateIndex
CREATE INDEX "review_third_party_place_id_idx" ON "review"("third_party_place_id");

-- CreateIndex
CREATE UNIQUE INDEX "station_code_key" ON "station"("code");

-- CreateIndex
CREATE INDEX "station_status_idx" ON "station"("status");

-- CreateIndex
CREATE INDEX "cabin_occupancy_status_idx" ON "cabin"("occupancy_status");

-- CreateIndex
CREATE UNIQUE INDEX "cabin_station_id_code_key" ON "cabin"("station_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "slatoki_tent_station_id_key" ON "slatoki_tent"("station_id");

-- CreateIndex
CREATE INDEX "third_party_place_place_type_idx" ON "third_party_place"("place_type");

-- CreateIndex
CREATE UNIQUE INDEX "tag_code_key" ON "tag"("code");

-- CreateIndex
CREATE INDEX "notification_user_id_idx" ON "notification"("user_id");

-- CreateIndex
CREATE INDEX "alert_station_id_status_idx" ON "alert"("station_id", "status");

-- CreateIndex
CREATE INDEX "alert_severity_status_idx" ON "alert"("severity", "status");

-- CreateIndex
CREATE INDEX "maintenance_intervention_station_id_idx" ON "maintenance_intervention"("station_id");

-- CreateIndex
CREATE INDEX "telemetry_reading_station_id_metric_recorded_at_idx" ON "telemetry_reading"("station_id", "metric", "recorded_at");

-- AddForeignKey
ALTER TABLE "user_role" ADD CONSTRAINT "user_role_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_role" ADD CONSTRAINT "user_role_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "role"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_document" ADD CONSTRAINT "verification_document_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_document" ADD CONSTRAINT "verification_document_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_method" ADD CONSTRAINT "payment_method_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorite" ADD CONSTRAINT "favorite_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "review" ADD CONSTRAINT "review_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cabin" ADD CONSTRAINT "cabin_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "slatoki_tent" ADD CONSTRAINT "slatoki_tent_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "third_party_place_tag" ADD CONSTRAINT "third_party_place_tag_third_party_place_id_fkey" FOREIGN KEY ("third_party_place_id") REFERENCES "third_party_place"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "third_party_place_tag" ADD CONSTRAINT "third_party_place_tag_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "tag"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification" ADD CONSTRAINT "notification_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alert" ADD CONSTRAINT "alert_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_intervention" ADD CONSTRAINT "maintenance_intervention_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_intervention" ADD CONSTRAINT "maintenance_intervention_alert_id_fkey" FOREIGN KEY ("alert_id") REFERENCES "alert"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "telemetry_reading" ADD CONSTRAINT "telemetry_reading_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "telemetry_reading" ADD CONSTRAINT "telemetry_reading_cabin_id_fkey" FOREIGN KEY ("cabin_id") REFERENCES "cabin"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- Manual SQL (documented in prisma/README.md, not expressible in Prisma's
-- schema language) — applied as part of this first migration per
-- docs/phase-5-release-validation-report.md.

-- GIST spatial indexes (ERD §5 "idx_station_position"/"idx_place_position")
-- — Unsupported("geography(Point,4326)") columns, Prisma cannot manage
-- indexes on them.
CREATE INDEX idx_station_position ON station USING GIST (position);
CREATE INDEX idx_place_position ON third_party_place USING GIST (position);

-- Favorite (ERD §3.16): exactly one of station_id / third_party_place_id is non-null.
ALTER TABLE favorite
  ADD CONSTRAINT favorite_polymorphic_target_xor
  CHECK (
    (station_id IS NOT NULL AND third_party_place_id IS NULL)
    OR (station_id IS NULL AND third_party_place_id IS NOT NULL)
  );

-- Review (ERD §3.15): same pattern.
ALTER TABLE review
  ADD CONSTRAINT review_polymorphic_target_xor
  CHECK (
    (station_id IS NOT NULL AND third_party_place_id IS NULL)
    OR (station_id IS NULL AND third_party_place_id IS NOT NULL)
  );

-- Review: rating must be 1-5 (ERD §3.15 "int, 1-5") — not enforceable via
-- Prisma's `Int` type alone.
ALTER TABLE review
  ADD CONSTRAINT review_rating_range
  CHECK (rating BETWEEN 1 AND 5);

-- Notification (Phase 4 additive gap-fill, confirmed with user 2026-08-05):
-- is_read/read_at must stay consistent.
ALTER TABLE notification
  ADD CONSTRAINT notification_read_state_consistency
  CHECK (
    (is_read = false AND read_at IS NULL)
    OR (is_read = true AND read_at IS NOT NULL)
  );
