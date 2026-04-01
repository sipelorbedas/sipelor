-- ========================================
-- DROP CHAT-RELATED TABLES
-- ========================================
-- Purpose: Remove 9 chat-related tables from Supabase
-- Tables to drop:
--   1. admin_response_times
--   2. chat_analytics
--   3. chat_attachments
--   4. chat_busy_hours
--   5. chat_conversations
--   6. chat_messages
--   7. chat_templates
--   8. chat_typing_indicators
--   9. Most_active_chat_users
-- 
-- ⚠️ WARNING: This will permanently delete all data in these tables!
-- Make sure to backup data if needed before running this script.
-- 
-- How to use:
-- 1. Go to Supabase Dashboard → SQL Editor
-- 2. Copy and paste this entire script
-- 3. Click "Run" or press Ctrl+Enter
-- ========================================

-- Start transaction for safety
BEGIN;

-- ========================================
-- STEP 1: Disable Row Level Security (RLS) on all tables
-- ========================================
DO $$
BEGIN
  -- Disable RLS if tables exist
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'admin_response_times') THEN
    ALTER TABLE admin_response_times DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_analytics') THEN
    ALTER TABLE chat_analytics DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_attachments') THEN
    ALTER TABLE chat_attachments DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_busy_hours') THEN
    ALTER TABLE chat_busy_hours DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_conversations') THEN
    ALTER TABLE chat_conversations DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_messages') THEN
    ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_templates') THEN
    ALTER TABLE chat_templates DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_typing_indicators') THEN
    ALTER TABLE chat_typing_indicators DISABLE ROW LEVEL SECURITY;
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'Most_active_chat_users') THEN
    ALTER TABLE "Most_active_chat_users" DISABLE ROW LEVEL SECURITY;
  END IF;

  RAISE NOTICE '✅ Step 1: RLS disabled on existing tables';
END $$;

-- ========================================
-- STEP 2: Drop all RLS policies
-- ========================================

-- Drop policies for admin_response_times
DROP POLICY IF EXISTS "Admin can read response times" ON admin_response_times;
DROP POLICY IF EXISTS "Admin can insert response times" ON admin_response_times;
DROP POLICY IF EXISTS "Admin can update response times" ON admin_response_times;
DROP POLICY IF EXISTS "Admin can delete response times" ON admin_response_times;

-- Drop policies for chat_analytics
DROP POLICY IF EXISTS "Admin can read analytics" ON chat_analytics;
DROP POLICY IF EXISTS "Admin can insert analytics" ON chat_analytics;
DROP POLICY IF EXISTS "Admin can update analytics" ON chat_analytics;
DROP POLICY IF EXISTS "Admin can delete analytics" ON chat_analytics;

-- Drop policies for chat_attachments
DROP POLICY IF EXISTS "Users can read attachments" ON chat_attachments;
DROP POLICY IF EXISTS "Users can insert attachments" ON chat_attachments;
DROP POLICY IF EXISTS "Users can delete attachments" ON chat_attachments;
DROP POLICY IF EXISTS "Admin can manage attachments" ON chat_attachments;

-- Drop policies for chat_busy_hours
DROP POLICY IF EXISTS "Admin can read busy hours" ON chat_busy_hours;
DROP POLICY IF EXISTS "Admin can insert busy hours" ON chat_busy_hours;
DROP POLICY IF EXISTS "Admin can update busy hours" ON chat_busy_hours;

-- Drop policies for chat_conversations
DROP POLICY IF EXISTS "Users can read conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can insert conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Admin can read all conversations" ON chat_conversations;

-- Drop policies for chat_messages
DROP POLICY IF EXISTS "Users can read their own booking chats" ON chat_messages;
DROP POLICY IF EXISTS "Users and staff can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update read status on their messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read their messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read booking messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read general chat" ON chat_messages;
DROP POLICY IF EXISTS "Admin can read all messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Admin can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can mark messages as read" ON chat_messages;

-- Drop policies for chat_templates
DROP POLICY IF EXISTS "Admin can read templates" ON chat_templates;
DROP POLICY IF EXISTS "Admin can insert templates" ON chat_templates;
DROP POLICY IF EXISTS "Admin can update templates" ON chat_templates;
DROP POLICY IF EXISTS "Admin can delete templates" ON chat_templates;

-- Drop policies for chat_typing_indicators
DROP POLICY IF EXISTS "Users can read typing indicators" ON chat_typing_indicators;
DROP POLICY IF EXISTS "Users can insert typing indicators" ON chat_typing_indicators;
DROP POLICY IF EXISTS "Users can update typing indicators" ON chat_typing_indicators;

-- Drop policies for Most_active_chat_users
DROP POLICY IF EXISTS "Admin can read active users" ON "Most_active_chat_users";
DROP POLICY IF EXISTS "Admin can insert active users" ON "Most_active_chat_users";

DO $$ BEGIN RAISE NOTICE '✅ Step 2: All RLS policies dropped'; END $$;

-- ========================================
-- STEP 3: Drop all indexes
-- ========================================

-- Indexes for admin_response_times
DROP INDEX IF EXISTS idx_admin_response_times_admin_id;
DROP INDEX IF EXISTS idx_admin_response_times_created_at;
DROP INDEX IF EXISTS idx_admin_response_times_booking_id;

-- Indexes for chat_analytics
DROP INDEX IF EXISTS idx_chat_analytics_date;
DROP INDEX IF EXISTS idx_chat_analytics_admin_id;

-- Indexes for chat_attachments
DROP INDEX IF EXISTS idx_chat_attachments_message_id;
DROP INDEX IF EXISTS idx_chat_attachments_conversation_id;
DROP INDEX IF EXISTS idx_chat_attachments_created_at;

