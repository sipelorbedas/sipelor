-- =====================================================
-- DEBUG SQL QUERIES FOR REVIEWS RLS INVESTIGATION
-- =====================================================
-- Run these queries in Supabase SQL Editor to diagnose
-- why reviews are not being fetched properly
-- =====================================================

-- =====================================================
-- TEST 1: Check RLS Policies on Reviews Table
-- =====================================================
-- This shows all RLS policies on the reviews table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'reviews';

-- Expected: Should show all RLS policies currently active
-- If policies are too restrictive, they might block access


-- =====================================================
-- TEST 2: Direct Access to Reviews Table (Basic Test)
-- =====================================================
-- Test if current user can access reviews table at all
SELECT 
    COUNT(*) as total_reviews,
    COUNT(DISTINCT booking_id) as unique_bookings,
    COUNT(DISTINCT user_id) as unique_users,
    MIN(created_at) as oldest_review,
    MAX(created_at) as newest_review
FROM reviews;

-- Expected: Should return counts without errors
-- If error occurs: RLS is blocking even basic SELECT access


-- =====================================================
-- TEST 3: Sample Booking IDs from Reviews
-- =====================================================
-- Get first 10 booking_ids that have reviews
SELECT 
    r.id as review_id,
    r.booking_id,
    r.user_id,
    r.rating,
    r.created_at,
    r.comment IS NOT NULL as has_comment
FROM reviews r
ORDER BY r.created_at DESC
LIMIT 10;

-- Expected: Should show actual booking_ids that have reviews
-- Use these booking_ids to verify bookings table has matching records


-- =====================================================
-- TEST 4: Check if Bookings Exist for Reviews
-- =====================================================
-- Verify that bookings exist for the booking_ids in reviews
SELECT 
    r.booking_id,
    r.rating,
    CASE 
        WHEN b.booking_id IS NOT NULL THEN 'EXISTS'
        ELSE 'MISSING'
    END as booking_exists,
    b.field_id,
    b.venue_id,
    b.booking_date,
    b.status
FROM reviews r
LEFT JOIN bookings b ON r.booking_id::text = b.booking_id::text
LIMIT 10;

-- Expected: booking_exists should be 'EXISTS' for all rows
-- If 'MISSING': orphaned reviews (bookings were deleted)
-- Check field_id and venue_id values


-- =====================================================
-- TEST 5: Field IDs Associated with Reviews
-- =====================================================
-- Get all unique field_ids that have reviews
SELECT 
    b.field_id,
    f.venue_name as field_name,
    f.venue_id,
    v.name as venue_name,
    COUNT(r.id) as review_count,
    AVG(r.rating) as avg_rating
FROM reviews r
INNER JOIN bookings b ON r.booking_id::text = b.booking_id::text
LEFT JOIN fields f ON b.field_id::text = f.id::text
LEFT JOIN venues v ON f.venue_id::text = v.id::text
GROUP BY b.field_id, f.venue_name, f.venue_id, v.name
ORDER BY review_count DESC;

-- Expected: Should show field_ids that have reviews
-- Compare these field_ids with what you're searching for
-- If no results: INNER JOIN is being blocked by RLS


-- =====================================================
-- TEST 6: Venue IDs Associated with Reviews
-- =====================================================
-- Get all unique venue_ids that have reviews (via bookings)
SELECT 
    b.venue_id,
    v.name as venue_name,
    COUNT(DISTINCT r.id) as review_count,
    COUNT(DISTINCT b.booking_id) as booking_count,
    AVG(r.rating)::NUMERIC(3,2) as avg_rating,
    MAX(r.created_at) as latest_review
FROM reviews r
INNER JOIN bookings b ON r.booking_id::text = b.booking_id::text
LEFT JOIN venues v ON b.venue_id::text = v.id::text
WHERE b.venue_id IS NOT NULL
GROUP BY b.venue_id, v.name
ORDER BY review_count DESC;

-- Expected: Should show venue_ids that have reviews
-- Compare with venue_id you're trying to fetch reviews for


-- =====================================================
-- TEST 7: Left Join Test (Less Restrictive)
-- =====================================================
-- Test if LEFT JOIN allows access where INNER JOIN doesn't
SELECT 
    r.id as review_id,
    r.booking_id,
    r.rating,
    r.user_id,
    b.booking_id IS NOT NULL as booking_accessible,
    b.field_id,
    b.venue_id
FROM reviews r
LEFT JOIN bookings b ON r.booking_id::text = b.booking_id::text
ORDER BY r.created_at DESC
LIMIT 10;

