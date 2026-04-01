-- ================================================================
-- FIX: Update chat_messages table to support general chat
-- ================================================================
-- This script fixes the chat_messages table structure to match
-- the application code requirements:
-- 1. Make booking_id nullable (for general chat support)
-- 2. Add user_id column (for privacy filtering in general chat)
-- 3. Update RLS policies to support both general and booking chat
-- ================================================================

-- STEP 1: Backup your data first (recommended)
-- CREATE TABLE chat_messages_backup AS SELECT * FROM chat_messages;

-- STEP 2: Check if table exists and show current structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'chat_messages'
ORDER BY ordinal_position;

-- STEP 3: Modify booking_id to be nullable (if it exists)
-- This allows general chat where booking_id = NULL
DO $$ 
BEGIN
  -- Check if booking_id column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_messages' AND column_name = 'booking_id'
  ) THEN
    -- Make booking_id nullable
    ALTER TABLE chat_messages 
    ALTER COLUMN booking_id DROP NOT NULL;
    
    RAISE NOTICE '✅ booking_id column is now nullable';
  ELSE
    -- If booking_id doesn't exist, create it as nullable
    ALTER TABLE chat_messages 
    ADD COLUMN booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE;
    
    RAISE NOTICE '✅ booking_id column created as nullable';
  END IF;
END $$;

-- STEP 4: Add user_id column if it doesn't exist
-- This is used for privacy filtering in general chat
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_messages' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE chat_messages 
    ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    
    -- Create index for performance
    CREATE INDEX IF NOT EXISTS idx_chat_user ON chat_messages(user_id);
    
    -- For existing rows, set user_id = sender_id if is_admin = false
    UPDATE chat_messages 
    SET user_id = sender_id 
    WHERE is_admin = false AND user_id IS NULL;
    
    RAISE NOTICE '✅ user_id column added with index';
  ELSE
    RAISE NOTICE '⚠️  user_id column already exists';
  END IF;
END $$;

-- STEP 5: Drop existing RLS policies that might conflict
DO $$ 
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'chat_messages'
  LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON chat_messages';
    RAISE NOTICE 'Dropped policy: %', r.policyname;
  END LOOP;
END $$;

-- STEP 6: Create new RLS policies supporting both general and booking chat

-- Policy 1: Users can read their own messages
CREATE POLICY "Users can read own messages"
ON chat_messages FOR SELECT
USING (auth.uid()::uuid = sender_id);

-- Policy 2: Users can read messages in their bookings
CREATE POLICY "Users can read booking messages"
ON chat_messages FOR SELECT
USING (
  booking_id IS NOT NULL AND
  EXISTS (
    SELECT 1 FROM bookings 
    WHERE bookings.id = chat_messages.booking_id 
    AND bookings.user_id = auth.uid()::uuid
  )
);

-- Policy 3: Users can read general chat messages belonging to them
CREATE POLICY "Users can read their general chat"
ON chat_messages FOR SELECT
USING (
  booking_id IS NULL 
  AND user_id = auth.uid()::uuid
);

-- Policy 4: Admin/Superadmin can read all messages
CREATE POLICY "Admin can read all messages"
ON chat_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()::uuid
    AND profiles.role IN ('admin', 'superadmin')
  )
);

-- Policy 5: Users can send messages (non-admin)
CREATE POLICY "Users can send messages"
ON chat_messages FOR INSERT
WITH CHECK (
  auth.uid()::uuid = sender_id
  AND is_admin = false
  AND (
    -- For general chat: user_id must match sender_id
    (booking_id IS NULL AND user_id = sender_id)
    OR
    -- For booking chat: booking must belong to user
    (booking_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM bookings 
      WHERE bookings.id = booking_id 
      AND bookings.user_id = sender_id
    ))
  )
);

-- Policy 6: Admin can send messages
CREATE POLICY "Admin can send messages"
ON chat_messages FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()::uuid
    AND profiles.role IN ('admin', 'superadmin')
  )
  AND is_admin = true
);

-- Policy 7: Users can mark messages as read
CREATE POLICY "Users can mark messages as read"
ON chat_messages FOR UPDATE
USING (
  auth.uid()::uuid != sender_id
  AND (
    -- Can update their general chat messages
    (booking_id IS NULL AND user_id = auth.uid()::uuid)
    OR
    -- Can update their booking chat messages
    (booking_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM bookings 
      WHERE bookings.id = booking_id 
      AND bookings.user_id = auth.uid()::uuid
    ))
  )
)
WITH CHECK (
  auth.uid()::uuid != sender_id
);

-- Policy 8: Admin can mark all messages as read
CREATE POLICY "Admin can mark messages as read"
ON chat_messages FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()::uuid
    AND profiles.role IN ('admin', 'superadmin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()::uuid
    AND profiles.role IN ('admin', 'superadmin')
  )
);

-- STEP 7: Ensure RLS is enabled
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- STEP 8: Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON chat_messages TO authenticated;

-- STEP 9: Update indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_booking_null ON chat_messages(user_id) WHERE booking_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_chat_booking_not_null ON chat_messages(booking_id) WHERE booking_id IS NOT NULL;

-- ================================================================
-- VERIFICATION
-- ================================================================

-- Show updated table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'chat_messages'
ORDER BY ordinal_position;

-- Show all policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'chat_messages'
ORDER BY policyname;

-- Show RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'chat_messages';

-- Count messages by type
SELECT 
  CASE 
    WHEN booking_id IS NULL THEN 'General Chat'
    ELSE 'Booking Chat'
  END as chat_type,
  COUNT(*) as message_count
FROM chat_messages
GROUP BY chat_type;

-- Success message
DO $$ 
BEGIN
  RAISE NOTICE '═══════════════════════════════════════════════';
  RAISE NOTICE '✅ Chat messages table structure updated!';
  RAISE NOTICE '✅ booking_id is now nullable';
  RAISE NOTICE '✅ user_id column added';
  RAISE NOTICE '✅ RLS policies updated';
  RAISE NOTICE '═══════════════════════════════════════════════';
END $$;
