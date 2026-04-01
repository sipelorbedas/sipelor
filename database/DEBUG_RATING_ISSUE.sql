-- ============================================
-- DEBUG: Rating Not Showing on Venue Cards
-- ============================================
-- Run these queries in Supabase SQL Editor to diagnose the issue
-- ============================================

-- STEP 1: Check if fields table has venue_id populated
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔍 STEP 1: Checking Fields Table                  ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    id,
    venue_name,
    venue_id,
    CASE 
        WHEN venue_id IS NULL THEN '❌ NULL - This is the problem!'
        ELSE '✅ Has venue_id'
    END as status
FROM fields
LIMIT 10;

-- Count fields with/without venue_id
SELECT 
    COUNT(*) FILTER (WHERE venue_id IS NULL) as fields_without_venue_id,
    COUNT(*) FILTER (WHERE venue_id IS NOT NULL) as fields_with_venue_id,
    COUNT(*) as total_fields
FROM fields;

-- STEP 2: Check if venues table exists and has data
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔍 STEP 2: Checking Venues Table                  ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    id,
    name,
    rating,
    total_reviews,
    CASE 
        WHEN total_reviews = 0 THEN '⚠️  No reviews yet'
        ELSE '✅ Has reviews'
    END as review_status
FROM venues
LIMIT 10;

-- STEP 3: Check if bookings have venue_id
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔍 STEP 3: Checking Bookings Table                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    COUNT(*) FILTER (WHERE venue_id IS NULL) as bookings_without_venue_id,
    COUNT(*) FILTER (WHERE venue_id IS NOT NULL) as bookings_with_venue_id,
    COUNT(*) as total_bookings
FROM bookings;

-- Show sample bookings with venue_id
SELECT 
    id,
    booking_id,
    venue_id,
    status,
    CASE 
        WHEN venue_id IS NULL THEN '❌ NULL - This is a problem!'
        ELSE '✅ Has venue_id'
    END as status_check
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- STEP 4: Check reviews and their relationship to venues
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔍 STEP 4: Checking Reviews Table                 ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT COUNT(*) as total_reviews FROM reviews;

-- Show reviews with their venue info (through bookings)
SELECT 
    r.id as review_id,
    r.rating,
    r.booking_id,
    b.venue_id,
    v.name as venue_name,
    CASE 
        WHEN v.id IS NULL THEN '❌ Venue not found'
        ELSE '✅ Venue linked'
    END as venue_status
FROM reviews r
LEFT JOIN bookings b ON r.booking_id = b.id
LEFT JOIN venues v ON b.venue_id = v.id
LIMIT 10;

-- STEP 5: Comprehensive venue-field-booking relationship check
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔍 STEP 5: Checking Relationships                 ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- Show which venues can display ratings
SELECT 
    v.id as venue_id,
    v.name as venue_name,
    v.rating as current_rating_in_db,
    v.total_reviews as current_review_count_in_db,
    COUNT(DISTINCT f.id) as fields_count,
    COUNT(DISTINCT b.id) as bookings_count,
    COUNT(DISTINCT r.id) as reviews_count,
    CASE 
        WHEN COUNT(DISTINCT r.id) > 0 THEN '✅ Has reviews - rating should show'
        WHEN COUNT(DISTINCT b.id) > 0 THEN '⚠️  Has bookings but no reviews yet'
        WHEN COUNT(DISTINCT f.id) > 0 THEN '⚠️  Has fields but no bookings yet'
        ELSE '❌ No fields linked to this venue'
    END as diagnosis
FROM venues v
LEFT JOIN fields f ON f.venue_id = v.id
LEFT JOIN bookings b ON b.venue_id = v.id
LEFT JOIN reviews r ON r.booking_id = b.id
GROUP BY v.id, v.name, v.rating, v.total_reviews
ORDER BY reviews_count DESC
LIMIT 10;

-- STEP 6: Identify the root cause
-- ============================================
DO $$ 
DECLARE
    venues_count INTEGER;
    fields_with_venue_id INTEGER;
    bookings_with_venue_id INTEGER;
    reviews_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         📊 DIAGNOSIS SUMMARY                               ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    
    -- Get counts
    SELECT COUNT(*) INTO venues_count FROM venues;
    SELECT COUNT(*) FILTER (WHERE venue_id IS NOT NULL) INTO fields_with_venue_id FROM fields;
    SELECT COUNT(*) FILTER (WHERE venue_id IS NOT NULL) INTO bookings_with_venue_id FROM bookings;
    SELECT COUNT(*) INTO reviews_count FROM reviews;
    
    RAISE NOTICE '║ Venues in database: %', venues_count;
    RAISE NOTICE '║ Fields with venue_id: %', fields_with_venue_id;
    RAISE NOTICE '║ Bookings with venue_id: %', bookings_with_venue_id;
    RAISE NOTICE '║ Total reviews: %', reviews_count;
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    
    -- Identify problems
    IF venues_count = 0 THEN
        RAISE NOTICE '║ ❌ PROBLEM 1: No venues exist                            ║';
        RAISE NOTICE '║    FIX: Create venues first                               ║';
    END IF;
    
    IF fields_with_venue_id = 0 THEN
        RAISE NOTICE '║ ❌ PROBLEM 2: Fields have no venue_id                    ║';
        RAISE NOTICE '║    FIX: Update fields to link to venues                  ║';
        RAISE NOTICE '║    SQL: See FIX_VENUE_ID_IN_FIELDS.sql                   ║';
    END IF;
    
    IF bookings_with_venue_id = 0 THEN
        RAISE NOTICE '║ ❌ PROBLEM 3: Bookings have no venue_id                 ║';
        RAISE NOTICE '║    FIX: Update bookings with correct venue_id            ║';
    END IF;
    
    IF reviews_count = 0 THEN
        RAISE NOTICE '║ ⚠️  PROBLEM 4: No reviews exist yet                     ║';
        RAISE NOTICE '║    FIX: Create bookings, complete them, then add reviews ║';
    END IF;
    
    IF venues_count > 0 AND fields_with_venue_id > 0 AND bookings_with_venue_id > 0 AND reviews_count > 0 THEN
        RAISE NOTICE '║ ✅ All data exists - rating should be working!           ║';
        RAISE NOTICE '║    If still not showing, check app logs                  ║';
    END IF;
    
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
