# Supabase RLS Policy Fix - Admin Cannot See Bookings

## Problem
Admin dashboard shows 0 bookings even though users have created bookings and uploaded payment proofs. The logs show:
```
📝 [FetchAllBookings] Total bookings in database: 0
```

## Root Cause
Row Level Security (RLS) policies on the `bookings` table may not allow admin users to read all bookings.

## Solution

### Step 1: Check Current RLS Policies

1. Go to Supabase Dashboard → Table Editor → `bookings` table
2. Click on "RLS" (Row Level Security) tab
3. Check if there are SELECT policies enabled

### Step 2: Create Admin SELECT Policy

Run this SQL in the Supabase SQL Editor:

```sql
-- Create policy to allow admins to read all bookings
CREATE POLICY "Admins can view all bookings"
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
```

### Step 3: Allow Users to Read Their Own Bookings

```sql
-- Create policy to allow users to read their own bookings
CREATE POLICY "Users can view their own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (user_id = auth.uid());
```

### Step 4: Verify RLS is Enabled

```sql
-- Enable RLS on bookings table (if not already enabled)
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
```

### Step 5: Check All Required Tables

Make sure similar policies exist for related tables:

#### Payment Proofs Table
```sql
-- Admin can view all payment proofs
CREATE POLICY "Admins can view all payment proofs"
ON payment_proofs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Users can view their own payment proofs
CREATE POLICY "Users can view their own payment proofs"
ON payment_proofs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());
```

#### Profiles Table
```sql
-- Admin can view all profiles
CREATE POLICY "Admins can view all profiles"
ON profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
    AND p.role = 'admin'
  )
  OR id = auth.uid()  -- Users can also view their own profile
);
```

## Testing

After applying the policies:

1. Restart your Flutter app
2. Login as admin
3. Check if bookings appear in the admin dashboard
4. Check console logs for confirmation

## Alternative: Disable RLS (NOT RECOMMENDED for production)

**⚠️ Only use this for development/testing**

```sql
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE payment_proofs DISABLE ROW LEVEL SECURITY;
```

## Verification Query

Run this to see if bookings exist:

```sql
-- Check total bookings
SELECT COUNT(*) as total_bookings FROM bookings;

-- Check bookings with payment proofs
SELECT 
  b.id,
  b.booking_id,
  b.status,
  b.created_at,
  pp.id as payment_proof_id
FROM bookings b
LEFT JOIN payment_proofs pp ON pp.booking_id = b.id
ORDER BY b.created_at DESC
LIMIT 10;
```

## Common Issues

### Issue 1: Infinite Recursion Error
If you see "infinite recursion" in logs, it means RLS policies have circular references. Fix by:
1. Simplifying the policy logic
2. Using direct auth.uid() checks instead of nested subqueries

### Issue 2: Role Column Missing
If the `profiles` table doesn't have a `role` column:
```sql
ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'user';
-- Update admin users
UPDATE profiles SET role = 'admin' WHERE id = 'admin-user-id-here';
```

### Issue 3: Profiles Table Doesn't Exist
Create the profiles table:
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);
```

## Need Help?

If the issue persists after applying these fixes:
1. Check Supabase logs in Dashboard → Logs
2. Enable debug mode in Flutter app
3. Share the complete error message
