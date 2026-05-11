-- Lönmeter Multi-tenant Security Configuration
-- RUN THIS IN SUPABASE SQL EDITOR TO ENFORCE DATA ISOLATION

-- 1. DRIVERS TABLE
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own drivers"
ON drivers
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 2. EARNINGS TABLE
ALTER TABLE earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own earnings"
ON earnings
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 3. SETTINGS TABLE
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own settings"
ON settings
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. AUTOMATIC USER_ID ASSIGNMENT (Optional but recommended)
-- Ensures that user_id is always set to the authenticated user's ID on insert.
ALTER TABLE drivers ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE earnings ALTER COLUMN user_id SET DEFAULT auth.uid();
ALTER TABLE settings ALTER COLUMN user_id SET DEFAULT auth.uid();
