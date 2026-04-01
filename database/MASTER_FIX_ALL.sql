-- ============================================
-- MASTER FIX: Complete solution for f.name error
-- ============================================
-- This script fixes EVERYTHING in the correct order:
-- 1. RLS Policies
-- 2. Trigger Functions
-- 3. Triggers
--
-- Run this single script to fix all issues.
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║           🚀 MASTER FIX SCRIPT STARTING                    ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ This will fix:                                            ║';
    RAISE NOTICE '║ 1. RLS Policies                                           ║';
    RAISE NOTICE '║ 2. Trigger Functions                                      ║';
    RAISE NOTICE '║ 3. Triggers                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- PART 1: FIX RLS POLICIES
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 PART 1: Fixing RLS Policies...';
    RAISE NOTICE '-------------------------------------------';
    
    -- Drop all existing policies
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'bookings'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON bookings', r.policyname);
        RAISE NOTICE '   Dropped policy: %', r.policyname;
    END LOOP;
    
    RAISE NOTICE '✅ All old policies dropped';
END $$;

-- Create new correct policies
CREATE POLICY "Users can create bookings"
ON bookings FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view their own bookings"
ON bookings FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own bookings"
ON bookings FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all bookings"
ON bookings FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Admins can update all bookings"
ON bookings FOR UPDATE TO authenticated
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

CREATE POLICY "Admins can delete bookings"
ON bookings FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Part 1 Complete: RLS policies recreated';
END $$;

-- ============================================
-- PART 2: FIX TRIGGER FUNCTIONS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 PART 2: Fixing Trigger Functions...';
    RAISE NOTICE '-------------------------------------------';
END $$;

-- Drop old functions
DROP FUNCTION IF EXISTS notify_booking_status_change() CASCADE;
DROP FUNCTION IF EXISTS notify_payment_verification() CASCADE;
DROP FUNCTION IF EXISTS handle_booking_update() CASCADE;

-- Create fixed notification function for booking status change
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.status != NEW.status AND NEW.status IN ('confirmed', 'completed')) THEN
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type, created_at)
        SELECT 
            NEW.user_id,
            CASE 
                WHEN NEW.status = 'confirmed' THEN 'Booking Dikonfirmasi'
                WHEN NEW.status = 'completed' THEN 'Booking Selesai'
                ELSE 'Update Booking'
            END,
            CASE 
                WHEN NEW.status = 'confirmed' THEN 'Booking Anda untuk ' || COALESCE(f.venue_name, 'lapangan') || ' telah dikonfirmasi'
                WHEN NEW.status = 'completed' THEN 'Booking Anda untuk ' || COALESCE(f.venue_name, 'lapangan') || ' telah selesai'
                ELSE 'Status booking Anda telah diupdate'
            END,
            'booking',
            NEW.id,
            'booking',
            NOW()
        FROM fields f
        WHERE f.id = NEW.field_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create fixed notification function for payment verification
CREATE OR REPLACE FUNCTION notify_payment_verification()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.payment_status != NEW.payment_status AND NEW.payment_status IN ('verified', 'rejected')) THEN
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type, created_at)
        SELECT 
            NEW.user_id,
            CASE 
                WHEN NEW.payment_status = 'verified' THEN 'Pembayaran Diverifikasi'
                WHEN NEW.payment_status = 'rejected' THEN 'Pembayaran Ditolak'
                ELSE 'Update Pembayaran'
            END,
            CASE 
                WHEN NEW.payment_status = 'verified' THEN 'Pembayaran untuk ' || COALESCE(f.venue_name, 'lapangan') || ' telah diverifikasi'
                WHEN NEW.payment_status = 'rejected' THEN 'Pembayaran untuk ' || COALESCE(f.venue_name, 'lapangan') || ' ditolak'
                ELSE 'Status pembayaran Anda telah diupdate'
            END,
            'payment',
            NEW.id,
            'booking',
            NOW()
        FROM fields f
        WHERE f.id = NEW.field_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Part 2 Complete: Trigger functions recreated with f.venue_name';
END $$;

-- ============================================
-- PART 3: RECREATE TRIGGERS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 PART 3: Recreating Triggers...';
    RAISE NOTICE '-------------------------------------------';
END $$;

-- Drop old triggers
DROP TRIGGER IF EXISTS booking_status_change_notification ON bookings;
DROP TRIGGER IF EXISTS payment_verification_notification ON bookings;
DROP TRIGGER IF EXISTS booking_update_notification ON bookings;

-- Create new triggers
CREATE TRIGGER booking_status_change_notification
    AFTER UPDATE ON bookings
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION notify_booking_status_change();

CREATE TRIGGER payment_verification_notification
    AFTER UPDATE ON bookings
    FOR EACH ROW
    WHEN (OLD.payment_status IS DISTINCT FROM NEW.payment_status)
    EXECUTE FUNCTION notify_payment_verification();

DO $$ 
BEGIN
    RAISE NOTICE '✅ Part 3 Complete: Triggers recreated';
END $$;

-- ============================================
-- VERIFICATION
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📊 VERIFICATION';
    RAISE NOTICE '-------------------------------------------';
END $$;

-- Show all policies
SELECT 
    '✅ Policy: ' || policyname || ' (' || cmd || ')' as result
FROM pg_policies 
WHERE tablename = 'bookings'
ORDER BY cmd, policyname;

-- Show all triggers
SELECT 
    '✅ Trigger: ' || tgname || ' → ' || pg_proc.proname as result
FROM pg_trigger
JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE tgrelid = 'bookings'::regclass
AND tgname NOT LIKE 'RI_%'
ORDER BY tgname;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║              ✅ ALL FIXES COMPLETED SUCCESSFULLY           ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Fixed:                                                    ║';
    RAISE NOTICE '║ ✅ RLS Policies (6 policies)                              ║';
    RAISE NOTICE '║ ✅ Trigger Functions (f.name → f.venue_name)              ║';
    RAISE NOTICE '║ ✅ Triggers (recreated)                                   ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ 🧪 TEST NOW:                                              ║';
    RAISE NOTICE '║ Go to admin panel and change booking status to confirmed  ║';
    RAISE NOTICE '║ It should work without any errors!                        ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
