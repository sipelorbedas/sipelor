-- ============================================
-- COMPREHENSIVE SEARCH: Find ALL f.name references
-- ============================================
-- This script searches EVERYWHERE in the database for f.name references
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔍 COMPREHENSIVE SEARCH FOR f.name                 ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- 1. SEARCH IN ALL FUNCTIONS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '1️⃣ Searching in ALL functions...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    '⚠️ CONTAINS f.name' as status,
    pg_get_functiondef(p.oid) as full_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE pg_get_functiondef(p.oid) ILIKE '%f.name%'
ORDER BY p.proname;

-- ============================================
-- 2. SEARCH IN ALL TRIGGERS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '2️⃣ Searching in ALL triggers on bookings table...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    tgname as trigger_name,
    pg_proc.proname as function_called,
    tgenabled as enabled_status,
    CASE tgenabled
        WHEN 'O' THEN '✅ Enabled'
        WHEN 'D' THEN '🔴 Disabled'
        ELSE '❓ Unknown'
    END as status,
    pg_get_triggerdef(pg_trigger.oid) as trigger_definition
FROM pg_trigger
LEFT JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE tgrelid = 'bookings'::regclass
AND tgname NOT LIKE 'RI_%'  -- Exclude foreign key triggers
ORDER BY tgname;

-- ============================================
-- 3. SEARCH IN ALL VIEWS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '3️⃣ Searching in ALL views that reference bookings...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    schemaname,
    viewname,
    '⚠️ CONTAINS f.name' as status,
    definition
FROM pg_views
WHERE (definition ILIKE '%f.name%' OR definition ILIKE '%bookings%')
ORDER BY viewname;

-- ============================================
-- 4. SEARCH IN ALL POLICIES
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '4️⃣ Checking ALL RLS policies on bookings...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as operation,
    qual::text as using_clause,
    with_check::text as with_check_clause
FROM pg_policies 
WHERE tablename = 'bookings'
ORDER BY policyname;

-- ============================================
-- 5. GET FULL DEFINITIONS OF FUNCTIONS CALLED BY TRIGGERS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '5️⃣ Getting full definitions of functions used by triggers...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    pg_proc.proname as function_name,
    '═══════════════════════════════════════════' as separator,
    pg_get_functiondef(pg_proc.oid) as full_function_code
FROM pg_trigger
JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE tgrelid = 'bookings'::regclass
AND tgname NOT LIKE 'RI_%'
ORDER BY pg_proc.proname;

-- ============================================
-- 6. LIST ALL TABLES AND THEIR COLUMNS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '6️⃣ Showing fields table structure (for reference)...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name = 'venue_name' THEN '✅ USE THIS'
        WHEN column_name = 'name' THEN '❌ DOES NOT EXIST'
        ELSE ''
    END as note
FROM information_schema.columns
WHERE table_name = 'fields'
ORDER BY ordinal_position;

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '7️⃣ Showing notifications table structure (for reference)...';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name = 'body' THEN '✅ USE THIS'
        WHEN column_name = 'message' THEN '❌ DOES NOT EXIST'
        ELSE ''
    END as note
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- ============================================
-- RESULTS SUMMARY
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   📊 SEARCH COMPLETE                       ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Review the output above to find:                          ║';
    RAISE NOTICE '║ 1. Functions containing f.name                            ║';
    RAISE NOTICE '║ 2. Triggers on bookings table                             ║';
    RAISE NOTICE '║ 3. Views with f.name                                      ║';
    RAISE NOTICE '║ 4. RLS policies that might cause issues                   ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ Copy the results and share them for detailed fix          ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