-- Expected: Should return reviews even if bookings are NULL
-- If booking_accessible is FALSE: RLS on bookings blocks the join
-- If no results at all: RLS on reviews blocks even LEFT JOIN


-- =====================================================
-- TEST 8: Test Specific Venue ID (Replace with your venue_id)
-- =====================================================
-- INSTRUCTIONS: 
-- 1. First, get a valid venue_id from TEST 6 results above
-- 2. Replace 'YOUR_VENUE_ID_HERE' in the query below with actual venue_id
-- 3. Uncomment the query and run it

-- Query to test a specific venue (UNCOMMENT AND REPLACE VENUE_ID):
/*
SELECT 
    f.id as field_id,
    f.venue_name as field_name,
    f.venue_id,
    COUNT(b.booking_id) as booking_count,
    COUNT(r.id) as review_count,
    AVG(r.rating)::NUMERIC(3,2) as avg_rating
FROM fields f
LEFT JOIN bookings b ON f.id::text = b.field_id::text
LEFT JOIN reviews r ON b.booking_id::text = r.booking_id::text
WHERE f.venue_id::text = 'YOUR_VENUE_ID_HERE'
GROUP BY f.id, f.venue_name, f.venue_id
ORDER BY review_count DESC;
*/

-- Alternative: Get ALL venues with their review counts (no need to replace anything)
SELECT 
    v.id as venue_id,
    v.name as venue_name,
    COUNT(DISTINCT f.id) as field_count,
    COUNT(DISTINCT b.booking_id) as booking_count,
    COUNT(DISTINCT r.id) as review_count,
    AVG(r.rating)::NUMERIC(3,2) as avg_rating
FROM venues v
LEFT JOIN fields f ON v.id::text = f.venue_id::text
LEFT JOIN bookings b ON f.id::text = b.field_id::text
LEFT JOIN reviews r ON b.booking_id::text = r.booking_id::text
GROUP BY v.id, v.name
HAVING COUNT(r.id) > 0  -- Only show venues with reviews
ORDER BY review_count DESC;


-- =====================================================
-- TEST 9: Check RLS Policies on Related Tables
-- =====================================================
-- Check RLS policies on bookings and fields tables too
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual AS using_expression,
    with_check AS with_check_expression
FROM pg_policies 
WHERE tablename IN ('reviews', 'bookings', 'fields', 'venues')
ORDER BY tablename, policyname;

-- Expected: Shows all RLS policies that might affect the join
-- Look for policies that restrict SELECT on foreign key columns


-- =====================================================
-- TEST 10: Test Current User's Access Level
-- =====================================================
-- Check what role the current user has
SELECT 
    current_user as postgres_user,
    auth.uid() as supabase_user_id,
    auth.jwt() ->> 'role' as jwt_role,
    (SELECT role FROM profiles WHERE id = auth.uid()) as profile_role;

-- Expected: Shows the current user's authentication info
-- Helps understand which RLS policies apply to current user


-- =====================================================
-- TEST 11: Reviews with Full Profile and Field Info
-- =====================================================
-- Comprehensive query with all joins (similar to app query)
SELECT 
    r.id,
    r.booking_id,
    r.user_id,
    r.rating,
    r.comment,
    r.created_at,
    p.full_name as reviewer_name,
    p.avatar_url as reviewer_avatar,
    b.booking_date,
    b.field_id,
    b.venue_id,
    f.venue_name as field_name,
    v.name as venue_name
FROM reviews r
LEFT JOIN profiles p ON r.user_id::text = p.id::text
LEFT JOIN bookings b ON r.booking_id::text = b.booking_id::text
LEFT JOIN fields f ON b.field_id::text = f.id::text
LEFT JOIN venues v ON b.venue_id::text = v.id::text
ORDER BY r.created_at DESC
LIMIT 10;

-- Expected: Should show full review data with all related info
-- If columns are NULL: those joins are being blocked by RLS
-- If no results: reviews table itself is blocked


-- =====================================================
-- TEST 12: Count Reviews by Table Join Success
-- =====================================================
-- Statistical analysis of join success rates
SELECT 
    COUNT(*) as total_reviews,
    COUNT(b.booking_id) as reviews_with_bookings,
    COUNT(f.id) as reviews_with_fields,
    COUNT(v.id) as reviews_with_venues,
    COUNT(*) - COUNT(b.booking_id) as orphaned_reviews,
    ROUND(100.0 * COUNT(b.booking_id) / COUNT(*), 2) as booking_match_rate,
    ROUND(100.0 * COUNT(f.id) / COUNT(*), 2) as field_match_rate,
    ROUND(100.0 * COUNT(v.id) / COUNT(*), 2) as venue_match_rate
