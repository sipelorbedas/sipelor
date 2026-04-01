-- ============================================================
-- popup_banners table + RLS policies
-- Run this in the Supabase SQL editor.
--
-- NOTE: PostgreSQL does NOT support CREATE POLICY IF NOT EXISTS.
--       We use DROP POLICY IF EXISTS first, then CREATE POLICY.
-- ============================================================

-- 1. Create table (safe to run multiple times)
CREATE TABLE IF NOT EXISTS popup_banners (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url   text NOT NULL,
  link_url    text,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 2. Enable Row Level Security
ALTER TABLE popup_banners ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies first (avoids the IF NOT EXISTS error)
DROP POLICY IF EXISTS "popup_select_authenticated" ON popup_banners;
DROP POLICY IF EXISTS "popup_all_service_role"     ON popup_banners;

-- 4. Recreate policies
-- Authenticated users can read active popup banners
CREATE POLICY "popup_select_authenticated"
  ON popup_banners
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Service role (admin) has full access
CREATE POLICY "popup_all_service_role"
  ON popup_banners
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
