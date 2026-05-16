-- ============================================================
-- Lönmeter — Unified Earnings Table (FRESH SETUP)
-- This script DROPS and RECREATES the table cleanly.
-- Safe to run in development — no production data yet.
-- ============================================================

-- Step 1: Drop existing table (and its indexes/triggers)
DROP TABLE IF EXISTS earnings_raw CASCADE;

-- Step 2: Drop old trigger function if exists
DROP FUNCTION IF EXISTS update_earnings_raw_updated_at() CASCADE;

-- Step 3: Create fresh table with correct column names
CREATE TABLE earnings_raw (
    id TEXT PRIMARY KEY,

    owner_id  UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id)    ON DELETE SET NULL,
    driver_name TEXT,

    -- Financial
    brutto_amount   NUMERIC(12, 2) NOT NULL DEFAULT 0,
    net_amount      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    moms_amount     NUMERIC(12, 2) DEFAULT 0,
    platform_fee    NUMERIC(12, 2) DEFAULT 0,
    dricks          NUMERIC(12, 2) DEFAULT 0,

    -- Metadata
    platform        TEXT NOT NULL DEFAULT 'bolt',
    source          TEXT NOT NULL DEFAULT 'manual',
    date            DATE,
    week_number     INT,
    entry_month     INT,
    entry_year      INT,
    reference       TEXT,

    -- Settlement
    is_settled      BOOLEAN DEFAULT false,

    -- Audit
    raw_data        JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Indexes
CREATE INDEX idx_earnings_raw_owner    ON earnings_raw(owner_id);
CREATE INDEX idx_earnings_raw_driver   ON earnings_raw(driver_id);
CREATE INDEX idx_earnings_raw_date     ON earnings_raw(date);
CREATE INDEX idx_earnings_raw_month_yr ON earnings_raw(entry_month, entry_year);
CREATE INDEX idx_earnings_raw_platform ON earnings_raw(platform);
CREATE INDEX idx_earnings_raw_source   ON earnings_raw(source);
CREATE INDEX idx_earnings_raw_settled  ON earnings_raw(is_settled);

-- Step 5: Row Level Security
ALTER TABLE earnings_raw ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access own earnings_raw"
    ON earnings_raw
    FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Step 6: Auto-update trigger
CREATE FUNCTION update_earnings_raw_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_earnings_raw_updated_at
    BEFORE UPDATE ON earnings_raw
    FOR EACH ROW EXECUTE FUNCTION update_earnings_raw_updated_at();

-- ============================================================
-- SUCCESS! Table created fresh with correct column names.
-- ============================================================
