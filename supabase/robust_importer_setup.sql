-- Robust CSV Importer Schema Extensions
-- Run this in your Supabase SQL Editor

-- 1. DRIVER ALIASES
CREATE TABLE IF NOT EXISTS driver_aliases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
    company_id UUID, -- Placeholder for multi-tenant company logic
    alias_name TEXT NOT NULL,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, alias_name)
);

-- 2. MAPPING PRESETS
CREATE TABLE IF NOT EXISTS mapping_presets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
    company_id UUID, -- Placeholder for multi-tenant company logic
    name TEXT NOT NULL,
    platform_id TEXT NOT NULL,
    mapping JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. EARNINGS TABLE UPDATES (Add missing columns for robust importer)
-- Run these one by one if they don't exist
ALTER TABLE earnings ADD COLUMN IF NOT EXISTS reference TEXT;
ALTER TABLE earnings ADD COLUMN IF NOT EXISTS platform_fee NUMERIC DEFAULT 0;
ALTER TABLE earnings ADD COLUMN IF NOT EXISTS social_fees NUMERIC DEFAULT 0;

-- Add unique constraint for duplicate protection (Run after columns are added)
-- ALTER TABLE earnings ADD CONSTRAINT unique_earning_per_user_ref UNIQUE (user_id, platform_id, reference);

-- Enable RLS
ALTER TABLE driver_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE mapping_presets ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can only access their own driver aliases" 
ON driver_aliases FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only access their own mapping presets" 
ON mapping_presets FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
