-- ========================================
-- SUPABASE EMAIL TEMPLATES & NOTIFICATIONS SETUP
-- ========================================
-- 
-- Script ini berisi:
-- 1. Functions untuk send email notifications
-- 2. Triggers untuk automated emails (booking approved, dll)
-- 3. Test queries untuk verify email system
--
-- Usage:
-- 1. Run this script in Supabase SQL Editor
-- 2. Update email templates in Supabase Dashboard → Authentication → Email Templates
-- 3. Test emails using test queries at bottom of this file
--
-- NOTE: Script ini idempotent (aman dijalankan berkali-kali)
-- ========================================

-- ========================================
-- PART 1: Test Email Functions
-- ========================================

-- NOTE: Supabase Auth emails (verification, password reset) cannot be triggered from SQL.
-- These functions are for reference only and will not work from SQL Editor.
-- 
-- To test Auth emails, use one of these methods:
-- 1. Flutter Client SDK: supabase.auth.signUp() or supabase.auth.resetPasswordForEmail()
-- 2. Supabase Management API via HTTP request
-- 3. Supabase Dashboard: Authentication → Users → Send password reset email
--
-- The functions below are commented out but kept for documentation purposes.

-- Function to check if user exists and log test attempt
-- Usage: SELECT check_user_for_test_email('your@email.com');
CREATE OR REPLACE FUNCTION check_user_for_test_email(test_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_exists BOOLEAN;
  user_confirmed BOOLEAN;
BEGIN
  -- Check if user exists
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE email = test_email
  ) INTO user_exists;
  
  IF NOT user_exists THEN
    RETURN 'User not found with email: ' || test_email || '. Please signup first.';
  END IF;
  
  -- Check if user is confirmed
  SELECT 
    CASE WHEN confirmed_at IS NOT NULL THEN true ELSE false END
  INTO user_confirmed
  FROM auth.users 
  WHERE email = test_email;
  
  IF user_confirmed THEN
    RETURN 'User exists and is already verified: ' || test_email;
  ELSE
    RETURN 'User exists but NOT verified: ' || test_email || '. Use client SDK to resend verification.';
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'Error checking user: ' || SQLERRM;
END;
$$;

-- ========================================
-- PART 2: Email Notification Log Table
-- ========================================

