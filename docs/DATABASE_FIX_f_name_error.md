# Database Fix: Column f.name Does Not Exist Error

## Problem Description

When updating booking status in the admin dashboard, the following error occurs:

```
PostgrestException(message: column f.name does not exist, code: 42703, details: , hint: Perhaps you meant to reference the column "v.name".)
```

## Root Cause

This error is caused by a **database-side RLS (Row Level Security) policy or trigger** that incorrectly references a non-existent column in the `fields` table.

The database policy is trying to access `f.name` (where `f` is an alias for the `fields` table), but the `fields` table does not have a `name` column. The database hint suggests using `v.name` (where `v` is an alias for the `venues` table) instead.

## Database Schema

### Fields Table
The `fields` table has columns like:
- `id`
- `venue_id`
- `venue_name`
- `area`
- `venue_type`
- etc.

**NOTE:** There is NO `name` column in the `fields` table!

### Venues Table  
The `venues` table has:
- `id`
- `name` ✓
- etc.

## Solution

You need to fix the RLS policy or trigger on the **`bookings`** table that is referencing the incorrect column.

### Step 1: Find the Problematic Policy

Connect to your Supabase/PostgreSQL database and run:

```sql
-- List all policies on the bookings table
SELECT * FROM pg_policies WHERE tablename = 'bookings';

-- Or check triggers
SELECT * FROM pg_trigger WHERE tgrelid = 'bookings'::regclass;
```

### Step 2: Look for References to `f.name`

Search for policies or triggers that contain joins with the `fields` table and reference `f.name`. Example of problematic code:

```sql
-- WRONG ❌
CREATE POLICY "update_booking_policy" ON bookings
FOR UPDATE
USING (
  auth.uid() IN (
    SELECT user_id FROM profiles WHERE role = 'admin'
  ) OR
  EXISTS (
    SELECT 1 
    FROM fields f
    JOIN venues v ON f.venue_id = v.id
    WHERE f.id = bookings.field_id
    AND f.name = 'something'  -- ❌ WRONG! fields table has no 'name' column
  )
);
```

### Step 3: Fix the Policy

Replace `f.name` with the correct column reference:

```sql
-- CORRECT ✓
CREATE POLICY "update_booking_policy" ON bookings
FOR UPDATE
USING (
  auth.uid() IN (
    SELECT user_id FROM profiles WHERE role = 'admin'
  ) OR
  EXISTS (
    SELECT 1 
    FROM fields f
    JOIN venues v ON f.venue_id = v.id
    WHERE f.id = bookings.field_id
    AND v.name = 'something'  -- ✓ CORRECT! Use venues.name
    -- OR use f.venue_name = 'something' if you want from fields table
  )
);
```

### Common Fixes:

1. **If you need venue name:** Use `v.name` (from venues table)
2. **If you need field area:** Use `f.area` (from fields table)  
3. **If you need venue name from fields:** Use `f.venue_name` (from fields table)

## Testing the Fix

After updating the policy, test by:

1. Going to the admin dashboard desktop
2. Try updating a booking status
3. The error should be resolved

## Additional Commands

```sql
-- Drop old policy (replace policy_name)
DROP POLICY IF EXISTS "update_booking_policy" ON bookings;

-- Create new corrected policy
CREATE POLICY "update_booking_policy" ON bookings
FOR UPDATE
USING (
  -- Your corrected policy logic here
);

-- Verify the policy was created
SELECT * FROM pg_policies WHERE tablename = 'bookings' AND policyname = 'update_booking_policy';
```

## Related Files

- Flutter Code: `lib/services/supabase_service.dart` (updateBookingStatus function)
- Admin UI: `lib/screens/admin_dashboard_desktop_screen.dart`
- Widget: `lib/widgets/admin/recent_booking_table.dart`

## Notes

- This is a **database-side issue** and cannot be fixed from the Flutter/Dart code
- The Flutter app has been updated to show a clearer error message when this occurs
- Contact your database administrator or Supabase project owner to fix the RLS policies
