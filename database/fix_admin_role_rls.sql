-- ============================================
-- FIX: Admin Role Detection - RLS Bypass Function
-- ============================================
-- This SQL script fixes the "infinite recursion detected in policy" error
-- that prevents admin users from being correctly identified and redirected
-- to the admin dashboard.
--
-- PROBLEM:
-- - The profiles table has RLS policies that create circular dependencies
-- - When trying to fetch user profile/role, it causes infinite recursion
-- - This causes all users (including admins) to be treated as regular users
--
-- SOLUTION:
-- Create an RPC function that bypasses RLS policies to directly get user role
-- Similar to the existing get_email_by_username function
--
-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard > SQL Editor
-- 2. Copy and paste this entire script
-- 3. Click "Run" to execute
-- 4. Verify the function was created successfully
-- ============================================

-- Drop function if it already exists (for updates)
DROP FUNCTION IF EXISTS get_role_by_user_id(uuid);

-- Create function to get user role by user ID
-- This function runs with SECURITY DEFINER which bypasses RLS policies
CREATE OR REPLACE FUNCTION get_role_by_user_id(input_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_role text;
BEGIN
  -- Get role from profiles table
  SELECT role INTO user_role
  FROM profiles
  WHERE id = input_user_id
  LIMIT 1;
  
  -- Return the role (defaults to 'user' if not found)
  RETURN COALESCE(user_role, 'user');
EXCEPTION
  WHEN OTHERS THEN
    -- If any error occurs, default to 'user' role
    RETURN 'user';
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_role_by_user_id(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_role_by_user_id(uuid) TO anon;

-- ============================================
-- OPTIONAL: Fix the RLS Policy (Recommended)
-- ============================================
-- The root cause is the RLS policy on profiles table.
-- You should also fix the policy to prevent infinite recursion.
--
-- Common causes of infinite recursion in RLS policies:
-- 1. Policy references the same table it's protecting
-- 2. Policy uses a subquery that queries profiles table
-- 3. Policy has circular dependencies
--
-- EXAMPLE FIX:
-- Instead of:
--   CREATE POLICY "Users can read their own profile"
--   ON profiles FOR SELECT
--   USING (auth.uid() = (SELECT id FROM profiles WHERE id = profiles.id));
--
-- Use:
--   CREATE POLICY "Users can read their own profile"
--   ON profiles FOR SELECT
--   USING (auth.uid() = id);
--
-- To view current policies:
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profiles';

-- ============================================
-- VERIFICATION
-- ============================================
-- After running this script, test by calling the function:
-- SELECT get_role_by_user_id('your-user-uuid-here');
--
-- Expected output: 'admin' or 'user'
-- ============================================

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE 'RPC function get_role_by_user_id created successfully!';
  RAISE NOTICE 'You can now test it by running: SELECT get_role_by_user_id(''your-user-uuid'');';
  RAISE NOTICE '';
  RAISE NOTICE 'IMPORTANT: This is a workaround. You should also fix the RLS policies on profiles table.';
  RAISE NOTICE 'Run the verification query above to see current policies and identify the problematic one.';
END $$;
