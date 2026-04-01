-- ============================================
-- SIMPLE FIX: Drop ALL policies and recreate
-- ============================================
-- This script drops ALL existing policies on the bookings table
-- and recreates them with correct column references.
--
-- Use this if the main fix script encounters "already exists" errors.
-- ============================================

-- STEP 1: Drop ALL existing policies on bookings table
DO $$ 
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '🗑️  Dropping all existing policies on bookings table...';
    
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'bookings'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON bookings', r.policyname);
        RAISE NOTICE '   Dropped: %', r.policyname;
    END LOOP;
    
    RAISE NOTICE '✅ All old policies dropped';
END $$;

-- STEP 2: Create new correct policies
DO $$ 
BEGIN
    RAISE NOTICE '✅ Creating new correct policies...';
END $$;

-- Policy 1: Users can INSERT their own bookings
CREATE POLICY "Users can create bookings"
ON bookings
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
);

-- Policy 2: Users can SELECT their own bookings
CREATE POLICY "Users can view their own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
);

-- Policy 3: Users can UPDATE their own pending bookings
CREATE POLICY "Users can update their own bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (
    user_id = auth.uid()
)
WITH CHECK (
    user_id = auth.uid()
);

-- Policy 4: Admins can SELECT all bookings
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

-- Policy 5: Admins can UPDATE all bookings (FIX FOR THE ERROR)
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

-- Policy 6: Admins can DELETE bookings
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

-- STEP 3: Verify
SELECT 
    policyname,
    cmd as operation,
    'Created successfully' as status
FROM pg_policies 
WHERE tablename = 'bookings'
ORDER BY cmd, policyname;

-- SUCCESS MESSAGE
DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   ✅ FIX COMPLETED                         ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ All policies recreated successfully.                      ║';
    RAISE NOTICE '║ Test by updating a booking status from admin panel.       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