-- Create table to log all sent emails
CREATE TABLE IF NOT EXISTS email_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  email_type TEXT NOT NULL, -- 'verification', 'password_reset', 'booking_approved', 'booking_rejected', etc.
  recipient_email TEXT NOT NULL,
  subject TEXT,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'failed'
  error_message TEXT,
  metadata JSONB, -- Additional data (booking_id, venue_name, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_at TIMESTAMP WITH TIME ZONE
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_email_notifications_user_id ON email_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_status ON email_notifications(status);
CREATE INDEX IF NOT EXISTS idx_email_notifications_created_at ON email_notifications(created_at DESC);

-- Add RLS policies
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own email notifications" ON email_notifications;
DROP POLICY IF EXISTS "Service can insert email notifications" ON email_notifications;

-- Only authenticated users can view their own email notifications
CREATE POLICY "Users can view own email notifications"
  ON email_notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can insert email notifications
CREATE POLICY "Service can insert email notifications"
  ON email_notifications FOR INSERT
  WITH CHECK (true);

-- ========================================
-- PART 3: Booking Approved Email Notification
-- ========================================

-- Function to log and prepare booking approved email
CREATE OR REPLACE FUNCTION notify_booking_approved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_email TEXT;
  user_name TEXT;
  venue_name TEXT;
  field_name TEXT;
  booking_date TEXT;
  start_time TEXT;
  end_time TEXT;
  total_price TEXT;
BEGIN
  -- Only trigger when status changes to 'confirmed'
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
    
    -- Get user details
    SELECT email, full_name 
    INTO user_email, user_name
    FROM profiles 
    WHERE id = NEW.user_id;
    
    -- Get booking details
    SELECT 
      v.name,
      f.name,
      TO_CHAR(NEW.booking_date, 'DD Month YYYY'),
      TO_CHAR(NEW.start_time, 'HH24:MI'),
      TO_CHAR(NEW.end_time, 'HH24:MI'),
      'Rp ' || TO_CHAR(NEW.total_price, 'FM999,999,999')
    INTO 
      venue_name,
      field_name,
      booking_date,
      start_time,
      end_time,
      total_price
    FROM venues v
    JOIN fields f ON f.venue_id = v.id
    WHERE v.id = NEW.venue_id AND f.id = NEW.field_id;
    
    -- Log email notification
    INSERT INTO email_notifications (
      user_id,
      email_type,
      recipient_email,
      subject,
      status,
      metadata
    ) VALUES (
      NEW.user_id,
      'booking_approved',
      user_email,
      'Booking Disetujui - SIPELOR BEDAS',
      'pending',
      jsonb_build_object(
        'booking_id', NEW.id,
        'user_name', user_name,
        'venue_name', venue_name,
        'field_name', field_name,
        'booking_date', booking_date,
        'start_time', start_time,
        'end_time', end_time,
        'total_price', total_price,
        'eticket_url', 'sipelor://eticket/' || NEW.id
      )
    );
    
    -- TODO: Call external email service or Edge Function here
    -- Example: PERFORM net.http_post(
    --   url := 'https://your-email-service.com/send',
    --   body := json_build_object(...)
    -- );
    
    RAISE NOTICE 'Booking approved notification logged for booking: %', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for booking approved
DROP TRIGGER IF EXISTS trigger_notify_booking_approved ON bookings;
CREATE TRIGGER trigger_notify_booking_approved
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_booking_approved();

-- ========================================
-- PART 4: Booking Rejected Email Notification
-- ========================================

-- Function to notify booking rejection
CREATE OR REPLACE FUNCTION notify_booking_rejected()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_email TEXT;
  user_name TEXT;
  venue_name TEXT;
BEGIN
  -- Only trigger when status changes to 'cancelled' by admin
  IF NEW.status = 'cancelled' AND OLD.status = 'pending' THEN
    
    -- Get user details
    SELECT email, full_name 
    INTO user_email, user_name
    FROM profiles 
    WHERE id = NEW.user_id;
    
    -- Get venue name
    SELECT name INTO venue_name
    FROM venues WHERE id = NEW.venue_id;
    
    -- Log email notification
    INSERT INTO email_notifications (
      user_id,
      email_type,
      recipient_email,
      subject,
      status,
      metadata
    ) VALUES (
      NEW.user_id,
      'booking_rejected',
      user_email,
      'Booking Ditolak - SIPELOR BEDAS',
      'pending',
      jsonb_build_object(
        'booking_id', NEW.id,
        'user_name', user_name,
        'venue_name', venue_name,
        'rejection_reason', COALESCE(NEW.cancellation_reason, 'Tidak ada alasan diberikan')
      )
    );
    
    RAISE NOTICE 'Booking rejected notification logged for booking: %', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for booking rejected
DROP TRIGGER IF EXISTS trigger_notify_booking_rejected ON bookings;
CREATE TRIGGER trigger_notify_booking_rejected
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION notify_booking_rejected();

-- ========================================
-- PART 5: Payment Reminder Before Expiry
-- ========================================

-- Function to send payment reminders (run via cron or scheduled task)
CREATE OR REPLACE FUNCTION send_payment_reminders()
RETURNS TABLE (
  booking_id UUID,
  user_email TEXT,
  hours_remaining INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH expiring_bookings AS (
    SELECT 
      b.id,
      p.email,
      EXTRACT(HOUR FROM (b.payment_deadline - NOW()))::INTEGER AS hours_left
    FROM bookings b
    JOIN profiles p ON p.id = b.user_id
    WHERE b.status = 'pending'
      AND b.payment_proof IS NULL
      AND b.payment_deadline > NOW()
      AND b.payment_deadline <= NOW() + INTERVAL '2 hours'
  )
  SELECT 
    eb.id,
    eb.email,
    eb.hours_left
  FROM expiring_bookings eb;
  
  -- Log reminders
  INSERT INTO email_notifications (user_id, email_type, recipient_email, subject, status, metadata)
  SELECT 
    b.user_id,
    'payment_reminder',
    p.email,
    'Segera Upload Bukti Pembayaran - SIPELOR BEDAS',
    'pending',
    jsonb_build_object(
      'booking_id', b.id,
      'hours_remaining', EXTRACT(HOUR FROM (b.payment_deadline - NOW()))
    )
  FROM bookings b
  JOIN profiles p ON p.id = b.user_id
  WHERE b.status = 'pending'
    AND b.payment_proof IS NULL
    AND b.payment_deadline > NOW()
    AND b.payment_deadline <= NOW() + INTERVAL '2 hours';
END;
$$;

-- ========================================
-- PART 6: Weekly Revenue Report Function
-- ========================================

-- Function to generate weekly revenue report
CREATE OR REPLACE FUNCTION generate_weekly_revenue_report()
RETURNS TABLE (
  total_bookings BIGINT,
  confirmed_bookings BIGINT,
  total_revenue NUMERIC,
  avg_booking_value NUMERIC,
  top_venue TEXT,
  report_period TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT AS total_bookings,
    COUNT(*) FILTER (WHERE status = 'confirmed')::BIGINT AS confirmed_bookings,
    COALESCE(SUM(total_price) FILTER (WHERE status = 'confirmed'), 0) AS total_revenue,
    COALESCE(AVG(total_price) FILTER (WHERE status = 'confirmed'), 0) AS avg_booking_value,
    (
      SELECT v.name 
      FROM venues v
      JOIN bookings b ON b.venue_id = v.id
      WHERE b.created_at >= NOW() - INTERVAL '7 days'
        AND b.status = 'confirmed'
      GROUP BY v.name
      ORDER BY COUNT(*) DESC
      LIMIT 1
    ) AS top_venue,
    TO_CHAR(NOW() - INTERVAL '7 days', 'DD Mon') || ' - ' || TO_CHAR(NOW(), 'DD Mon YYYY') AS report_period
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '7 days';
END;
$$;

-- ========================================
-- PART 7: Admin Email Notification Preferences
-- ========================================

-- Table to store admin email notification preferences
CREATE TABLE IF NOT EXISTS admin_email_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL, -- 'new_booking', 'payment_uploaded', 'weekly_report', etc.
  enabled BOOLEAN DEFAULT true,
  email_address TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(admin_user_id, notification_type)
);

-- RLS policies
ALTER TABLE admin_email_preferences ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if exists
DROP POLICY IF EXISTS "Admins can manage own email preferences" ON admin_email_preferences;

CREATE POLICY "Admins can manage own email preferences"
  ON admin_email_preferences
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM staff
      WHERE staff.user_id = auth.uid()
      AND staff.role IN ('superadmin', 'admin')
      AND staff.is_active = true
    )
  );

