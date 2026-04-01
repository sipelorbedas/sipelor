-- ============================================
-- VERIFY ADMIN ACCESS TO BOOKINGS
-- ============================================
-- Script ini untuk memverifikasi bahwa admin bisa akses bookings
-- Run script ini untuk debugging
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║           🔍 VERIFYING ADMIN ACCESS                        ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- CHECK 1: Total bookings in database
-- ============================================
DO $$ 
DECLARE
    total_bookings INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_bookings FROM bookings;
    
    RAISE NOTICE '';
    RAISE NOTICE '📊 CHECK 1: Total Bookings in Database';
    RAISE NOTICE '-------------------------------------------';
    RAISE NOTICE 'Total bookings: %', total_bookings;
    
    IF total_bookings = 0 THEN
        RAISE WARNING '⚠️  No bookings found in database!';
    ELSE
        RAISE NOTICE '✅ Bookings exist in database';
    END IF;
END $$;

-- ============================================
-- CHECK 2: Show recent bookings
-- ============================================
RAISE NOTICE '';
RAISE NOTICE '📋 CHECK 2: Recent Bookings (Latest 5)';
RAISE NOTICE '-------------------------------------------';

SELECT 
    id,
    booking_id,
    user_id,
    booking_date,
    status,
    payment_status,
    created_at
FROM bookings
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- CHECK 3: Count admin users
-- ============================================
DO $$ 
DECLARE
    admin_count INTEGER;
    superadmin_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '👥 CHECK 3: Admin Users';
    RAISE NOTICE '-------------------------------------------';
    
    SELECT COUNT(*) INTO admin_count 
    FROM profiles 
    WHERE role = 'admin';
    
    SELECT COUNT(*) INTO superadmin_count 
    FROM profiles 
    WHERE role = 'superadmin';
    
    RAISE NOTICE 'Admin users: %', admin_count;
    RAISE NOTICE 'Superadmin users: %', superadmin_count;
    
    IF admin_count = 0 AND superadmin_count = 0 THEN
        RAISE WARNING '⚠️  No admin/superadmin users found!';
        RAISE NOTICE '💡 You need to set user role to admin or superadmin in profiles table';
    ELSE
        RAISE NOTICE '✅ Admin users exist';
    END IF;
END $$;

-- ============================================
-- CHECK 4: Show admin users
-- ============================================
RAISE NOTICE '';
RAISE NOTICE '👤 CHECK 4: Admin User Details';
RAISE NOTICE '-------------------------------------------';

SELECT 
    id,
    email,
    full_name,
    role,
    created_at
FROM profiles
WHERE role IN ('admin', 'superadmin')
ORDER BY created_at;

-- ============================================
-- CHECK 5: RLS policies on bookings
-- ============================================
DO $$ 
DECLARE
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔒 CHECK 5: RLS Policies on Bookings Table';
    RAISE NOTICE '-------------------------------------------';
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'bookings' AND schemaname = 'public';
    
    RAISE NOTICE 'Total policies: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE WARNING '⚠️  No RLS policies found on bookings table!';
        RAISE NOTICE '💡 Run FIX_ADMIN_BOOKING_RLS.sql to create policies';
    ELSIF policy_count < 6 THEN
        RAISE WARNING '⚠️  Incomplete policies (expected 6, found %)', policy_count;
        RAISE NOTICE '💡 Run FIX_ADMIN_BOOKING_RLS.sql to fix policies';
    ELSE
        RAISE NOTICE '✅ RLS policies exist';
    END IF;
END $$;

-- ============================================
-- CHECK 6: List all bookings policies
-- ============================================
RAISE NOTICE '';
RAISE NOTICE '📜 CHECK 6: Bookings Table Policies';
RAISE NOTICE '-------------------------------------------';

SELECT 
    policyname AS "Policy Name",
    cmd AS "Command",
    roles AS "Roles",
    permissive AS "Type"
FROM pg_policies 
WHERE tablename = 'bookings' AND schemaname = 'public'
ORDER BY policyname;

-- ============================================
-- CHECK 7: RLS policies on payment_proofs
-- ============================================
DO $$ 
DECLARE
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔒 CHECK 7: RLS Policies on Payment_Proofs Table';
    RAISE NOTICE '-------------------------------------------';
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'payment_proofs' AND schemaname = 'public';
    
    RAISE NOTICE 'Total policies: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE WARNING '⚠️  No RLS policies found on payment_proofs table!';
    ELSIF policy_count < 4 THEN
        RAISE WARNING '⚠️  Incomplete policies (expected 4, found %)', policy_count;
    ELSE
        RAISE NOTICE '✅ RLS policies exist';
    END IF;
END $$;

-- ============================================
-- CHECK 8: List all payment_proofs policies
-- ============================================
RAISE NOTICE '';
RAISE NOTICE '📜 CHECK 8: Payment_Proofs Table Policies';
RAISE NOTICE '-------------------------------------------';

SELECT 
    policyname AS "Policy Name",
    cmd AS "Command",
    roles AS "Roles",
    permissive AS "Type"
FROM pg_policies 
WHERE tablename = 'payment_proofs' AND schemaname = 'public'
ORDER BY policyname;

-- ============================================
-- FINAL SUMMARY
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                   ✅ VERIFICATION COMPLETE                 ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Check the results above to identify issues:               ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ Common issues:                                             ║';
    RAISE NOTICE '║ 1. No bookings in database → Create test bookings         ║';
    RAISE NOTICE '║ 2. No admin users → Set role to admin in profiles         ║';
    RAISE NOTICE '║ 3. Missing RLS policies → Run FIX_ADMIN_BOOKING_RLS.sql   ║';
    RAISE NOTICE '║ 4. Wrong role values → Check profiles.role column         ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
