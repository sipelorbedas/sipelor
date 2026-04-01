-- ========================================
-- SIMPLE CHAT SYSTEM - Database Schema
-- ========================================
-- Purpose: Create a simple chat table for admin-user communication
-- Features:
--   - Direct messaging between users and admin
--   - Real-time updates via Supabase
--   - Read/unread status tracking
--   - Simple and lightweight
-- ========================================

BEGIN;

-- ========================================
-- STEP 1: Create chat_messages table
-- ========================================

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Sender information
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  
  -- Receiver information (optional - for user to admin chats)
  receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Message content
  message TEXT NOT NULL,
  
  -- Status
  is_read BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- STEP 2: Create indexes for performance
-- ========================================

-- Index for fetching user's messages quickly
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver_id ON chat_messages(receiver_id);

-- Index for sorting by time
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- Index for unread messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_unread ON chat_messages(is_read) WHERE is_read = false;

-- Composite index for user-specific queries
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_created ON chat_messages(sender_id, created_at DESC);

-- ========================================
-- STEP 3: Enable Row Level Security (RLS)
-- ========================================

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Admin can read all messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own message read status" ON chat_messages;

-- Policy 1: Users can read their own messages (sent or received)
CREATE POLICY "Users can read their own messages"
ON chat_messages FOR SELECT
USING (
  auth.uid() = sender_id 
  OR auth.uid() = receiver_id
);

-- Policy 2: Admin can read all messages
CREATE POLICY "Admin can read all messages"
ON chat_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.is_active = true
  )
);

-- Policy 3: Authenticated users can send messages
CREATE POLICY "Users can send messages"
ON chat_messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
);

-- Policy 4: Users can update read status on messages sent to them
CREATE POLICY "Users can update their own message read status"
ON chat_messages FOR UPDATE
USING (
  auth.uid() = receiver_id 
  OR EXISTS (
    SELECT 1 FROM staff
    WHERE staff.user_id = auth.uid()
    AND staff.is_active = true
  )
);

-- ========================================
-- STEP 4: Create trigger for updated_at
-- ========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_chat_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS trigger_update_chat_messages_updated_at ON chat_messages;
CREATE TRIGGER trigger_update_chat_messages_updated_at
BEFORE UPDATE ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION update_chat_messages_updated_at();

-- ========================================
-- STEP 5: Enable Realtime
-- ========================================

-- Enable realtime for live chat updates
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- ========================================
-- VERIFICATION
-- ========================================

DO $$
BEGIN
  -- Check if table exists
  IF EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'chat_messages'
  ) THEN
    RAISE NOTICE '✅ Table chat_messages created successfully';
  ELSE
    RAISE NOTICE '❌ Failed to create chat_messages table';
  END IF;
  
  -- Check if RLS is enabled
  IF EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'chat_messages'
    AND rowsecurity = true
  ) THEN
    RAISE NOTICE '✅ Row Level Security enabled';
  ELSE
    RAISE NOTICE '❌ Row Level Security not enabled';
  END IF;
END $$;

COMMIT;

-- ========================================
-- SUMMARY
-- ========================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║         🎉 SIMPLE CHAT SYSTEM SETUP COMPLETE              ║';
  RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ ✅ Table: chat_messages                                    ║';
  RAISE NOTICE '║ ✅ Indexes: 5 performance indexes                          ║';
  RAISE NOTICE '║ ✅ RLS Policies: 4 security policies                       ║';
  RAISE NOTICE '║ ✅ Triggers: updated_at auto-update                        ║';
  RAISE NOTICE '║ ✅ Realtime: Enabled for live chat                         ║';
  RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ Features:                                                  ║';
  RAISE NOTICE '║   • User to Admin messaging                                ║';
  RAISE NOTICE '║   • Admin to User messaging                                ║';
  RAISE NOTICE '║   • Real-time updates                                      ║';
  RAISE NOTICE '║   • Read/Unread status                                     ║';
  RAISE NOTICE '║   • Secure with RLS                                        ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '📱 Next steps:';
  RAISE NOTICE '   1. Create ChatService in Flutter';
  RAISE NOTICE '   2. Create UserChatScreen';
  RAISE NOTICE '   3. Create AdminChatScreen';
  RAISE NOTICE '';
END $$;
