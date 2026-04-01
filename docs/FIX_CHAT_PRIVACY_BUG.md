# Fix: Chat Privacy Bug - Admin Messages Leaked Between Users

## Problem
When admin chats with User A, the chat history is visible to User B. This is a critical privacy issue where general chat messages (booking_id = NULL) are not properly isolated between users.

## Root Cause
1. The `chat_messages` table lacks a `user_id` column to track which user a conversation belongs to
2. The RLS policy "Users can read general chat" allows ALL users to see ALL messages where `booking_id IS NULL`
3. The `fetchMessages()` function doesn't filter by user for general chat

## Solution

### Step 1: Add `user_id` Column to Database

Run this SQL in Supabase SQL Editor:

```sql
-- Step 0: Add updated_at column (fixes trigger error if trigger exists)
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Step 1: Add user_id column to chat_messages table
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_chat_user ON chat_messages(user_id);

-- Update existing records to set user_id based on sender_id for non-admin messages
UPDATE chat_messages 
SET user_id = sender_id 
WHERE user_id IS NULL AND is_admin = false;

-- For admin messages, we need to determine the user from context
-- This is a one-time migration - you may need to manually review these
UPDATE chat_messages cm
SET user_id = (
  SELECT DISTINCT sender_id 
  FROM chat_messages 
  WHERE booking_id = cm.booking_id 
    AND is_admin = false 
  LIMIT 1
)
WHERE user_id IS NULL AND is_admin = true AND booking_id IS NOT NULL;

-- For general chat admin messages (booking_id IS NULL), 
-- we need to handle manually or accept data loss
-- Option: Delete orphaned admin messages in general chat
DELETE FROM chat_messages 
WHERE user_id IS NULL AND is_admin = true AND booking_id IS NULL;
```

### Step 2: Update RLS Policies

Replace the existing RLS policies with these updated ones:

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Users can read general chat" ON chat_messages;
DROP POLICY IF EXISTS "Users can read booking messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read own messages" ON chat_messages;

-- Updated Policy: Users can read their own messages (by user_id)
CREATE POLICY "Users can read their messages" ON chat_messages
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR 
  sender_id = auth.uid()
);

-- Updated Policy: Users can read messages in their bookings
CREATE POLICY "Users can read booking messages" ON chat_messages
FOR SELECT
TO authenticated
USING (
  booking_id IN (
    SELECT id FROM bookings WHERE user_id = auth.uid()
  )
);

-- Admins can still read all messages
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
```

### Step 3: Update Application Code

The chat service needs to be updated to always set `user_id` when sending messages.

See the updated `lib/services/chat_service.dart` file (changes will be applied automatically).

## Testing

After applying the fix:

1. **Test User A**: Login as User A, send a message in general chat
2. **Test User B**: Login as User B, open general chat
3. **Verify**: User B should NOT see User A's messages
4. **Test Admin**: Login as admin, verify you can see both User A and User B's separate chats

## Verification Queries

Check if the fix is working:

```sql
-- Count messages per user in general chat
SELECT user_id, COUNT(*) as message_count
FROM chat_messages
WHERE booking_id IS NULL
GROUP BY user_id;

-- Verify no messages have NULL user_id
SELECT COUNT(*) FROM chat_messages WHERE user_id IS NULL;
```

## Rollback (if needed)

If you need to rollback this change:

```sql
-- Remove the column
ALTER TABLE chat_messages DROP COLUMN IF EXISTS user_id;

-- Remove the index
DROP INDEX IF EXISTS idx_chat_user;

-- Restore old policy
CREATE POLICY "Users can read general chat" ON chat_messages
FOR SELECT
TO authenticated
USING (booking_id IS NULL);
```
