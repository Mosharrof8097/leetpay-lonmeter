-- Lönmeter Database Schema
-- Run this in your Supabase SQL Editor

-- 1. Bolt Trips Data
CREATE TABLE IF NOT EXISTS bolt_trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
    order_reference TEXT UNIQUE NOT NULL,
    driver_name TEXT,
    price_total DECIMAL(12, 2) NOT NULL,
    net_earnings DECIMAL(12, 2) NOT NULL,
    tax_6_percent DECIMAL(12, 2),
    employer_fee_31_42 DECIMAL(12, 2),
    net_payout_to_driver DECIMAL(12, 2),
    order_created_timestamp BIGINT,
    order_status TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Platform Configs (Dynamic Rules & API Credentials)
CREATE TABLE IF NOT EXISTS platform_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
    platform_name TEXT NOT NULL, -- 'bolt', 'uber', etc.
    client_id TEXT,
    client_secret TEXT,
    fleet_id TEXT,
    tax_percent DECIMAL(10, 4) DEFAULT 5.66, -- 0.0566 factor
    platform_fee_percent DECIMAL(5, 2) DEFAULT 20.0,
    driver_share_percent DECIMAL(5, 2) DEFAULT 45.0,
    holiday_pay_percent DECIMAL(5, 2) DEFAULT 12.0,
    pension_percent DECIMAL(5, 2) DEFAULT 4.5,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, platform_name)
);

-- 3. User Settings (Company Branding & Defaults)
CREATE TABLE IF NOT EXISTS settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) DEFAULT auth.uid(),
    company_name TEXT DEFAULT 'Lönmeter AB',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4. Calculation Rules (Presets)
CREATE TABLE IF NOT EXISTS calculation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
    name TEXT NOT NULL, -- e.g., 'Standard Rule', 'Summer Promo'
    platform_id TEXT, -- optional, if specific to a platform
    tax_percent DECIMAL(10, 4) DEFAULT 5.66,
    platform_fee_percent DECIMAL(5, 2) DEFAULT 20.0,
    driver_share_percent DECIMAL(5, 2) DEFAULT 45.0,
    holiday_pay_percent DECIMAL(5, 2) DEFAULT 12.0,
    pension_percent DECIMAL(5, 2) DEFAULT 4.5,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE bolt_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE calculation_rules ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can only access their own bolt trips" ON bolt_trips;
DROP POLICY IF EXISTS "Users can only access their own platform configs" ON platform_configs;
DROP POLICY IF EXISTS "Users can only access their own settings" ON settings;
DROP POLICY IF EXISTS "Users can only access their own calculation rules" ON calculation_rules;

CREATE POLICY "Users can only access their own bolt trips" ON bolt_trips FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can only access their own platform configs" ON platform_configs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can only access their own settings" ON settings FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can only access their own calculation rules" ON calculation_rules FOR ALL USING (auth.uid() = user_id);
