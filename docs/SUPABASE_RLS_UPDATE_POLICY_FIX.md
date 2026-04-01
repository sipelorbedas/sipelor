# Supabase RLS Policy Fix - Admin Cannot Update Bookings

## Problem
Admin can change booking status in the UI, but after refresh it reverts back to the original status. The database is not being updated.

## Root Cause
Row Level Security (RLS) policies on the `bookings` table do not allow admin users to UPDATE bookings.

## Solution

### Step 1: Check if UPDATE Policy Exists

1. Go to Supabase Dashboard → Table Editor → `bookings` table
2. Click on "RLS" (Row Level Security) tab
3. Check if there's an UPDATE policy for admins

### Step 2: Create Admin UPDATE Policy

Run this SQL in the Supabase SQL Editor:

```sql
-- Allow admins to update all bookings
CREATE POLICY "Admins can update all bookings"
ON bookings
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
```

### Step 3: Allow Users to Update Their Own Bookings (Optional)

```sql
-- Allow users to update their own bookings (e.g., add notes)
CREATE POLICY "Users can update their own bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

### Step 4: Create Admin INSERT Policy (if needed)

```sql
-- Allow admins to create bookings
CREATE POLICY "Admins can create bookings"
ON bookings
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);
```

### Step 5: Create Admin DELETE Policy (if needed)

```sql
-- Allow admins to delete bookings
CREATE POLICY "Admins can delete bookings"
ON bookings
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);
```

## Complete RLS Setup for Bookings Table

Here's the complete set of policies you should have:

```sql
-- Enable RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 1. SELECT Policies
CREATE POLICY "Admins can view all bookings"
ON bookings FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Users can view their own bookings"
ON bookings FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- 2. INSERT Policies
CREATE POLICY "Admins can create bookings"
ON bookings FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Users can create their own bookings"
ON bookings FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- 3. UPDATE Policies
CREATE POLICY "Admins can update all bookings"
ON bookings FOR UPDATE TO authenticated
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

CREATE POLICY "Users can update their own bookings"
ON bookings FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 4. DELETE Policies
CREATE POLICY "Admins can delete bookings"
ON bookings FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);
```

## Testing

After applying the policies:

1. Restart your Flutter app
2. Login as admin
3. Try to update a booking status
4. Refresh the page
5. Verify the status persists

## Verification Query

Check if the update worked:

```sql
-- Check recent status changes
SELECT 
  id,
  booking_id,
  status,
  updated_at,
  created_at
FROM bookings
ORDER BY updated_at DESC
LIMIT 10;
```

## Check Admin Role

Make sure your admin user has the correct role:

```sql
-- Check your user's role
SELECT id, username, full_name, role
FROM profiles
WHERE id = auth.uid();

-- Update role to admin if needed
UPDATE profiles 
SET role = 'admin' 
WHERE id = 'your-user-id-here';
```

## Common Errors

### Error: "new row violates row-level security policy"
This means the WITH CHECK clause is failing. The admin role check might not be working.

**Solution:**
```sql
-- Temporarily disable RLS to test (NOT for production)
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;

-- Try the update
-- If it works, then it's definitely an RLS issue

-- Re-enable RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
```

### Error: "Update returned no rows"
This means the USING clause is failing. The admin doesn't have permission to select the row for update.

**Solution:**
Make sure both USING and WITH CHECK clauses allow admin access.

## Alternative: Simplified Admin Policy

If the nested query is causing issues, try this simpler approach:

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Admins can update all bookings" ON bookings;

-- Create simpler policy
CREATE POLICY "Admins can update all bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);
```

## Need Help?

If the issue persists:
1. Check Supabase Dashboard → Logs → Postgres Logs
2. Look for "permission denied" or "policy" errors
3. Verify admin role is set correctly
4. Try updating directly in SQL editor to isolate the issue
