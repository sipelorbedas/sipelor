-- ================================================
-- CHAT PRIVACY FIX - SQL MIGRATION
-- ================================================
-- Purpose: Fix privacy bug where admin messages to User A are visible to User B
-- Problem: General chat (booking_id = NULL) shows all admin messages to all users
-- Solution: Add user_id column to track conversation ownership
-- Run this SQL in Supabase SQL Editor
-- ================================================

-- Step 0: Add updated_at column (required by trigger if it exists)
-- This prevents the "record has no field updated_at" error
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Step 1: Add user_id column to chat_messages table
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Step 2: Create index for performance
CREATE INDEX IF NOT EXISTS idx_chat_user ON chat_messages(user_id);

-- Step 3: Data Migration - Update existing records
-- For user messages: user_id = sender_id (user talking to admin)
UPDATE chat_messages 
SET user_id = sender_id 
WHERE user_id IS NULL AND is_admin = false;

-- For admin messages in bookings: find user from booking
UPDATE chat_messages cm
SET user_id = (
  SELECT user_id 
  FROM bookings 
  WHERE bookings.id = cm.booking_id
  LIMIT 1
)
WHERE user_id IS NULL AND is_admin = true AND booking_id IS NOT NULL;

-- Step 4: Clean up orphaned admin messages in general chat
-- These are admin messages with no user context (should not exist in production)
DELETE FROM chat_messages 
WHERE user_id IS NULL AND is_admin = true AND booking_id IS NULL;

-- Step 5: Update RLS Policies for Security
-- Drop the vulnerable policy that allows all users to see all general chat
DROP POLICY IF EXISTS "Users can read general chat" ON chat_messages;

-- Create secure policy that filters by user_id
CREATE POLICY "Users can read their messages" ON chat_messages
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR 
  sender_id = auth.uid()
);

-- Ensure admins can still read all messages
DROP POLICY IF EXISTS "Admins can read all messages" ON chat_messages;

CREATE POLICY "Admins can read all messages" ON chat_messages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'admin'
  )
);

-- Step 6: Verification queries
-- Check that all messages now have user_id
SELECT COUNT(*) as orphaned_messages 
FROM chat_messages 
WHERE user_id IS NULL;
-- Should return 0

-- Count messages per user in general chat
SELECT user_id, COUNT(*) as message_count
FROM chat_messages
WHERE booking_id IS NULL
GROUP BY user_id;

-- Verify RLS policies are active
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'chat_messages'
ORDER BY policyname;

-- ================================================
-- Migration Complete!
-- ================================================
-- Now test:
-- 1. Login as User A, send a message in general chat
-- 2. Login as User B, open general chat
-- 3. Verify: User B should NOT see User A's messages
-- 4. Login as Admin
-- 5. Verify: Admin can see separate chats for each user
-- ================================================