FROM reviews r
LEFT JOIN bookings b ON r.booking_id::text = b.booking_id::text
LEFT JOIN fields f ON b.field_id::text = f.id::text
LEFT JOIN venues v ON f.venue_id::text = v.id::text;

-- Expected: Match rates should be close to 100%
-- Low match rates indicate:
-- - RLS blocking joins
-- - Missing foreign key data
-- - Orphaned records


-- =====================================================
-- TEST 13: Verify Foreign Key Relationships
-- =====================================================
-- Check if foreign key constraints exist and are valid
SELECT
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN ('reviews', 'bookings', 'fields');

-- Expected: Should show foreign key relationships
-- Helps verify that database structure is correct


-- =====================================================
-- TEST 14: Test INNER JOIN vs LEFT JOIN Performance
-- =====================================================
-- Compare results between INNER and LEFT joins
WITH inner_results AS (
    SELECT COUNT(*) as inner_count
    FROM reviews r
    INNER JOIN bookings b ON r.booking_id::text = b.booking_id::text
),
left_results AS (
    SELECT COUNT(*) as left_count
    FROM reviews r
    LEFT JOIN bookings b ON r.booking_id::text = b.booking_id::text
)
SELECT 
    i.inner_count,
    l.left_count,
    l.left_count - i.inner_count as difference,
    CASE 
        WHEN i.inner_count = 0 AND l.left_count > 0 THEN 'RLS blocks INNER JOIN'
        WHEN i.inner_count = l.left_count THEN 'All reviews have bookings'
        ELSE 'Some reviews missing bookings'
    END as diagnosis
FROM inner_results i, left_results l;

-- Expected: Helps identify if INNER JOIN is the problem
-- If difference is large: INNER JOIN is being blocked


-- =====================================================
-- RECOMMENDED SOLUTIONS
-- =====================================================
-- Based on test results, apply appropriate fix:

-- SOLUTION 1: If RLS is too restrictive on reviews table
-- ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
-- 
-- DROP POLICY IF EXISTS "Users can view all reviews" ON reviews;
-- CREATE POLICY "Users can view all reviews" ON reviews
--     FOR SELECT
--     USING (true); -- Allow all authenticated users to read reviews
--
-- DROP POLICY IF EXISTS "Users can insert their own reviews" ON reviews;
-- CREATE POLICY "Users can insert their own reviews" ON reviews
--     FOR INSERT
--     WITH CHECK (auth.uid() = user_id);
--
-- DROP POLICY IF EXISTS "Users can update their own reviews" ON reviews;
-- CREATE POLICY "Users can update their own reviews" ON reviews
--     FOR UPDATE
--     USING (auth.uid() = user_id);
--
-- DROP POLICY IF EXISTS "Users can delete their own reviews" ON reviews;
-- CREATE POLICY "Users can delete their own reviews" ON reviews
--     FOR DELETE
--     USING (auth.uid() = user_id);


-- SOLUTION 2: If RLS on bookings blocks joins
-- CREATE POLICY "Authenticated users can view bookings for reviews" ON bookings
--     FOR SELECT
--     USING (
--         auth.role() = 'authenticated' AND
--         (
--             user_id = auth.uid() OR
--             EXISTS (
--                 SELECT 1 FROM reviews 
--                 WHERE reviews.booking_id::text = bookings.booking_id::text
--             )
--         )
--     );


-- SOLUTION 3: If venue_id is NULL in bookings
-- First check which bookings have NULL venue_id:
-- SELECT booking_id, field_id, venue_id 
-- FROM bookings 
-- WHERE venue_id IS NULL 
-- LIMIT 10;
--
-- Then update them (if fields have venue_id):
-- UPDATE bookings b
-- SET venue_id = f.venue_id
-- FROM fields f
-- WHERE b.field_id::text = f.id::text
--   AND b.venue_id IS NULL
--   AND f.venue_id IS NOT NULL;


-- =====================================================
-- INSTRUCTIONS
-- =====================================================
-- 1. Run tests 1-14 in order
-- 2. Note which tests fail or return unexpected results
-- 3. Share the results to identify the root cause
-- 4. Apply appropriate solution from above
-- 5. Retest after applying fixes
-- =====================================================
