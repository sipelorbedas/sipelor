-- ============================================
-- FIX: Booking Update RLS Policy Error
-- ============================================
-- Error: "column f.name does not exist"
-- Cause: RLS policy trying to access non-existent column in fields table
-- Solution: Update policy to use correct column references
--
-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard → SQL Editor
-- 2. Paste and run this script
-- 3. Test by updating a booking status from admin panel
-- ============================================

-- First, let's check what policies exist on bookings table
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
WHERE tablename = 'bookings'
ORDER BY policyname;

-- Drop problematic policies if they exist
-- These are likely using incorrect column references
DROP POLICY IF EXISTS "Admin can update bookings" ON bookings;
DROP POLICY IF EXISTS "Admin can manage bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can update all bookings" ON bookings;

-- Create correct UPDATE policy for admins
-- This policy allows admins to update bookings
-- WITHOUT referencing fields table columns incorrectly
CREATE POLICY "Admin can update all bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (
    -- Check if user is admin from profiles table
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    -- Check if user is admin from profiles table
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Create correct SELECT policy for admins if not exists
DROP POLICY IF EXISTS "Admin can view all bookings" ON bookings;
CREATE POLICY "Admin can view all bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Also ensure users can view their own bookings
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
CREATE POLICY "Users can view their own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Verify the policies are created correctly
SELECT 
    policyname,
    cmd,
    'Created successfully' as status
FROM pg_policies 
WHERE tablename = 'bookings'
AND policyname IN (
    'Admin can update all bookings',
    'Admin can view all bookings',
    'Users can view their own bookings'
);

-- ============================================
-- IMPORTANT: Check for triggers that might cause issues
-- ============================================
-- List all triggers on bookings table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
ORDER BY trigger_name;

-- If you see any trigger with complex logic that references f.name,
-- you'll need to fix that trigger definition as well.
-- Contact database administrator if you see suspicious triggers.

-- ============================================
-- Test the fix
-- ============================================
-- Run this test query to ensure admin can update bookings
-- Replace 'YOUR_ADMIN_USER_ID' and 'YOUR_BOOKING_ID' with actual values

/*
-- Example test (uncomment and modify):
UPDATE bookings
SET status = 'confirmed'
WHERE id = 'YOUR_BOOKING_ID';

-- If this runs without error, the fix is successful!
*/
