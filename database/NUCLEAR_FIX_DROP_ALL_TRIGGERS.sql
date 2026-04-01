-- ============================================
-- NUCLEAR OPTION: Drop ALL triggers and functions
-- ============================================
-- This script removes ALL custom triggers and functions
-- related to bookings to isolate the issue
--
-- ⚠️ WARNING: This will disable all notifications!
-- Use this only to identify which trigger is causing the issue
-- You'll need to recreate triggers after testing
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║             ⚠️  NUCLEAR OPTION - DROP ALL                  ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ This will DROP all triggers and functions on bookings     ║';
    RAISE NOTICE '║ Notifications will NOT work until you recreate them       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- STEP 1: Drop ALL triggers on bookings
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '1️⃣ Dropping ALL triggers on bookings table...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    
    FOR r IN (
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'bookings'::regclass
        AND tgname NOT LIKE 'RI_%'  -- Keep foreign key triggers
    ) LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON bookings', r.tgname);
        RAISE NOTICE '   🗑️ Dropped trigger: %', r.tgname;
    END LOOP;
    
    RAISE NOTICE '✅ All custom triggers dropped';
END $$;

-- ============================================
-- STEP 2: Drop ALL notification-related functions
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '2️⃣ Dropping notification functions...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

DROP FUNCTION IF EXISTS notify_booking_status_change() CASCADE;
DROP FUNCTION IF EXISTS notify_payment_verification() CASCADE;
DROP FUNCTION IF EXISTS handle_booking_update() CASCADE;
DROP FUNCTION IF EXISTS send_booking_notification() CASCADE;
DROP FUNCTION IF EXISTS booking_notification_trigger() CASCADE;
DROP FUNCTION IF EXISTS update_booking_trigger() CASCADE;

-- Search and drop any other function with 'booking' or 'notif' in name
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT p.proname as function_name, n.nspname as schema_name
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE (p.proname ILIKE '%booking%' OR p.proname ILIKE '%notif%')
        AND n.nspname = 'public'
        AND pg_get_functiondef(p.oid) ILIKE '%trigger%'
    ) LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I() CASCADE', r.schema_name, r.function_name);
        RAISE NOTICE '   🗑️ Dropped function: %', r.function_name;
    END LOOP;
END $$;

DO $$ 
BEGIN
    RAISE NOTICE '✅ All notification functions dropped';
END $$;

-- ============================================
-- STEP 3: Verify all triggers are gone
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '3️⃣ Verifying triggers are removed...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    COALESCE(
        (SELECT string_agg(tgname, ', ')
         FROM pg_trigger
         WHERE tgrelid = 'bookings'::regclass
         AND tgname NOT LIKE 'RI_%'),
        '✅ No custom triggers found'
    ) as remaining_triggers;

-- ============================================
-- STEP 4: Test booking update
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   ✅ TRIGGERS REMOVED                      ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ 🧪 TEST NOW:                                              ║';
    RAISE NOTICE '║ Go to admin panel and change booking status to confirmed  ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ If it works now, the problem was in the triggers          ║';
    RAISE NOTICE '║ Run MASTER_FIX_ALL_V2.sql to recreate correct triggers    ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ ⚠️ IMPORTANT:                                             ║';
    RAISE NOTICE '║ No notifications will be sent until triggers are          ║';
    RAISE NOTICE '║ recreated with MASTER_FIX_ALL_V2.sql                      ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
