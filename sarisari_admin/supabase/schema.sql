-- Run this in the Supabase SQL editor (or any Postgres instance) to set up
-- the licensing/admin backend. Corresponds to the schema described in the
-- Sari-Sari POS system design.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name TEXT NOT NULL,
  owner_name TEXT,
  contact_number TEXT,
  license_key TEXT UNIQUE NOT NULL,
  license_type TEXT NOT NULL CHECK (license_type IN ('lifetime', 'subscription')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'disabled', 'deleted')),
  device_id TEXT,
  activated_at TIMESTAMPTZ,
  activation_verified BOOLEAN DEFAULT FALSE,
  subscription_plan TEXT,
  amount_due NUMERIC DEFAULT 0,
  due_date DATE,
  last_payment_date DATE,
  cycle_days INT DEFAULT 30,
  grace_period_days INT DEFAULT 3,
  last_login_check TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL,
  method TEXT,
  notes TEXT,
  payment_date TIMESTAMPTZ DEFAULT now()
);

-- Optional mirror of local sales data, pushed during background sync.
-- Used for owner-facing reports/backup only — never authoritative for
-- licensing or stock (the phone's SQLite is authoritative for that).
CREATE TABLE IF NOT EXISTS synced_transactions (
  id UUID PRIMARY KEY,
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  payload JSONB NOT NULL,
  synced_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stores_status ON stores(status);
CREATE INDEX IF NOT EXISTS idx_stores_license_key ON stores(license_key);
CREATE INDEX IF NOT EXISTS idx_payments_store ON payments(store_id);
CREATE INDEX IF NOT EXISTS idx_synced_transactions_store ON synced_transactions(store_id);
