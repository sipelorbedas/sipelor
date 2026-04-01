-- ============================================
-- FIX: Common Trigger Functions with f.name
-- ============================================
-- This script fixes common notification functions that reference f.name
-- Run this after running find_and_fix_trigger.sql to identify the issue
-- ============================================

-- ============================================
-- FIX 1: Notification function for booking status change
-- ============================================
-- Drop and recreate if exists
DROP FUNCTION IF EXISTS notify_booking_status_change() CASCADE;

CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only send notification when status changes to confirmed or completed
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

-- ============================================
-- FIX 2: Notification function for payment verification
-- ============================================
DROP FUNCTION IF EXISTS notify_payment_verification() CASCADE;

CREATE OR REPLACE FUNCTION notify_payment_verification()
RETURNS TRIGGER AS $$
BEGIN
    -- Only send notification when payment_status changes to verified or rejected
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

-- ============================================
-- FIX 3: Combined booking update notification
-- ============================================
DROP FUNCTION IF EXISTS handle_booking_update() CASCADE;

CREATE OR REPLACE FUNCTION handle_booking_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle status change
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type, created_at)
        SELECT 
            NEW.user_id,
            'Update Status Booking',
            'Status booking untuk ' || COALESCE(f.venue_name, 'lapangan') || ' area ' || COALESCE(f.area, '') || ' telah diupdate menjadi ' || NEW.status,
            'booking',
            NEW.id,
            'booking',
            NOW()
        FROM fields f
        WHERE f.id = NEW.field_id;
    END IF;
    
    -- Handle payment status change
    IF (OLD.payment_status IS DISTINCT FROM NEW.payment_status) THEN
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type, created_at)
        SELECT 
            NEW.user_id,
            'Update Pembayaran',
            'Status pembayaran untuk ' || COALESCE(f.venue_name, 'lapangan') || ' area ' || COALESCE(f.area, '') || ' telah diupdate',
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

-- ============================================
-- RECREATE TRIGGERS
-- ============================================
-- Drop old triggers first
DROP TRIGGER IF EXISTS booking_status_change_notification ON bookings;
DROP TRIGGER IF EXISTS payment_verification_notification ON bookings;
DROP TRIGGER IF EXISTS booking_update_notification ON bookings;

-- Create trigger for booking status changes
CREATE TRIGGER booking_status_change_notification
    AFTER UPDATE ON bookings
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION notify_booking_status_change();

-- Create trigger for payment verification
CREATE TRIGGER payment_verification_notification
    AFTER UPDATE ON bookings
    FOR EACH ROW
    WHEN (OLD.payment_status IS DISTINCT FROM NEW.payment_status)
    EXECUTE FUNCTION notify_payment_verification();

-- ============================================
-- VERIFY
-- ============================================
SELECT 
    'Trigger: ' || tgname as name,
    'Function: ' || pg_get_functiondef(tgfoid)::text as details
FROM pg_trigger
WHERE tgrelid = 'bookings'::regclass
AND tgname NOT LIKE 'RI_%'
ORDER BY tgname;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║              ✅ TRIGGER FUNCTIONS FIXED                    ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Fixed functions:                                          ║';
    RAISE NOTICE '║ 1. notify_booking_status_change()                         ║';
    RAISE NOTICE '║ 2. notify_payment_verification()                          ║';
    RAISE NOTICE '║ 3. handle_booking_update()                                ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ All references to f.name changed to f.venue_name          ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ Test by updating a booking status to "confirmed"          ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
