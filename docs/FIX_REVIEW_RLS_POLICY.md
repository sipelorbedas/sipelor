# Fix Review Visibility Issue - RLS Policy Update

## Problem
User A creates a review → User A can see it ✅
User B logs in → User B cannot see User A's review ❌

This is caused by Row Level Security (RLS) policies blocking access to reviews created by other users.

## Solution: Update Supabase RLS Policies

### Step 1: Go to Supabase Dashboard
1. Open your Supabase project dashboard
2. Navigate to **Authentication** → **Policies**

### Step 2: Update `reviews` Table Policy

Find the `reviews` table and update/create the following policy:

```sql
-- Policy: Allow all authenticated users to READ all reviews
-- This allows everyone to see all reviews (for public ratings/reviews)

CREATE POLICY "Allow authenticated users to read all reviews"
ON reviews
FOR SELECT
TO authenticated
USING (true);
```

### Step 3: Update `bookings` Table Policy (if needed)

If users still can't see reviews after Step 2, also update bookings policy:

```sql
-- Policy: Allow all authenticated users to READ booking venue_id
-- This is needed for the JOIN query to work

CREATE POLICY "Allow authenticated users to read booking venues"
ON bookings
FOR SELECT
TO authenticated
USING (true);
```

### Step 4: Verify Policies

After creating policies, verify in SQL Editor:

```sql
-- Test as User A
SELECT 
  r.id, 
  r.rating, 
  r.comment,
  b.venue_id
FROM reviews r
INNER JOIN bookings b ON r.booking_id = b.id
WHERE b.venue_id = 'YOUR_VENUE_ID';
-- Should return User A's review

-- Test as User B (different user)
SELECT 
  r.id, 
  r.rating, 
  r.comment,
  b.venue_id
FROM reviews r
INNER JOIN bookings b ON r.booking_id = b.id
WHERE b.venue_id = 'YOUR_VENUE_ID';
-- Should ALSO return User A's review (currently returns 0)
```

## Alternative: Disable RLS (Not Recommended for Production)

If you want to quickly test, you can temporarily disable RLS:

```sql
-- TEMPORARY: Disable RLS on reviews table (NOT for production!)
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- TEMPORARY: Disable RLS on bookings table (NOT for production!)
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
```

⚠️ **Warning**: Disabling RLS removes all security restrictions. Only use for testing!

## Recommended Policy Structure

For a proper review system, you should have:

### Reviews Table:
1. **SELECT (Read)**: Everyone can read all reviews ✅
2. **INSERT (Create)**: Only authenticated users who made the booking
3. **UPDATE**: Only the review creator
4. **DELETE**: Only the review creator or admin

### Bookings Table:
1. **SELECT (Read)**: User can see their own bookings + venue_id visible to all for reviews
2. **INSERT (Create)**: Only authenticated users
3. **UPDATE**: Only booking owner or admin
4. **DELETE**: Only admin

## After Applying Changes

1. Restart your Flutter app (not just hot reload)
2. Test with User A and User B
3. Both users should now see all reviews for the venue

## Troubleshooting

If reviews still don't show after updating policies:

1. Check Supabase logs for policy errors
2. Run the verification SQL queries above
3. Ensure `venue_id` in bookings table is correctly populated
4. Check that `booking_id` in reviews table matches `id` in bookings table

---

**Need Help?** Check Supabase RLS documentation: https://supabase.com/docs/guides/auth/row-level-security
