-- ========================================
-- SUPABASE SQL FIX SCRIPT FOR RLS POLICIES
-- ========================================
-- Fixes: Chat, Booking, Profile features
-- Run these scripts in Supabase SQL Editor
-- ========================================

-- STEP 1: Backup existing policies (optional but recommended)
-- Copy the output before running DROP commands
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('profiles', 'chat_messages');

-- ========================================
-- STEP 2: Drop existing problematic policies
-- ========================================

-- Drop all possible policy name variations on profiles table
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Admin can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can read basic profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can read profiles for chat" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;

-- Drop all possible policy name variations on chat_messages table
DROP POLICY IF EXISTS "Users can read their messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read booking messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read general chat" ON chat_messages;
DROP POLICY IF EXISTS "Admin can read all messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Admin can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can mark messages as read" ON chat_messages;
DROP POLICY IF EXISTS "Enable read access for all users" ON chat_messages;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON chat_messages;
DROP POLICY IF EXISTS "Enable update for users based on sender" ON chat_messages;

-- ========================================
-- STEP 3: Create new simplified policies for PROFILES table
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

-- Policy 3: Users can insert their own profile (for new registrations)
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy 4: Admin can read all profiles (using simple staff check)
CREATE POLICY "Admin can read all profiles"
ON profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.role IN ('superadmin', 'admin')
  )
);

-- Policy 5: Allow authenticated users to read basic profile info (for chat)
-- This enables users to see sender names in chat without recursion
CREATE POLICY "Authenticated users can read profiles for chat"
ON profiles FOR SELECT
TO authenticated
USING (true);  -- All authenticated users can read all profiles

-- ========================================
-- STEP 4: Create new simplified policies for CHAT_MESSAGES table
-- ========================================

-- Policy 1: Users can read their own messages
CREATE POLICY "Users can read own messages"
ON chat_messages FOR SELECT
USING (
  auth.uid() = sender_id
);

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

-- Policy 3: Users can read general chat (where booking_id is NULL)
CREATE POLICY "Users can read general chat"
ON chat_messages FOR SELECT
USING (
  booking_id IS NULL
);

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

-- Policy 5: Users can send their own messages (non-admin)
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

-- Policy 7: Users can update read status on messages not sent by them
CREATE POLICY "Users can mark messages as read"
ON chat_messages FOR UPDATE
USING (auth.uid() != sender_id)
WITH CHECK (auth.uid() != sender_id);

-- ========================================
-- STEP 5: Verify RLS is enabled
-- ========================================

-- Enable RLS if not already enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 6: Test policies
-- ========================================

-- Test 1: Check if current user can read their profile
SELECT * FROM profiles WHERE id = auth.uid();

-- Test 2: Check if current user can read their messages
SELECT * FROM chat_messages WHERE sender_id = auth.uid();

-- Test 3: Check if current user can read general chat
SELECT * FROM chat_messages WHERE booking_id IS NULL;

-- ========================================
-- STEP 7: Grant permissions to authenticated role
-- ========================================

-- Grant SELECT on profiles to authenticated users
GRANT SELECT ON profiles TO authenticated;

-- Grant SELECT, INSERT, UPDATE on chat_messages to authenticated users
GRANT SELECT, INSERT, UPDATE ON chat_messages TO authenticated;

-- Grant SELECT on bookings to authenticated users (needed for policy checks)
GRANT SELECT ON bookings TO authenticated;

-- Grant SELECT on staff to authenticated users (needed for admin checks)
GRANT SELECT ON staff TO authenticated;

-- ========================================
-- STEP 8: Verify grants
-- ========================================

-- Check table permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name IN ('profiles', 'chat_messages')
AND grantee = 'authenticated';

-- ========================================
-- STEP 8: Create/Replace RPC functions to bypass RLS
-- ========================================

-- Drop function if exists (for clean recreation)
DROP FUNCTION IF EXISTS get_user_profile_data(UUID);

-- Function to get user profile bypassing RLS (for internal use)
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

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_user_profile_data(UUID) TO authenticated;

-- ========================================
-- STEP 9: Fix bookings table policies
-- ========================================

-- Drop all possible policy name variations on bookings table
DROP POLICY IF EXISTS "Users can read own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can insert own bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can read all bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can update bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can update all bookings" ON bookings;
DROP POLICY IF EXISTS "Enable read access for all users" ON bookings;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON bookings;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON bookings;

-- Policy 1: Users can read their own bookings
CREATE POLICY "Users can read own bookings"
ON bookings FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Users can create their own bookings
CREATE POLICY "Users can create own bookings"
ON bookings FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy 3: Users can update their own bookings (limited)
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

-- Enable RLS on bookings
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON bookings TO authenticated;

-- ========================================
-- DEBUGGING QUERIES (if errors still occur)
-- ========================================

-- Show all current policies on profiles
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Show all current policies on chat_messages
SELECT * FROM pg_policies WHERE tablename = 'chat_messages';

-- Show all current policies on bookings
SELECT * FROM pg_policies WHERE tablename = 'bookings';

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');

-- ========================================
-- ROLLBACK (if something goes wrong)
-- ========================================

-- Disable RLS temporarily for debugging (NOT recommended for production!)
-- ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;

-- To re-enable:
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
