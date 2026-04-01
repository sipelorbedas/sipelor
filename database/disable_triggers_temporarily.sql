-- ============================================
-- TEMPORARY FIX: Disable all triggers on bookings
-- ============================================
-- Use this to temporarily disable triggers while you fix them
-- This allows booking updates to work while you identify the problem
-- 
-- WARNING: This disables ALL triggers, including important ones
-- Only use for testing/debugging, then re-enable after fix
-- ============================================

-- STEP 1: Disable ALL triggers on bookings table
DO $$ 
BEGIN
    RAISE NOTICE '⚠️  Disabling all triggers on bookings table...';
END $$;

ALTER TABLE bookings DISABLE TRIGGER ALL;

DO $$ 
BEGIN
    RAISE NOTICE '✅ All triggers disabled';
    RAISE NOTICE 'You can now test booking updates';
    RAISE NOTICE '⚠️  REMEMBER TO RE-ENABLE TRIGGERS AFTER FIXING!';
END $$;

-- Test by updating a booking status
-- UPDATE bookings SET status = 'confirmed' WHERE booking_id = 'BOOK001';

-- ============================================
-- STEP 2: Re-enable ALL triggers (run after fix)
-- ============================================
-- Uncomment this block after you've fixed the problematic function:

/*
DO $$ 
BEGIN
    RAISE NOTICE '🔄 Re-enabling all triggers on bookings table...';
END $$;

ALTER TABLE bookings ENABLE TRIGGER ALL;

DO $$ 
BEGIN
    RAISE NOTICE '✅ All triggers re-enabled';
END $$;
*/

-- ============================================
-- SPECIFIC TRIGGER CONTROL
-- ============================================
-- If you want to disable only specific triggers:

/*
-- Disable specific trigger
ALTER TABLE bookings DISABLE TRIGGER trigger_name_here;

-- Re-enable specific trigger
ALTER TABLE bookings ENABLE TRIGGER trigger_name_here;

-- List all triggers and their status
SELECT 
    tgname as trigger_name,
    tgenabled as enabled,
    CASE tgenabled
        WHEN 'O' THEN 'Enabled'
        WHEN 'D' THEN 'Disabled'
        ELSE 'Unknown'
    END as status
FROM pg_trigger
WHERE tgrelid = 'bookings'::regclass
AND tgname NOT LIKE 'RI_%'  -- Exclude foreign key triggers
ORDER BY tgname;
*/

-- ============================================
-- WORKFLOW
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   📝 WORKFLOW                              ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ 1. Run this script to disable triggers                    ║';
    RAISE NOTICE '║ 2. Test booking update - should work now                  ║';
    RAISE NOTICE '║ 3. Run find_and_fix_trigger.sql to find the problem       ║';
    RAISE NOTICE '║ 4. Fix the function (change f.name to f.venue_name)       ║';
    RAISE NOTICE '║ 5. Uncomment and run STEP 2 above to re-enable            ║';
    RAISE NOTICE '║ 6. Test again - should work with triggers enabled         ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
