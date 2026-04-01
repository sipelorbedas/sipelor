-- ============================================
-- DIAGNOSTIC: Check Notification RLS Policies
-- ============================================
-- Run this to quickly check if policies are configured correctly
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  DIAGNOSTIC: Notification RLS Status                       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ========================================
-- CHECK 1: Does notifications table exist?
-- ========================================

DO $$ 
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
    ) INTO table_exists;
    
    IF table_exists THEN
        RAISE NOTICE '✅ CHECK 1: Table "notifications" exists';
    ELSE
        RAISE NOTICE '❌ CHECK 1: Table "notifications" DOES NOT EXIST!';
        RAISE EXCEPTION 'Table notifications not found!';
    END IF;
END $$;

-- ========================================
-- CHECK 2: Is RLS enabled?
-- ========================================

DO $$ 
DECLARE
    rls_enabled BOOLEAN;
BEGIN
    SELECT relrowsecurity INTO rls_enabled
    FROM pg_class
    WHERE relname = 'notifications';
    
    IF rls_enabled THEN
        RAISE NOTICE '✅ CHECK 2: RLS is ENABLED on notifications';
    ELSE
        RAISE NOTICE '❌ CHECK 2: RLS is DISABLED on notifications';
        RAISE NOTICE '   Run FIX_NOTIFICATION_RLS_POLICY_V2.sql to enable';
    END IF;
END $$;

-- ========================================
-- CHECK 3: Show table schema
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  CHECK 3: Notifications Table Schema                       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    column_name as "Column",
    data_type as "Type",
    is_nullable as "Nullable",
    column_default as "Default"
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- ========================================
-- CHECK 4: List all RLS policies
-- ========================================

DO $$ 
DECLARE
    policy_count INTEGER;
    insert_policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'notifications';
    
    SELECT COUNT(*) INTO insert_policy_count
    FROM pg_policies 
    WHERE tablename = 'notifications' 
      AND cmd = 'INSERT';
    
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  CHECK 4: RLS Policies Status                              ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE 'Total policies: %', policy_count;
    RAISE NOTICE 'INSERT policies: %', insert_policy_count;
    
    IF insert_policy_count = 0 THEN
        RAISE NOTICE '❌ NO INSERT POLICY FOUND!';
        RAISE NOTICE '   This is why notifications are failing!';
        RAISE NOTICE '   Run FIX_NOTIFICATION_RLS_POLICY_V2.sql to fix';
    ELSE
        RAISE NOTICE '✅ INSERT policy exists';
    END IF;
END $$;

SELECT 
    policyname as "Policy Name",
    cmd as "Command",
    CASE 
        WHEN qual IS NULL THEN 'true (no restriction)'
        ELSE qual 
    END as "USING (SELECT condition)",
    CASE 
        WHEN with_check IS NULL THEN 'true (no restriction)'
        ELSE with_check 
    END as "WITH CHECK (INSERT condition)",
    permissive as "Permissive"
FROM pg_policies 
WHERE tablename = 'notifications'
ORDER BY cmd, policyname;

-- ========================================
-- CHECK 5: Check table permissions
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  CHECK 5: Table Permissions                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    grantee as "Role",
    string_agg(privilege_type, ', ') as "Privileges"
FROM information_schema.role_table_grants
WHERE table_name = 'notifications'
  AND grantee IN ('authenticated', 'anon', 'service_role')
GROUP BY grantee
ORDER BY grantee;

-- ========================================
-- CHECK 6: Test INSERT (will fail if policies wrong)
-- ========================================

DO $$ 
DECLARE
    test_user_id UUID;
    test_notification_id UUID;
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  CHECK 6: Test Notification Insert                         ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    
    -- Get first user or use random UUID
    SELECT id INTO test_user_id FROM profiles LIMIT 1;
    IF test_user_id IS NULL THEN
        test_user_id := gen_random_uuid();
    END IF;
    
    -- Try insert
    INSERT INTO notifications (
        user_id, type, title, body, data, is_read, created_at
    ) VALUES (
        test_user_id,
        'general',
        'Diagnostic Test',
        'Testing if RLS policies allow insert',
        '{"test": true}'::jsonb,
        false,
        NOW()
    ) RETURNING id INTO test_notification_id;
    
    RAISE NOTICE '✅ INSERT TEST PASSED!';
    RAISE NOTICE '   Notification ID: %', test_notification_id;
    RAISE NOTICE '   Policies are working correctly!';
    
    -- Cleanup
    DELETE FROM notifications WHERE id = test_notification_id;
    RAISE NOTICE '✅ Test notification cleaned up';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ INSERT TEST FAILED!';
        RAISE NOTICE '   Error: %', SQLERRM;
        RAISE NOTICE '   Error Code: %', SQLSTATE;
        RAISE NOTICE '';
        
        IF SQLERRM LIKE '%permission denied%' THEN
            RAISE NOTICE '💡 DIAGNOSIS: Permission denied error';
            RAISE NOTICE '   CAUSE: No INSERT grant or RLS policy blocking';
            RAISE NOTICE '   FIX: Run FIX_NOTIFICATION_RLS_POLICY_V2.sql';
        ELSIF SQLERRM LIKE '%violates row-level security%' THEN
            RAISE NOTICE '💡 DIAGNOSIS: RLS policy violation';
            RAISE NOTICE '   CAUSE: WITH CHECK condition failing';
            RAISE NOTICE '   FIX: Policy needs WITH CHECK (true)';
        ELSIF SQLERRM LIKE '%column%does not exist%' THEN
            RAISE NOTICE '💡 DIAGNOSIS: Schema mismatch';
            RAISE NOTICE '   CAUSE: Column names dont match';
            RAISE NOTICE '   FIX: Check table schema vs insert data';
        ELSE
            RAISE NOTICE '💡 DIAGNOSIS: Unknown error';
            RAISE NOTICE '   Share this error message for analysis';
        END IF;
END $$;

-- ========================================
-- SUMMARY
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  DIAGNOSTIC COMPLETE                                       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'If CHECK 6 failed:';
    RAISE NOTICE '1. Run FIX_NOTIFICATION_RLS_POLICY_V2.sql';
    RAISE NOTICE '2. Run this diagnostic again';
    RAISE NOTICE '3. CHECK 6 should pass after fix';
    RAISE NOTICE '';
    RAISE NOTICE 'If CHECK 6 passed but Flutter still fails:';
    RAISE NOTICE '1. Restart Flutter app completely';
    RAISE NOTICE '2. Check Flutter error message for details';
    RAISE NOTICE '3. Compare table schema with insert data';
    RAISE NOTICE '';
END $$;
