# Fix Chat RLS Policy Error

## Problem
Error message when sending chat messages:
```
[ChatService] Error sending message: PostgrestException(message: new row violates row-level security policy for table "chat_messages", code: 42501, details: , hint: null)
```

## Root Cause
The RLS (Row Level Security) policies on the `chat_messages` table are incorrectly configured. Some policies check the `staff` table for admin permissions, but your application uses the `profiles` table with a `role` column instead.

## Solution

### Option 1: Run the Correct Migration Script (RECOMMENDED)

The file `database_migration_chat.sql` in your project root already has the correct policies that use `profiles.role` instead of the `staff` table.

**Steps:**
1. Open Supabase Dashboard → SQL Editor
2. Copy the entire contents of `database_migration_chat.sql`
3. Run the script
4. Restart your Flutter app

### Option 2: Run Quick Fix SQL (if migration script doesn't work)

If the migration script has issues, use this quick fix SQL:

```sql
-- ============================================
-- QUICK FIX: Chat Messages RLS Policies
-- ============================================

-- Step 1: Drop ALL existing policies on chat_messages
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'chat_messages'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON chat_messages';
    END LOOP;
END $$;

-- Step 2: Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Step 3: Create new simplified policies using PROFILES table

-- Policy 1: Admins can read all messages
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

-- Policy 2: Users can read their own messages
CREATE POLICY "Users can read own messages" ON chat_messages
FOR SELECT
TO authenticated
USING (sender_id = auth.uid());

-- Policy 3: Users can read messages in their bookings
CREATE POLICY "Users can read booking messages" ON chat_messages
FOR SELECT
TO authenticated
USING (
  booking_id IN (
    SELECT id FROM bookings WHERE user_id = auth.uid()
  )
);

-- Policy 4: Users can read general chat (null booking_id)
CREATE POLICY "Users can read general chat" ON chat_messages
FOR SELECT
TO authenticated
USING (booking_id IS NULL);

-- Policy 5: Admins can send messages
CREATE POLICY "Admins can send messages" ON chat_messages
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  AND sender_id = auth.uid()
);

-- Policy 6: Users can send messages
CREATE POLICY "Users can send messages" ON chat_messages
FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND (
    -- Can send to their own bookings
    booking_id IN (
      SELECT id FROM bookings WHERE user_id = auth.uid()
    )
    -- OR can send to general chat
    OR booking_id IS NULL
  )
);

-- Policy 7: Users can mark messages as read
CREATE POLICY "Users can mark messages as read" ON chat_messages
FOR UPDATE
TO authenticated
USING (
  booking_id IN (
    SELECT id FROM bookings WHERE user_id = auth.uid()
  )
  OR booking_id IS NULL
)
WITH CHECK (
  booking_id IN (
    SELECT id FROM bookings WHERE user_id = auth.uid()
  )
  OR booking_id IS NULL
);

-- Policy 8: Admins can update any message
CREATE POLICY "Admins can update messages" ON chat_messages
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Policy 9: Admins can delete messages
CREATE POLICY "Admins can delete messages" ON chat_messages
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Step 4: Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT ON profiles TO authenticated;
GRANT SELECT ON bookings TO authenticated;
```

### Option 3: Verify Admin Role Exists

Make sure your admin user has the correct role in the profiles table:

```sql
-- Check if your user has admin role
SELECT id, username, full_name, role 
FROM profiles 
WHERE id = auth.uid();

-- If role is NULL or 'user', update it to 'admin':
UPDATE profiles 
SET role = 'admin' 
WHERE id = 'YOUR-USER-ID-HERE';
```

## Verification

After applying the fix:

1. Check policies exist:
```sql
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'chat_messages'
ORDER BY policyname;
```

2. Test in your Flutter app:
   - Restart the app
   - Login as admin
   - Try sending a chat message
   - Check console logs for success message

## Troubleshooting

### Error: "profiles.role column does not exist"
Add the role column to profiles table:
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';
UPDATE profiles SET role = 'admin' WHERE id = 'YOUR-ADMIN-USER-ID';
```

### Still getting RLS errors
Temporarily disable RLS to test (NOT for production):
```sql
ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;
```

If this fixes it, the issue is definitely with the policies. Re-enable RLS and apply the correct policies above:
```sql
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
```

## Related Files
- `database_migration_chat.sql` - Complete migration script with correct policies
- `docs/SUPABASE_SQL_SCRIPTS.sql` - OLD script (uses `staff` table, incorrect)
- `docs/SUPABASE_SQL_SCRIPTS_SAFE.sql` - OLD script (uses `staff` table, incorrect)
