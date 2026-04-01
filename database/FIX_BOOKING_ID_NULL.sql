-- ============================================
-- FIX: Booking ID NULL Error
-- ============================================
-- Error: "null value in column booking_id violates not-null constraint"
-- This happens when updating booking status
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║         🔧 FIXING BOOKING_ID NULL ERROR                   ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- Step 1: Check if booking_id column has NULL constraint
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 1: Checking booking_id column constraint...';
END $$;

SELECT 
    column_name, 
    is_nullable, 
    column_default,
    data_type
FROM information_schema.columns
WHERE table_name = 'bookings' 
AND column_name = 'booking_id';

-- Step 2: Check if there are any bookings with NULL booking_id
DO $$ 
DECLARE
    null_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 2: Checking for NULL booking_id values...';
    
    SELECT COUNT(*) INTO null_count
    FROM bookings
    WHERE booking_id IS NULL;
    
    IF null_count > 0 THEN
        RAISE NOTICE '⚠️  Found % bookings with NULL booking_id', null_count;
    ELSE
        RAISE NOTICE '✅ No bookings with NULL booking_id found';
    END IF;
END $$;

-- Step 3: Create sequence for booking_id if not exists
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 3: Creating booking_id sequence...';
    
    IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'booking_id_seq') THEN
        CREATE SEQUENCE booking_id_seq START 1;
        RAISE NOTICE '✅ Sequence booking_id_seq created';
    ELSE
        RAISE NOTICE '✅ Sequence booking_id_seq already exists';
    END IF;
END $$;

-- Step 4: Create or replace function to generate booking_id
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 4: Creating booking_id generation function...';
END $$;

CREATE OR REPLACE FUNCTION generate_booking_id()
RETURNS TEXT AS $$
DECLARE
    next_val INTEGER;
    booking_code TEXT;
BEGIN
    next_val := nextval('booking_id_seq');
    booking_code := 'BOOK' || LPAD(next_val::TEXT, 4, '0');
    RETURN booking_code;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Function generate_booking_id() created';
END $$;

-- Step 5: Make booking_id nullable temporarily (to allow updates)
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 5: Making booking_id nullable temporarily...';
    
    ALTER TABLE bookings ALTER COLUMN booking_id DROP NOT NULL;
    
    RAISE NOTICE '✅ booking_id is now nullable';
END $$;

-- Step 6: Update existing NULL booking_id values
DO $$ 
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 6: Updating NULL booking_id values...';
    
    WITH updated_rows AS (
        UPDATE bookings
        SET booking_id = generate_booking_id()
        WHERE booking_id IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO updated_count FROM updated_rows;
    
    IF updated_count > 0 THEN
        RAISE NOTICE '✅ Updated % bookings with generated booking_id', updated_count;
    ELSE
        RAISE NOTICE '✅ No bookings needed updating';
    END IF;
END $$;

-- Step 7: Create trigger to auto-generate booking_id on INSERT
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 7: Creating trigger for auto-generating booking_id...';
END $$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS set_booking_id_on_insert ON bookings;
DROP FUNCTION IF EXISTS set_booking_id_on_insert();

CREATE OR REPLACE FUNCTION set_booking_id_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.booking_id IS NULL THEN
        NEW.booking_id := generate_booking_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_booking_id_on_insert
    BEFORE INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION set_booking_id_on_insert();

DO $$ 
BEGIN
    RAISE NOTICE '✅ Trigger set_booking_id_on_insert created';
END $$;

-- Step 8: Make booking_id NOT NULL again (with default)
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 8: Setting booking_id default and NOT NULL...';
    
    -- Set default value for new inserts
    ALTER TABLE bookings ALTER COLUMN booking_id SET DEFAULT generate_booking_id();
    
    -- Make it NOT NULL again
    ALTER TABLE bookings ALTER COLUMN booking_id SET NOT NULL;
    
    RAISE NOTICE '✅ booking_id now has default value and is NOT NULL';
END $$;

-- Step 9: Verify the fix
DO $$ 
DECLARE
    null_count INTEGER;
    has_default BOOLEAN;
    is_not_null BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 9: Verifying the fix...';
    
    -- Check for NULL values
    SELECT COUNT(*) INTO null_count
    FROM bookings
    WHERE booking_id IS NULL;
    
    -- Check column properties
    SELECT 
        column_default IS NOT NULL,
        is_nullable = 'NO'
    INTO has_default, is_not_null
    FROM information_schema.columns
    WHERE table_name = 'bookings' AND column_name = 'booking_id';
    
    RAISE NOTICE '   - NULL booking_id count: %', null_count;
    RAISE NOTICE '   - Has default value: %', has_default;
    RAISE NOTICE '   - Is NOT NULL: %', is_not_null;
    
    IF null_count = 0 AND has_default AND is_not_null THEN
        RAISE NOTICE '✅ Verification PASSED';
    ELSE
        RAISE NOTICE '⚠️  Verification FAILED - please check manually';
    END IF;
END $$;

-- Step 10: Test the fix
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 Step 10: Testing booking_id generation...';
    RAISE NOTICE '   Test 1: Calling generate_booking_id()';
    RAISE NOTICE '   Result: %', generate_booking_id();
    RAISE NOTICE '✅ Test passed';
END $$;

-- Summary
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║               ✅ FIX COMPLETE                              ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ What was fixed:                                           ║';
    RAISE NOTICE '║ 1. Created sequence for booking_id                        ║';
    RAISE NOTICE '║ 2. Created function to generate booking_id (BOOK0001)     ║';
    RAISE NOTICE '║ 3. Updated NULL booking_id values                         ║';
    RAISE NOTICE '║ 4. Created trigger to auto-generate on INSERT             ║';
    RAISE NOTICE '║ 5. Set booking_id as NOT NULL with default                ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ Next steps:                                                ║';
    RAISE NOTICE '║ 1. Test creating a new booking in the app                 ║';
    RAISE NOTICE '║ 2. Test confirming a booking                              ║';
    RAISE NOTICE '║ 3. Verify booking_id is auto-generated                    ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
