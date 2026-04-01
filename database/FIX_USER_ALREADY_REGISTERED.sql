-- ================================================
-- FIX: User Already Registered Error
-- ================================================
-- Problem: Getting "User already registered" error
-- but user not visible in profiles table
--
-- Root Cause: User exists in auth.users but not in profiles
-- ================================================

-- Step 1: Check auth.users table for the email
-- This shows ALL users in Supabase Auth
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  updated_at,
  last_sign_in_at,
  deleted_at
FROM auth.users
WHERE email = 'goodwin.rama@gmail.com';

-- Expected: You should see the user here even if not in profiles

-- Step 2: Check profiles table
SELECT 
  id,
  email,
  username,
  full_name,
  role,
  created_at
FROM profiles
WHERE email = 'goodwin.rama@gmail.com';

-- If user exists in auth.users but NOT in profiles, 
-- this explains the "already registered" error

-- Step 3: Check for ANY mismatches between auth.users and profiles
SELECT 
  au.id,
  au.email as auth_email,
  au.created_at as auth_created,
  p.email as profile_email,
  p.username,
  p.role,
  CASE 
    WHEN p.id IS NULL THEN 'Missing Profile'
    ELSE 'OK'
  END as status
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
ORDER BY au.created_at DESC;

-- This shows ALL users and highlights missing profiles

-- ================================================
-- SOLUTION OPTIONS
-- ================================================

-- OPTION 1: Delete the user from auth.users (RECOMMENDED for testing)
-- This allows you to re-register with the same email
-- ⚠️ WARNING: This permanently deletes the user account

DELETE FROM auth.users 
WHERE email = 'goodwin.rama@gmail.com';

-- Verify deletion
SELECT COUNT(*) FROM auth.users WHERE email = 'goodwin.rama@gmail.com';
-- Should return 0

-- Now you can signup again with this email

-- ================================================

-- OPTION 2: Create missing profile entry
-- Use this if you want to keep the auth user and just add profile
-- First, get the user ID from auth.users

-- Get user ID
SELECT id FROM auth.users WHERE email = 'goodwin.rama@gmail.com';

-- Insert profile (replace USER_ID_HERE with actual ID from above)
INSERT INTO profiles (id, email, username, full_name, role, created_at, updated_at)
VALUES (
  'USER_ID_HERE',  -- Replace with actual user ID
  'goodwin.rama@gmail.com',
  'rama',
  'rama',
  'user',
  NOW(),
  NOW()
);

-- ================================================

-- OPTION 3: Clean up ALL orphaned auth users
-- This removes all auth.users that don't have profiles
-- ⚠️ USE WITH CAUTION: Review the list first

-- First, see which users would be deleted
SELECT 
  au.id,
  au.email,
  au.created_at,
  'Will be deleted' as action
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- If you're sure, delete them
DELETE FROM auth.users
WHERE id IN (
  SELECT au.id
  FROM auth.users au
  LEFT JOIN profiles p ON au.id = p.id
  WHERE p.id IS NULL
);

-- ================================================
-- PREVENTION: Create trigger to auto-create profiles
-- ================================================
-- This ensures profiles are created whenever auth.users are created

-- Create function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    'user',
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Test the trigger by checking if it exists
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- ================================================
-- VERIFICATION
-- ================================================

-- Count total users
SELECT 
  (SELECT COUNT(*) FROM auth.users) as auth_users,
  (SELECT COUNT(*) FROM profiles) as profiles,
  (SELECT COUNT(*) FROM auth.users au LEFT JOIN profiles p ON au.id = p.id WHERE p.id IS NULL) as orphaned
;

-- Expected: auth_users = profiles, orphaned = 0

-- ================================================
-- SUMMARY
-- ================================================
-- For immediate fix: Use OPTION 1 to delete the user
-- For prevention: Install the trigger at the bottom
-- ================================================
