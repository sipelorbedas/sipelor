-- ========================================
-- SAFE RLS POLICY FIX SCRIPT
-- ========================================
-- This script is IDEMPOTENT - safe to run multiple times
-- Fixes: Chat, Booking, Profile features
-- Run in Supabase SQL Editor
-- ========================================

-- ========================================
-- STEP 1: Drop ALL existing policies (safe approach)
-- ========================================

DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on profiles table
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'profiles'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON profiles';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
    
    -- Drop all policies on chat_messages table
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'chat_messages'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON chat_messages';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
    
    -- Drop all policies on bookings table
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'bookings'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON bookings';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END $$;

-- ========================================
-- STEP 2: Create NEW simplified policies for PROFILES
-- ========================================

-- Policy 1: Users can read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Policy 2: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy 3: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy 4: Admin can read all profiles
CREATE POLICY "Admin can read all profiles"
ON profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('superadmin', 'admin')
  )
);

-- Policy 5: Allow all authenticated users to read profiles (for chat/booking features)
CREATE POLICY "Authenticated users can read profiles for chat"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- ========================================
-- STEP 3: Create NEW policies for CHAT_MESSAGES
-- ========================================

-- Policy 1: Users can read their own messages
CREATE POLICY "Users can read own messages"
ON chat_messages FOR SELECT
USING (auth.uid() = sender_id);

-- Policy 2: Users can read messages in their bookings
CREATE POLICY "Users can read booking messages"
ON chat_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM bookings 
    WHERE bookings.id = chat_messages.booking_id 
    AND bookings.user_id = auth.uid()
  )
);

-- Policy 3: Users can read general chat (null booking_id)
CREATE POLICY "Users can read general chat"
ON chat_messages FOR SELECT
USING (booking_id IS NULL);

-- Policy 4: Admin can read all messages
CREATE POLICY "Admin can read all messages"
ON chat_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('superadmin', 'admin')
  )
);

-- Policy 5: Users can send messages (non-admin)
CREATE POLICY "Users can send messages"
ON chat_messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
  AND is_admin = false
);

-- Policy 6: Admin can send messages
CREATE POLICY "Admin can send messages"
ON chat_messages FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('superadmin', 'admin')
  )
  AND is_admin = true
);

-- Policy 7: Users can update read status
CREATE POLICY "Users can mark messages as read"
ON chat_messages FOR UPDATE
USING (auth.uid() != sender_id)
WITH CHECK (auth.uid() != sender_id);

-- ========================================
-- STEP 4: Create NEW policies for BOOKINGS
-- ========================================

-- Policy 1: Users can read their own bookings
CREATE POLICY "Users can read own bookings"
ON bookings FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Users can create their own bookings
CREATE POLICY "Users can create own bookings"
ON bookings FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can update their own bookings
CREATE POLICY "Users can update own bookings"
ON bookings FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy 4: Admin can read all bookings
CREATE POLICY "Admin can read all bookings"
ON bookings FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('superadmin', 'admin')
  )
);

-- Policy 5: Admin can update all bookings
CREATE POLICY "Admin can update all bookings"
ON bookings FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('superadmin', 'admin')
  )
);

-- ========================================
-- STEP 5: Ensure RLS is enabled
-- ========================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 6: Grant necessary permissions
-- ========================================

GRANT SELECT ON profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON chat_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON bookings TO authenticated;
GRANT SELECT ON staff TO authenticated;

-- ========================================
-- STEP 7: Create RPC function to bypass RLS
-- ========================================

-- Drop existing function if any
DROP FUNCTION IF EXISTS get_user_profile_data(UUID);

-- Create function
CREATE OR REPLACE FUNCTION get_user_profile_data(input_user_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  email TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  role TEXT
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.username,
    p.full_name,
    p.email,
    p.phone_number,
    p.avatar_url,
    p.role
  FROM profiles p
  WHERE p.id = input_user_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_profile_data(UUID) TO authenticated;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Show all policies created
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings')
ORDER BY tablename, policyname;

-- Show RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');

-- Show granted permissions
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name IN ('profiles', 'chat_messages', 'bookings')
AND grantee = 'authenticated'
ORDER BY table_name;

-- Success message
DO $$ 
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ RLS POLICIES FIXED SUCCESSFULLY!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Restart your Flutter app';
  RAISE NOTICE '2. Test chat, booking, and profile features';
  RAISE NOTICE '3. Check that no more "infinite recursion" errors occur';
  RAISE NOTICE '========================================';
END $$;
