-- ========================================
-- DROP CHAT-RELATED TABLES (SAFE VERSION)
-- ========================================
-- Purpose: Remove chat-related tables from Supabase
-- This version only drops tables that actually exist
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

DO $$
DECLARE
  table_count INTEGER := 0;
  tables_dropped TEXT[] := ARRAY[]::TEXT[];
BEGIN
  RAISE NOTICE '════════════════════════════════════════════════════════════';
  RAISE NOTICE '           STARTING CHAT TABLES DELETION PROCESS';
  RAISE NOTICE '════════════════════════════════════════════════════════════';
  RAISE NOTICE '';

  -- ========================================
  -- STEP 1: Check which tables exist
  -- ========================================
  RAISE NOTICE '🔍 Step 1: Checking which tables exist...';
  RAISE NOTICE '';
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'admin_response_times') THEN
    RAISE NOTICE '   ✅ Found: admin_response_times';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: admin_response_times (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_analytics') THEN
    RAISE NOTICE '   ✅ Found: chat_analytics';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_analytics (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_attachments') THEN
    RAISE NOTICE '   ✅ Found: chat_attachments';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_attachments (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_busy_hours') THEN
    RAISE NOTICE '   ✅ Found: chat_busy_hours';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_busy_hours (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_conversations') THEN
    RAISE NOTICE '   ✅ Found: chat_conversations';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_conversations (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_messages') THEN
    RAISE NOTICE '   ✅ Found: chat_messages';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_messages (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_templates') THEN
    RAISE NOTICE '   ✅ Found: chat_templates';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_templates (does not exist)';
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_typing_indicators') THEN
    RAISE NOTICE '   ✅ Found: chat_typing_indicators';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: chat_typing_indicators (does not exist)';
  END IF;
  
  -- Check both variations of Most_active_chat_users (case-sensitive)
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'Most_active_chat_users') THEN
    RAISE NOTICE '   ✅ Found: Most_active_chat_users';
    table_count := table_count + 1;
  ELSIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'most_active_chat_users') THEN
    RAISE NOTICE '   ✅ Found: most_active_chat_users (lowercase)';
    table_count := table_count + 1;
  ELSE
    RAISE NOTICE '   ⏭️  Skipped: Most_active_chat_users (does not exist)';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '📊 Summary: Found % table(s) to delete', table_count;
  RAISE NOTICE '';
  
  IF table_count = 0 THEN
    RAISE NOTICE '✅ No chat tables found. Nothing to delete.';
    RAISE NOTICE '';
    RETURN;
  END IF;

  -- ========================================
  -- STEP 2: Disable RLS and drop policies
  -- ========================================
  RAISE NOTICE '🔓 Step 2: Disabling RLS and dropping policies...';
  
  -- admin_response_times
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'admin_response_times') THEN
    ALTER TABLE admin_response_times DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admin can read response times" ON admin_response_times;
    DROP POLICY IF EXISTS "Admin can insert response times" ON admin_response_times;
    DROP POLICY IF EXISTS "Admin can update response times" ON admin_response_times;
    DROP POLICY IF EXISTS "Admin can delete response times" ON admin_response_times;
  END IF;

  -- chat_analytics
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_analytics') THEN
    ALTER TABLE chat_analytics DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admin can read analytics" ON chat_analytics;
    DROP POLICY IF EXISTS "Admin can insert analytics" ON chat_analytics;
    DROP POLICY IF EXISTS "Admin can update analytics" ON chat_analytics;
    DROP POLICY IF EXISTS "Admin can delete analytics" ON chat_analytics;
  END IF;

  -- chat_attachments
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_attachments') THEN
    ALTER TABLE chat_attachments DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can read attachments" ON chat_attachments;
    DROP POLICY IF EXISTS "Users can insert attachments" ON chat_attachments;
    DROP POLICY IF EXISTS "Users can delete attachments" ON chat_attachments;
    DROP POLICY IF EXISTS "Admin can manage attachments" ON chat_attachments;
  END IF;

  -- chat_busy_hours
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_busy_hours') THEN
    ALTER TABLE chat_busy_hours DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admin can read busy hours" ON chat_busy_hours;
    DROP POLICY IF EXISTS "Admin can insert busy hours" ON chat_busy_hours;
    DROP POLICY IF EXISTS "Admin can update busy hours" ON chat_busy_hours;
  END IF;

  -- chat_conversations
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_conversations') THEN
    ALTER TABLE chat_conversations DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can read conversations" ON chat_conversations;
    DROP POLICY IF EXISTS "Users can insert conversations" ON chat_conversations;
    DROP POLICY IF EXISTS "Users can update conversations" ON chat_conversations;
    DROP POLICY IF EXISTS "Admin can read all conversations" ON chat_conversations;
  END IF;

  -- chat_messages
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_messages') THEN
    ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;
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
  END IF;

  -- chat_templates
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_templates') THEN
    ALTER TABLE chat_templates DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admin can read templates" ON chat_templates;
    DROP POLICY IF EXISTS "Admin can insert templates" ON chat_templates;
    DROP POLICY IF EXISTS "Admin can update templates" ON chat_templates;
    DROP POLICY IF EXISTS "Admin can delete templates" ON chat_templates;
  END IF;

  -- chat_typing_indicators
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_typing_indicators') THEN
    ALTER TABLE chat_typing_indicators DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Users can read typing indicators" ON chat_typing_indicators;
    DROP POLICY IF EXISTS "Users can insert typing indicators" ON chat_typing_indicators;
    DROP POLICY IF EXISTS "Users can update typing indicators" ON chat_typing_indicators;
  END IF;

  -- Most_active_chat_users (check both cases)
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'Most_active_chat_users') THEN
    EXECUTE 'ALTER TABLE "Most_active_chat_users" DISABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Admin can read active users" ON "Most_active_chat_users"';
    EXECUTE 'DROP POLICY IF EXISTS "Admin can insert active users" ON "Most_active_chat_users"';
  ELSIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'most_active_chat_users') THEN
    ALTER TABLE most_active_chat_users DISABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admin can read active users" ON most_active_chat_users;
    DROP POLICY IF EXISTS "Admin can insert active users" ON most_active_chat_users;
  END IF;

  RAISE NOTICE '   ✅ RLS disabled and policies dropped';

  -- ========================================
  -- STEP 3: Remove from Realtime
  -- ========================================
  RAISE NOTICE '📡 Step 3: Removing from realtime publication...';
  
  -- Remove chat_messages from realtime if it exists in the table
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_messages') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime DROP TABLE chat_messages;
    EXCEPTION
      WHEN OTHERS THEN
        -- Table might not be in publication, that's okay
        NULL;
    END;
  END IF;
  
  -- Remove chat_conversations from realtime if it exists in the table
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_conversations') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime DROP TABLE chat_conversations;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;
  
  -- Remove chat_typing_indicators from realtime if it exists in the table
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_typing_indicators') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime DROP TABLE chat_typing_indicators;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;
  
  RAISE NOTICE '   ✅ Realtime publication updated';

  -- ========================================
  -- STEP 4: Drop triggers
  -- ========================================
  RAISE NOTICE '⚙️  Step 4: Dropping triggers...';
  
  DROP TRIGGER IF EXISTS update_chat_conversations_updated_at ON chat_conversations;
  DROP TRIGGER IF EXISTS update_conversation_last_message ON chat_messages;
  DROP TRIGGER IF EXISTS update_chat_analytics_trigger ON chat_messages;
  DROP TRIGGER IF EXISTS calculate_admin_response_time ON chat_messages;
  
  RAISE NOTICE '   ✅ Triggers dropped';

  -- ========================================
  -- STEP 5: Drop all tables
  -- ========================================
  RAISE NOTICE '🗑️  Step 5: Dropping tables...';
  RAISE NOTICE '';
  
  -- Drop in order (dependencies first)
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'admin_response_times') THEN
    DROP TABLE admin_response_times CASCADE;
    RAISE NOTICE '   ✅ Dropped: admin_response_times';
    tables_dropped := array_append(tables_dropped, 'admin_response_times');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_analytics') THEN
    DROP TABLE chat_analytics CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_analytics';
    tables_dropped := array_append(tables_dropped, 'chat_analytics');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_attachments') THEN
    DROP TABLE chat_attachments CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_attachments';
    tables_dropped := array_append(tables_dropped, 'chat_attachments');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_busy_hours') THEN
    DROP TABLE chat_busy_hours CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_busy_hours';
    tables_dropped := array_append(tables_dropped, 'chat_busy_hours');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_typing_indicators') THEN
    DROP TABLE chat_typing_indicators CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_typing_indicators';
    tables_dropped := array_append(tables_dropped, 'chat_typing_indicators');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_messages') THEN
    DROP TABLE chat_messages CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_messages';
    tables_dropped := array_append(tables_dropped, 'chat_messages');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_conversations') THEN
    DROP TABLE chat_conversations CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_conversations';
    tables_dropped := array_append(tables_dropped, 'chat_conversations');
  END IF;
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_templates') THEN
    DROP TABLE chat_templates CASCADE;
    RAISE NOTICE '   ✅ Dropped: chat_templates';
    tables_dropped := array_append(tables_dropped, 'chat_templates');
  END IF;
  
  -- Handle Most_active_chat_users (both cases)
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'Most_active_chat_users') THEN
    EXECUTE 'DROP TABLE "Most_active_chat_users" CASCADE';
    RAISE NOTICE '   ✅ Dropped: Most_active_chat_users';
    tables_dropped := array_append(tables_dropped, 'Most_active_chat_users');
  ELSIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'most_active_chat_users') THEN
    DROP TABLE most_active_chat_users CASCADE;
    RAISE NOTICE '   ✅ Dropped: most_active_chat_users';
    tables_dropped := array_append(tables_dropped, 'most_active_chat_users');
  END IF;

  -- ========================================
  -- SUMMARY
  -- ========================================
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║         🎉 CHAT TABLES DELETION COMPLETED                  ║';
  RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ Deleted % table(s):', array_length(tables_dropped, 1);
  
  IF array_length(tables_dropped, 1) > 0 THEN
    RAISE NOTICE '║                                                            ║';
    FOR i IN 1..array_length(tables_dropped, 1) LOOP
      RAISE NOTICE '║   %. %', i, rpad(tables_dropped[i], 50);
    END LOOP;
  END IF;
  
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  IMPORTANT: Update Flutter code if it references these tables';
  RAISE NOTICE '';
  
END $$;

-- Commit the transaction
COMMIT;