-- Indexes for chat_busy_hours
DROP INDEX IF EXISTS idx_chat_busy_hours_hour;
DROP INDEX IF EXISTS idx_chat_busy_hours_day_of_week;

-- Indexes for chat_conversations
DROP INDEX IF EXISTS idx_chat_conversations_user_id;
DROP INDEX IF EXISTS idx_chat_conversations_booking_id;
DROP INDEX IF EXISTS idx_chat_conversations_created_at;
DROP INDEX IF EXISTS idx_chat_conversations_updated_at;

-- Indexes for chat_messages
DROP INDEX IF EXISTS idx_chat_booking;
DROP INDEX IF EXISTS idx_chat_sender;
DROP INDEX IF EXISTS idx_chat_created;
DROP INDEX IF EXISTS idx_chat_unread;
DROP INDEX IF EXISTS idx_chat_messages_conversation_id;
DROP INDEX IF EXISTS idx_chat_messages_sender_id;
DROP INDEX IF EXISTS idx_chat_messages_created_at;

-- Indexes for chat_templates
DROP INDEX IF EXISTS idx_chat_templates_category;
DROP INDEX IF EXISTS idx_chat_templates_is_active;

-- Indexes for chat_typing_indicators
DROP INDEX IF EXISTS idx_chat_typing_indicators_conversation_id;
DROP INDEX IF EXISTS idx_chat_typing_indicators_user_id;

-- Indexes for Most_active_chat_users
DROP INDEX IF EXISTS idx_most_active_chat_users_user_id;
DROP INDEX IF EXISTS idx_most_active_chat_users_message_count;

DO $$ BEGIN RAISE NOTICE '✅ Step 3: All indexes dropped'; END $$;

-- ========================================
-- STEP 4: Remove from Realtime publication
-- ========================================

-- Remove chat_messages from realtime (if it was added)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS chat_messages;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS chat_conversations;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS chat_typing_indicators;
  RAISE NOTICE '✅ Step 4: Tables removed from realtime publication';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Note: Tables may not be in realtime publication';
END $$;

-- ========================================
-- STEP 5: Drop all triggers
-- ========================================

-- Drop triggers for chat_conversations
DROP TRIGGER IF EXISTS update_chat_conversations_updated_at ON chat_conversations;
DROP TRIGGER IF EXISTS update_conversation_last_message ON chat_messages;

-- Drop triggers for chat_analytics
DROP TRIGGER IF EXISTS update_chat_analytics_trigger ON chat_messages;

-- Drop triggers for admin_response_times
DROP TRIGGER IF EXISTS calculate_admin_response_time ON chat_messages;

DO $$ BEGIN RAISE NOTICE '✅ Step 5: All triggers dropped'; END $$;

-- ========================================
-- STEP 6: Drop all tables
-- ========================================

-- Drop tables in correct order (considering foreign key dependencies)
-- Drop dependent tables first, then parent tables

DROP TABLE IF EXISTS admin_response_times CASCADE;
DROP TABLE IF EXISTS chat_analytics CASCADE;
DROP TABLE IF EXISTS chat_attachments CASCADE;
DROP TABLE IF EXISTS chat_busy_hours CASCADE;
DROP TABLE IF EXISTS chat_typing_indicators CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP TABLE IF EXISTS chat_templates CASCADE;
DROP TABLE IF EXISTS "Most_active_chat_users" CASCADE;

DO $$ BEGIN 
  RAISE NOTICE '✅ Dropped all 9 chat tables'; 
END $$;

-- ========================================
-- STEP 7: Verify deletion
-- ========================================

DO $$
DECLARE
  remaining_tables TEXT;
BEGIN
  SELECT string_agg(tablename, ', ')
  INTO remaining_tables
  FROM pg_tables
  WHERE schemaname = 'public'
  AND tablename IN (
    'admin_response_times',
    'chat_analytics',
    'chat_attachments',
    'chat_busy_hours',
    'chat_conversations',
    'chat_messages',
    'chat_templates',
    'chat_typing_indicators',
    'Most_active_chat_users'
  );

  IF remaining_tables IS NULL THEN
    RAISE NOTICE '✅ ✅ ✅ SUCCESS! All 9 chat tables have been deleted.';
  ELSE
    RAISE NOTICE '⚠️  Warning: These tables still exist: %', remaining_tables;
  END IF;
END $$;

-- Commit the transaction
COMMIT;

-- ========================================
-- SUMMARY
-- ========================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║              🎉 CHAT TABLES DELETION COMPLETE              ║';
  RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ ✅ RLS policies removed                                    ║';
  RAISE NOTICE '║ ✅ Indexes dropped                                         ║';
  RAISE NOTICE '║ ✅ Triggers removed                                        ║';
  RAISE NOTICE '║ ✅ Tables removed from realtime                            ║';
  RAISE NOTICE '║ ✅ All 9 tables deleted:                                   ║';
  RAISE NOTICE '║    1. admin_response_times                                 ║';
  RAISE NOTICE '║    2. chat_analytics                                       ║';
  RAISE NOTICE '║    3. chat_attachments                                     ║';
  RAISE NOTICE '║    4. chat_busy_hours                                      ║';
  RAISE NOTICE '║    5. chat_conversations                                   ║';
  RAISE NOTICE '║    6. chat_messages                                        ║';
  RAISE NOTICE '║    7. chat_templates                                       ║';
  RAISE NOTICE '║    8. chat_typing_indicators                               ║';
  RAISE NOTICE '║    9. Most_active_chat_users                               ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  IMPORTANT: If you have Flutter code referencing these';
  RAISE NOTICE '   tables, you may need to update or remove that code.';
  RAISE NOTICE '';
END $$;
