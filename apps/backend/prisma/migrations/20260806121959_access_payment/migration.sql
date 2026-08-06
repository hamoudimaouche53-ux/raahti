-- CreateEnum
CREATE TYPE "AccessSessionStatus" AS ENUM ('initiated', 'payment_pending', 'unlocked', 'in_use', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "TransactionStatus" AS ENUM ('pending', 'authorized', 'captured', 'failed', 'refunded');

-- NOTE: `prisma migrate diff` also proposed `DROP INDEX "idx_station_position"`
-- and `DROP INDEX "idx_place_position"` here — a false positive, not a real
-- schema change. Those two GIST indexes were added by hand in
-- migrations/20260805181420_init/migration.sql (see prisma/README.md
-- "Indexes") because they sit on `Unsupported("geography(Point, 4326)")`
-- columns Prisma's migration engine cannot manage at all; the diff engine
-- only sees "declared in the live DB, absent from schema.prisma" and
-- proposes dropping them. Removed by hand from this migration, same
-- precedent as the init migration's own hand-edits.

-- CreateTable
CREATE TABLE "access_session" (
    "id" UUID NOT NULL,
    "cabin_id" UUID NOT NULL,
    "user_id" UUID,
    "status" "AccessSessionStatus" NOT NULL DEFAULT 'initiated',
    "qr_code_scanned" TEXT NOT NULL,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "unlocked_at" TIMESTAMP(3),
    "closed_at" TIMESTAMP(3),

    CONSTRAINT "access_session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaction" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "access_session_id" UUID,
    "payment_method_id" UUID,
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'DZD',
    "discount_applied" DECIMAL(5,2),
    "status" "TransactionStatus" NOT NULL DEFAULT 'pending',
    "provider_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "idempotency_key" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "response_status" INTEGER,
    "response_body" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "idempotency_key_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "access_session_cabin_id_status_idx" ON "access_session"("cabin_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_access_session_id_key" ON "transaction"("access_session_id");

-- CreateIndex
CREATE INDEX "transaction_user_id_idx" ON "transaction"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_key_user_id_key_endpoint_key" ON "idempotency_key"("user_id", "key", "endpoint");

-- AddForeignKey
ALTER TABLE "access_session" ADD CONSTRAINT "access_session_cabin_id_fkey" FOREIGN KEY ("cabin_id") REFERENCES "cabin"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_session" ADD CONSTRAINT "access_session_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction" ADD CONSTRAINT "transaction_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction" ADD CONSTRAINT "transaction_access_session_id_fkey" FOREIGN KEY ("access_session_id") REFERENCES "access_session"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction" ADD CONSTRAINT "transaction_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "payment_method"("id") ON DELETE SET NULL ON UPDATE CASCADE;

