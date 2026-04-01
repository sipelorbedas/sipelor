-- ============================================
-- FIX ADMIN DASHBOARD BOOKING TABLE RLS
-- ============================================
-- Problem: Bookings tidak muncul di admin dashboard meskipun ada di database
-- Solution: Fix RLS policies untuk bookings dan payment_proofs tables
-- 
-- Cara pakai:
-- 1. Login ke Supabase Dashboard
-- 2. Buka SQL Editor
-- 3. Copy-paste script ini
-- 4. Klik RUN
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║      🔧 FIXING ADMIN BOOKING TABLE RLS POLICIES           ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ This script will:                                         ║';
    RAISE NOTICE '║ 1. Drop existing restrictive RLS policies                 ║';
    RAISE NOTICE '║ 2. Create new policies for admin access                   ║';
    RAISE NOTICE '║ 3. Support both admin and superadmin roles                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- STEP 1: FIX BOOKINGS TABLE RLS POLICIES
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 STEP 1: Fixing bookings table RLS policies...';
    RAISE NOTICE '-------------------------------------------';
    
    -- Drop all existing policies on bookings table
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'bookings' AND schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON bookings', r.policyname);
        RAISE NOTICE '   ✓ Dropped policy: %', r.policyname;
    END LOOP;
    
    RAISE NOTICE '✅ All old bookings policies dropped';
    RAISE NOTICE 'Creating new bookings policies...';
END $$;

-- Policy 1: Users can create their own bookings
CREATE POLICY "Users can create bookings"
ON bookings FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy 2: Users can view their own bookings
CREATE POLICY "Users can view their own bookings"
ON bookings FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- Policy 3: Users can update their own bookings
CREATE POLICY "Users can update their own bookings"
ON bookings FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy 4: Admins and Superadmins can view ALL bookings
CREATE POLICY "Admins can view all bookings"
ON bookings FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

-- Policy 5: Admins and Superadmins can update ALL bookings
CREATE POLICY "Admins can update all bookings"
ON bookings FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

-- Policy 6: Admins and Superadmins can delete bookings
CREATE POLICY "Admins can delete bookings"
ON bookings FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Bookings table policies created successfully';
END $$;

-- ============================================
-- STEP 2: FIX PAYMENT_PROOFS TABLE RLS POLICIES
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 STEP 2: Fixing payment_proofs table RLS policies...';
    RAISE NOTICE '-------------------------------------------';
    
    -- Drop all existing policies on payment_proofs table
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'payment_proofs' AND schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON payment_proofs', r.policyname);
        RAISE NOTICE '   ✓ Dropped policy: %', r.policyname;
    END LOOP;
    
    RAISE NOTICE '✅ All old payment_proofs policies dropped';
    RAISE NOTICE 'Creating new payment_proofs policies...';
END $$;

-- Policy 1: Users can view their own payment proofs
CREATE POLICY "Users can read own payment proofs"
ON payment_proofs FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- Policy 2: Users can create their own payment proofs
CREATE POLICY "Users can create own payment proofs"
ON payment_proofs FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy 3: Admins and Superadmins can view ALL payment proofs
CREATE POLICY "Admins can read all payment proofs"
ON payment_proofs FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

-- Policy 4: Admins and Superadmins can update ALL payment proofs
CREATE POLICY "Admins can update payment proofs"
ON payment_proofs FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Payment_proofs table policies created successfully';
END $$;

-- ============================================
-- STEP 3: VERIFY POLICIES
-- ============================================
DO $$ 
DECLARE
    booking_count INTEGER;
    proof_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 STEP 3: Verifying policies...';
    RAISE NOTICE '-------------------------------------------';
    
    -- Count bookings policies
    SELECT COUNT(*) INTO booking_count
    FROM pg_policies 
    WHERE tablename = 'bookings' AND schemaname = 'public';
    
    -- Count payment_proofs policies
    SELECT COUNT(*) INTO proof_count
    FROM pg_policies 
    WHERE tablename = 'payment_proofs' AND schemaname = 'public';
    
    RAISE NOTICE 'Bookings policies: %', booking_count;
    RAISE NOTICE 'Payment_proofs policies: %', proof_count;
    
    IF booking_count >= 6 AND proof_count >= 4 THEN
        RAISE NOTICE '✅ All policies created successfully!';
    ELSE
        RAISE WARNING '⚠️  Some policies may be missing. Please check manually.';
    END IF;
END $$;

-- ============================================
-- STEP 4: DISPLAY FINAL STATUS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                    ✅ FIX COMPLETED!                       ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ RLS policies have been updated successfully.              ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ What to do next:                                          ║';
    RAISE NOTICE '║ 1. Refresh your Flutter app (hot reload)                  ║';
    RAISE NOTICE '║ 2. Check admin dashboard booking table                    ║';
    RAISE NOTICE '║ 3. Bookings should now appear immediately                 ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ If still not working:                                     ║';
    RAISE NOTICE '║ - Check if logged-in user has admin/superadmin role      ║';
    RAISE NOTICE '║ - Check Flutter console for error messages                ║';
    RAISE NOTICE '║ - Verify profiles.role column values in database          ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- BONUS: VIEW CURRENT POLICIES (OPTIONAL)
-- ============================================
-- Uncomment these lines to see all policies after fix:

-- SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies 
-- WHERE tablename IN ('bookings', 'payment_proofs')
-- ORDER BY tablename, policyname;
