-- ============================================================
-- NOTIFICATION AUTO-CLEANUP POLICY
-- ============================================================
-- This policy allows the system to delete old notifications
-- Run this in Supabase SQL Editor to enable auto-cleanup
-- ============================================================

-- Check if policy already exists, if yes then drop and recreate
DO $$ 
BEGIN
    -- Drop policy if exists
    DROP POLICY IF EXISTS "System can delete old notifications" ON notifications;
    
    -- Create the policy
    CREATE POLICY "System can delete old notifications"
    ON notifications FOR DELETE
    USING (
        -- Allow deletion of notifications older than 23 hours
        -- (1 hour buffer to ensure 24-hour cleanup doesn't fail)
        created_at < NOW() - INTERVAL '23 hours'
    );
    
    RAISE NOTICE 'Policy created successfully!';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
END $$;

-- ============================================================
-- VERIFICATION
-- ============================================================
-- Check that policy was created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'notifications' 
  AND policyname = 'System can delete old notifications';

-- ============================================================
-- TEST CLEANUP (OPTIONAL)
-- ============================================================
-- Uncomment to test if cleanup works
-- This will delete notifications older than 24 hours

/*
DELETE FROM notifications 
WHERE created_at < NOW() - INTERVAL '24 hours';
*/

-- ============================================================
-- NOTES
-- ============================================================
-- 1. This policy allows deletion of notifications older than 23 hours
-- 2. The 23-hour threshold (instead of 24) provides a buffer zone
-- 3. Auto-cleanup service runs every 6 hours and uses 24-hour cutoff
-- 4. RLS must be enabled on notifications table for this to work
-- 5. Service will automatically delete old notifications in background
-- ============================================================
