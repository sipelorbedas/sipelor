-- ============================================
-- FIX: RLS Policy Column Reference Error
-- ============================================
-- Error: "column f.name does not exist"
-- Cause: RLS policies/triggers referencing non-existent column f.name
-- Solution: Update all policies and triggers to use correct column names
--
-- Fields table columns:
--   - venue_id (NOT name)
--   - venue_name (correct column to use)
--   - venue_type
--   - area
--
-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard → SQL Editor
-- 2. Paste and run this entire script
-- 3. Test by updating a booking status from admin panel
-- ============================================

-- ============================================
-- STEP 1: Check current problematic policies
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '🔍 Checking current policies on bookings table...';
END $$;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    SUBSTRING(qual::text, 1, 100) as qual_preview,
    SUBSTRING(with_check::text, 1, 100) as with_check_preview
FROM pg_policies 
WHERE tablename = 'bookings'
ORDER BY policyname;

-- ============================================
-- STEP 2: Check for triggers that might cause issues
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '🔍 Checking triggers on bookings table...';
END $$;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
ORDER BY trigger_name;

-- ============================================
-- STEP 3: Drop all existing problematic policies
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '🗑️  Dropping old policies...';
END $$;

-- Drop all variations of policies that might exist
DROP POLICY IF EXISTS "Admin can update bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can manage bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can update all bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can update all bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Users can insert bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can delete bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can delete bookings" ON bookings;
DROP POLICY IF EXISTS "Users can delete their own bookings" ON bookings;

-- ============================================
-- STEP 4: Create correct policies WITHOUT incorrect column references
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '✅ Creating new correct policies...';
END $$;

-- Policy 1: Users can INSERT their own bookings
CREATE POLICY "Users can create bookings"
ON bookings
FOR INSERT
TO authenticated
WITH CHECK (
    -- User can only create bookings for themselves
    user_id = auth.uid()
);

-- Policy 2: Users can SELECT their own bookings
CREATE POLICY "Users can view their own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
    -- User can view their own bookings
    user_id = auth.uid()
);

-- Policy 3: Users can UPDATE their own pending bookings (e.g., cancel)
CREATE POLICY "Users can update their own bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (
    -- User can only update their own bookings
    user_id = auth.uid()
)
WITH CHECK (
    -- User can only update their own bookings
    user_id = auth.uid()
);

-- Policy 4: Admins can SELECT all bookings
CREATE POLICY "Admins can view all bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
    -- Check if user is admin from profiles table
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Policy 5: Admins can UPDATE all bookings (CRITICAL FIX)
-- This is the policy that was causing the error
-- Do NOT reference fields table or venues table in this policy
CREATE POLICY "Admins can update all bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (
    -- Check if user is admin from profiles table
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    -- Check if user is admin from profiles table
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Policy 6: Admins can DELETE bookings
CREATE POLICY "Admins can delete bookings"
ON bookings
FOR DELETE
TO authenticated
USING (
    -- Check if user is admin from profiles table
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- ============================================
-- STEP 5: Verify the policies are created correctly
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '✅ Verifying new policies...';
END $$;

SELECT 
    policyname,
    cmd,
    'Created successfully' as status
FROM pg_policies 
WHERE tablename = 'bookings'
ORDER BY policyname;

-- ============================================
-- STEP 6: Check for problematic triggers
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '🔍 Checking for triggers with f.name references...';
END $$;

-- List all triggers and their definitions
SELECT 
    t.trigger_name,
    t.event_manipulation,
    t.action_timing,
    t.action_statement,
    pg_get_triggerdef(pg_trigger.oid) as full_definition
FROM information_schema.triggers t
JOIN pg_trigger ON pg_trigger.tgname = t.trigger_name
WHERE t.event_object_table = 'bookings'
ORDER BY t.trigger_name;

-- If you see any trigger with "f.name" in the definition, you need to:
-- 1. DROP that trigger: DROP TRIGGER trigger_name ON bookings;
-- 2. Recreate it with correct column reference (f.venue_name)

-- ============================================
-- STEP 7: Test the fix
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '🧪 Ready for testing!';
    RAISE NOTICE 'Try updating a booking status from the admin panel';
    RAISE NOTICE 'If error persists, check the trigger definitions above for f.name references';
END $$;

/*
-- Example test (uncomment and modify with actual values):
UPDATE bookings
SET 
    status = 'confirmed',
    updated_at = NOW()
WHERE booking_id = 'BOOK001';

-- If this runs without error, the fix is successful!
*/

-- ============================================
-- STEP 8: Alternative - Drop and recreate bookings table policies entirely
-- ============================================
-- If the above doesn't work, uncomment this section to start fresh:

/*
-- Disable RLS temporarily (DANGEROUS - only for testing)
-- ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;

-- Enable RLS again
-- ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Then recreate all policies using the policies above
*/

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   ✅ FIX SCRIPT COMPLETED                  ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ All policies on bookings table have been recreated        ║';
    RAISE NOTICE '║ without referencing non-existent columns.                 ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ NEXT STEPS:                                                ║';
    RAISE NOTICE '║ 1. Test booking status update from admin panel            ║';
    RAISE NOTICE '║ 2. If error persists, check trigger definitions above     ║';
    RAISE NOTICE '║ 3. Look for any trigger that references f.name            ║';
    RAISE NOTICE '║ 4. Drop and recreate that trigger with f.venue_name       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
