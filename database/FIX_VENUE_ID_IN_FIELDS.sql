-- ============================================
-- FIX: Link Fields to Venues via venue_id
-- ============================================
-- This script fixes the issue where fields table has NULL venue_id
-- causing ratings to not display on venue cards
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔧 FIXING VENUE_ID IN FIELDS TABLE                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- OPTION 1: If you want ONE venue for ALL fields
-- ============================================
-- Uncomment and modify this section if you have one venue (e.g., "Stadion Jalak Harupat")
-- and want all fields to belong to it

/*
DO $$ 
DECLARE
    main_venue_id UUID;
    venue_exists BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Option 1: Assigning all fields to one main venue...';
    
    -- Check if main venue exists
    SELECT id INTO main_venue_id 
    FROM venues 
    WHERE name = 'Stadion Jalak Harupat' -- Change this to your venue name
    LIMIT 1;
    
    IF main_venue_id IS NULL THEN
        RAISE NOTICE '❌ Venue "Stadion Jalak Harupat" not found!';
        RAISE NOTICE '   Creating it now...';
        
        INSERT INTO venues (name, address, city, rating, total_reviews, is_active)
        VALUES (
            'Stadion Jalak Harupat',
            'Jl. Raya Jalaprang',
            'Kabupaten Bandung',
            0.0,
            0,
            true
        )
        RETURNING id INTO main_venue_id;
        
        RAISE NOTICE '✅ Created venue with ID: %', main_venue_id;
    ELSE
        RAISE NOTICE '✅ Found venue with ID: %', main_venue_id;
    END IF;
    
    -- Update all fields to use this venue_id
    UPDATE fields
    SET venue_id = main_venue_id
    WHERE venue_id IS NULL;
    
    RAISE NOTICE '✅ Updated all fields to use venue: %', main_venue_id;
    
END $$;
*/

-- OPTION 2: Create individual venues for each field
-- ============================================
-- Use this if each field should have its own venue entry

DO $$ 
DECLARE
    field_record RECORD;
    new_venue_id UUID;
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Option 2: Creating individual venues for each field...';
    
    -- Loop through fields that don't have venue_id
    FOR field_record IN 
        SELECT id, venue_name, area 
        FROM fields 
        WHERE venue_id IS NULL
    LOOP
        -- Check if venue with this name already exists
        SELECT id INTO new_venue_id
        FROM venues
        WHERE name = field_record.venue_name
        LIMIT 1;
        
        -- If venue doesn't exist, create it
        IF new_venue_id IS NULL THEN
            INSERT INTO venues (name, address, city, rating, total_reviews, is_active)
            VALUES (
                field_record.venue_name,
                field_record.area,
                'Kabupaten Bandung', -- Change this to your default city
                0.0,
                0,
                true
            )
            RETURNING id INTO new_venue_id;
            
            RAISE NOTICE '   Created venue: % (ID: %)', field_record.venue_name, new_venue_id;
        ELSE
            RAISE NOTICE '   Using existing venue: % (ID: %)', field_record.venue_name, new_venue_id;
        END IF;
        
        -- Update field with venue_id
        UPDATE fields
        SET venue_id = new_venue_id
        WHERE id = field_record.id;
        
        updated_count := updated_count + 1;
    END LOOP;
    
    RAISE NOTICE '✅ Updated % fields with venue_id', updated_count;
    
END $$;

-- STEP 2: Update existing bookings with venue_id from fields
-- ============================================
DO $$ 
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 2: Updating bookings with venue_id from fields...';
    
    WITH updated_bookings AS (
        UPDATE bookings b
        SET venue_id = f.venue_id
        FROM fields f
        WHERE b.field_id = f.id
        AND b.venue_id IS NULL
        AND f.venue_id IS NOT NULL
        RETURNING b.id
    )
    SELECT COUNT(*) INTO updated_count FROM updated_bookings;
    
    RAISE NOTICE '✅ Updated % bookings with venue_id', updated_count;
    
END $$;

-- STEP 3: Verify the fix
-- ============================================
DO $$ 
DECLARE
    fields_without_venue INTEGER;
    bookings_without_venue INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 3: Verifying the fix...';
    
    SELECT COUNT(*) INTO fields_without_venue
    FROM fields
    WHERE venue_id IS NULL;
    
    SELECT COUNT(*) INTO bookings_without_venue
    FROM bookings
    WHERE venue_id IS NULL;
    
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║               ✅ VERIFICATION RESULTS                      ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Fields without venue_id: %', fields_without_venue;
    RAISE NOTICE '║ Bookings without venue_id: %', bookings_without_venue;
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    
    IF fields_without_venue = 0 AND bookings_without_venue = 0 THEN
        RAISE NOTICE '║ ✅ SUCCESS! All records have venue_id                    ║';
        RAISE NOTICE '║ 📱 Now test the app - ratings should display!            ║';
    ELSE
        RAISE NOTICE '║ ⚠️  Some records still missing venue_id                 ║';
        RAISE NOTICE '║    Run the debug script to investigate                   ║';
    END IF;
    
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- STEP 4: Show sample data to verify
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📊 Sample of updated data:';
END $$;

SELECT 
    f.venue_name,
    f.venue_id,
    v.name as venue_in_venues_table,
    COUNT(b.id) as bookings_count
FROM fields f
LEFT JOIN venues v ON f.venue_id = v.id
LEFT JOIN bookings b ON b.field_id = f.id
GROUP BY f.id, f.venue_name, f.venue_id, v.name
LIMIT 10;
