-- =====================================================
-- FIX: Update chat messages to have correct user_id
-- =====================================================
-- This script fixes existing chat messages that don't have
-- proper user_id assigned, which causes messages to appear
-- in all user conversations on admin dashboard.
--
-- IMPORTANT: Run this in Supabase SQL Editor
-- =====================================================

-- Step 1: For messages with booking_id, set user_id from bookings table
UPDATE chat_messages cm
SET user_id = b.user_id
FROM bookings b
WHERE cm.booking_id = b.id
  AND cm.user_id IS NULL;

-- Step 2: For general chat messages (booking_id is NULL)
-- Set user_id to sender_id if sender is not admin
UPDATE chat_messages
SET user_id = sender_id
WHERE booking_id IS NULL
  AND user_id IS NULL
  AND is_admin = false;

-- Step 3: For general chat messages sent by admin,
-- we need to find the user from previous messages in the same conversation
-- This is more complex, so we do it case by case

-- First, let's see what messages are still missing user_id
SELECT 
  id,
  booking_id,
  sender_id,
  sender_name,
  is_admin,
  message,
  created_at,
  user_id
FROM chat_messages
WHERE user_id IS NULL
ORDER BY created_at DESC;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check all messages grouped by user_id
SELECT 
  user_id,
  COUNT(*) as message_count,
  COUNT(CASE WHEN is_admin = false THEN 1 END) as user_messages,
  COUNT(CASE WHEN is_admin = true THEN 1 END) as admin_messages
FROM chat_messages
GROUP BY user_id
ORDER BY user_id;

-- Check messages without user_id
SELECT COUNT(*) as messages_without_user_id
FROM chat_messages
WHERE user_id IS NULL;

-- Check a specific conversation
-- Replace 'USER_ID_HERE' with actual user ID
-- SELECT *
-- FROM chat_messages
-- WHERE user_id = 'USER_ID_HERE'
-- ORDER BY created_at;
