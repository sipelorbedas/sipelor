-- ============================================
-- FIND AND FIX TRIGGER/FUNCTION WITH f.name
-- ============================================
-- This script finds the trigger or function causing the error
-- and provides the fix for it.
-- ============================================

-- STEP 1: Find all triggers on bookings table
DO $$ 
BEGIN
    RAISE NOTICE '🔍 STEP 1: Finding all triggers on bookings table...';
END $$;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
ORDER BY trigger_name;

-- STEP 2: Get full trigger definitions
DO $$ 
BEGIN
    RAISE NOTICE '🔍 STEP 2: Getting full trigger definitions...';
END $$;

SELECT 
    tgname as trigger_name,
    pg_get_triggerdef(oid) as full_definition
FROM pg_trigger
WHERE tgrelid = 'bookings'::regclass
ORDER BY tgname;

-- STEP 3: Find functions that might be called by triggers
DO $$ 
BEGIN
    RAISE NOTICE '🔍 STEP 3: Finding functions that reference "f.name"...';
END $$;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE pg_get_functiondef(p.oid) LIKE '%f.name%'
ORDER BY p.proname;

-- STEP 4: Search for any object referencing bookings and fields tables together
DO $$ 
BEGIN
    RAISE NOTICE '🔍 STEP 4: Searching for views/functions that join bookings and fields...';
END $$;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE definition LIKE '%bookings%'
AND definition LIKE '%fields%'
AND definition LIKE '%f.name%';

-- STEP 5: Check for notification triggers (common culprit)
DO $$ 
BEGIN
    RAISE NOTICE '🔍 STEP 5: Checking for notification triggers...';
END $$;

SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
WHERE p.proname LIKE '%notif%'
OR p.proname LIKE '%booking%'
ORDER BY p.proname;

-- ============================================
-- COMMON FIX: Update notification function
-- ============================================
-- If you find a function with f.name, here's how to fix it:

/*
-- Example problematic function:
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- This references f.name which doesn't exist
    INSERT INTO notifications (user_id, message)
    SELECT NEW.user_id, 
           'Booking confirmed for ' || f.name  -- ❌ WRONG
    FROM fields f
    WHERE f.id = NEW.field_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FIX: Change f.name to f.venue_name
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, message)
    SELECT NEW.user_id, 
           'Booking confirmed for ' || f.venue_name  -- ✅ CORRECT
    FROM fields f
    WHERE f.id = NEW.field_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- ============================================
-- STEP 6: Drop problematic triggers temporarily
-- ============================================
-- Uncomment these if you find triggers with f.name references:

/*
-- Drop the trigger (not the function)
DROP TRIGGER IF EXISTS trigger_name ON bookings;

-- Then recreate it after fixing the function
CREATE TRIGGER trigger_name
AFTER UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION fixed_function_name();
*/

-- ============================================
-- RESULT INTERPRETATION
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   📊 ANALYSIS COMPLETE                     ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Check the output above for:                               ║';
    RAISE NOTICE '║ 1. Any trigger that fires on UPDATE                       ║';
    RAISE NOTICE '║ 2. Functions containing "f.name"                          ║';
    RAISE NOTICE '║ 3. The function definition showing the error              ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ Common culprits:                                           ║';
    RAISE NOTICE '║ - notify_booking_status_change()                          ║';
    RAISE NOTICE '║ - send_notification_on_booking_update()                   ║';
    RAISE NOTICE '║ - update_booking_status_trigger()                         ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ FIX: In the function definition, change:                  ║';
    RAISE NOTICE '║      f.name → f.venue_name                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