-- ========================================
-- PART 8: Email Queue for Batch Processing
-- ========================================

-- Function to get pending emails (for external service to process)
CREATE OR REPLACE FUNCTION get_pending_emails(batch_size INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  email_type TEXT,
  recipient_email TEXT,
  subject TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    en.id,
    en.email_type,
    en.recipient_email,
    en.subject,
    en.metadata,
    en.created_at
  FROM email_notifications en
  WHERE en.status = 'pending'
  ORDER BY en.created_at ASC
  LIMIT batch_size;
END;
$$;

-- Function to mark email as sent
CREATE OR REPLACE FUNCTION mark_email_sent(email_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE email_notifications
  SET 
    status = 'sent',
    sent_at = NOW()
  WHERE id = email_id;
END;
$$;

-- Function to mark email as failed
CREATE OR REPLACE FUNCTION mark_email_failed(email_id UUID, error_msg TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE email_notifications
  SET 
    status = 'failed',
    error_message = error_msg,
    sent_at = NOW()
  WHERE id = email_id;
END;
$$;

-- ========================================
-- PART 9: TEST QUERIES
-- ========================================

-- ========================================
-- 9.1 Check User Status (For Testing)
-- ========================================
-- Ganti 'your.email@example.com' dengan email test Anda
-- SELECT check_user_for_test_email('your.email@example.com');

-- ========================================
-- 9.2 Test Auth Emails (Use Flutter Client SDK)
-- ========================================
-- IMPORTANT: Auth emails cannot be sent from SQL directly.
-- Use Flutter client code instead:
--
-- // Test verification email (resend)
-- await supabase.auth.resend(
--   type: OtpType.signup,
--   email: 'your.email@example.com',
-- );
--
-- // Test password reset
-- await supabase.auth.resetPasswordForEmail('your.email@example.com');
--
-- OR use Supabase Dashboard:
-- Authentication → Users → [...] → Send password reset email

-- ========================================
-- 9.3 View All Email Notifications (Admin Only)
-- ========================================
-- SELECT 
--   email_type,
--   recipient_email,
--   status,
--   created_at,
--   metadata->>'booking_id' as booking_id
-- FROM email_notifications
-- ORDER BY created_at DESC
-- LIMIT 20;

-- ========================================
-- 9.4 View Failed Emails
-- ========================================
-- SELECT 
--   email_type,
--   recipient_email,
--   error_message,
--   created_at
-- FROM email_notifications
-- WHERE status = 'failed'
-- ORDER BY created_at DESC;

-- ========================================
-- 9.5 Test Booking Approved Trigger
-- ========================================
-- Simulasi approve booking (ganti dengan booking_id yang ada)
-- UPDATE bookings
-- SET status = 'confirmed'
-- WHERE id = 'YOUR_BOOKING_ID_HERE'
--   AND status = 'pending';

-- Cek apakah email notification ter-create
-- SELECT * FROM email_notifications
-- WHERE email_type = 'booking_approved'
-- ORDER BY created_at DESC
-- LIMIT 1;

-- ========================================
-- 9.6 Get Weekly Revenue Report
-- ========================================
-- SELECT * FROM generate_weekly_revenue_report();

-- ========================================
-- 9.7 Get Pending Payment Reminders
-- ========================================
-- SELECT * FROM send_payment_reminders();

-- ========================================
-- 9.8 Get Pending Emails for Processing
-- ========================================
-- SELECT * FROM get_pending_emails(10);

-- ========================================
-- PART 10: GRANT PERMISSIONS
-- ========================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION check_user_for_test_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_weekly_revenue_report() TO authenticated;
GRANT EXECUTE ON FUNCTION send_payment_reminders() TO authenticated;

-- Grant execute permissions to service role
GRANT EXECUTE ON FUNCTION get_pending_emails(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION mark_email_sent(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION mark_email_failed(UUID, TEXT) TO service_role;

-- ========================================
-- SETUP COMPLETE!
-- ========================================

-- Next Steps:
-- 1. Update email templates in Supabase Dashboard:
--    - Go to: Authentication → Email Templates
--    - Copy templates from: docs/EMAIL_TEMPLATES.md
--    
-- 2. Test verification email via Flutter client:
--    await supabase.auth.resend(type: OtpType.signup, email: 'your@email.com');
--
-- 3. Test password reset via Flutter client:
--    await supabase.auth.resetPasswordForEmail('your@email.com');
--
-- 4. Or test via Supabase Dashboard:
--    Authentication → Users → [...] → Send password reset email
--
-- 5. Approve a booking and check email_notifications table:
--    SELECT * FROM email_notifications WHERE email_type = 'booking_approved';
--
-- 6. Setup external email service (optional):
--    - Use Supabase Edge Functions
--    - Or setup cron job to call get_pending_emails() and send via SMTP
--
-- Documentation: docs/EMAIL_TEMPLATES.md
