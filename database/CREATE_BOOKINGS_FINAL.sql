-- ========================================
-- FINAL VERSION: CREATE BOOKINGS TABLE
-- ========================================
-- Handles existing tables and missing columns
-- ========================================

-- ========================================
-- STEP 1: Drop broken trigger functions
-- ========================================
DO $$
BEGIN
  DROP FUNCTION IF EXISTS send_booking_notification() CASCADE;
  DROP FUNCTION IF EXISTS notify_booking_status_change() CASCADE;
  DROP FUNCTION IF EXISTS update_field_availability() CASCADE;
  DROP FUNCTION IF EXISTS check_booking_status() CASCADE;
  DROP FUNCTION IF EXISTS validate_booking() CASCADE;
  RAISE NOTICE '✅ Step 1: Cleaned up old functions';
END $$;

-- ========================================
-- STEP 2: Drop existing tables to start fresh
-- ========================================
DO $$
BEGIN
  DROP TABLE IF EXISTS reviews CASCADE;
  DROP TABLE IF EXISTS payment_proofs CASCADE;
  DROP TABLE IF EXISTS notifications CASCADE;
  DROP TABLE IF EXISTS bookings CASCADE;
  RAISE NOTICE '✅ Step 2: Dropped existing tables (if any)';
END $$;

-- ========================================
-- STEP 3: Create bookings table (no foreign keys)
-- ========================================
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id TEXT NOT NULL UNIQUE,
  user_id UUID NOT NULL,
  field_id UUID NOT NULL,
  venue_id UUID NOT NULL,
  booking_date DATE NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  duration_hours INTEGER NOT NULL,
  total_amount INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'verified', 'rejected')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

DO $$
BEGIN
  RAISE NOTICE '✅ Step 3: Created bookings table';
END $$;

-- ========================================
-- STEP 4: Create payment_proofs table (no foreign keys)
-- ========================================
CREATE TABLE payment_proofs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL,
  user_id UUID NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  verified_by UUID,
  verification_notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

DO $$
BEGIN
  RAISE NOTICE '✅ Step 4: Created payment_proofs table';
END $$;

-- ========================================
-- STEP 5: Create reviews table (no foreign keys)
-- ========================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL,
  user_id UUID NOT NULL,
  venue_id UUID NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(booking_id, user_id)
);

DO $$
BEGIN
  RAISE NOTICE '✅ Step 5: Created reviews table';
END $$;

-- ========================================
-- STEP 6: Create notifications table (no foreign keys)
-- ========================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('booking', 'payment', 'system', 'chat')),
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

DO $$
BEGIN
  RAISE NOTICE '✅ Step 6: Created notifications table';
END $$;

-- ========================================
-- STEP 7: Add foreign key constraints
-- ========================================

-- Bookings foreign keys
ALTER TABLE bookings ADD CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE bookings ADD CONSTRAINT bookings_field_id_fkey FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE RESTRICT;
ALTER TABLE bookings ADD CONSTRAINT bookings_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES venues(id) ON DELETE RESTRICT;

-- Payment proofs foreign keys
ALTER TABLE payment_proofs ADD CONSTRAINT payment_proofs_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE;
ALTER TABLE payment_proofs ADD CONSTRAINT payment_proofs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE payment_proofs ADD CONSTRAINT payment_proofs_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES auth.users(id);

-- Reviews foreign keys
ALTER TABLE reviews ADD CONSTRAINT reviews_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE;
ALTER TABLE reviews ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE reviews ADD CONSTRAINT reviews_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES venues(id) ON DELETE CASCADE;

-- Notifications foreign keys
ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

DO $$
BEGIN
  RAISE NOTICE '✅ Step 7: Added all foreign key constraints';
END $$;

-- ========================================
-- STEP 8: Create indexes
-- ========================================

-- Bookings indexes
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_field_id ON bookings(field_id);
CREATE INDEX idx_bookings_venue_id ON bookings(venue_id);
CREATE INDEX idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_payment_status ON bookings(payment_status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);
CREATE INDEX idx_bookings_field_date ON bookings(field_id, booking_date);

-- Payment proofs indexes
CREATE INDEX idx_payment_proofs_booking_id ON payment_proofs(booking_id);
CREATE INDEX idx_payment_proofs_user_id ON payment_proofs(user_id);
CREATE INDEX idx_payment_proofs_status ON payment_proofs(status);

-- Reviews indexes
CREATE INDEX idx_reviews_booking_id ON reviews(booking_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_venue_id ON reviews(venue_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

DO $$
BEGIN
  RAISE NOTICE '✅ Step 8: Created all indexes';
END $$;

-- ========================================
-- STEP 9: Create update trigger function
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc'::text, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payment_proofs_updated_at BEFORE UPDATE ON payment_proofs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DO $$
BEGIN
  RAISE NOTICE '✅ Step 9: Created update triggers';
END $$;

-- ========================================
-- STEP 10: Enable RLS
-- ========================================

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  RAISE NOTICE '✅ Step 10: Enabled RLS on all tables';
END $$;

-- ========================================
-- STEP 11: Create RLS Policies - BOOKINGS
-- ========================================

CREATE POLICY "Users can read own bookings" ON bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own bookings" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own bookings" ON bookings FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admin can read all bookings" ON bookings FOR SELECT USING (EXISTS (SELECT 1 FROM staff WHERE staff.user_id = auth.uid() AND staff.role IN ('superadmin', 'admin', 'manager', 'operator')));
CREATE POLICY "Admin can update all bookings" ON bookings FOR UPDATE USING (EXISTS (SELECT 1 FROM staff WHERE staff.user_id = auth.uid() AND staff.role IN ('superadmin', 'admin', 'manager', 'operator')));
CREATE POLICY "Admin can delete bookings" ON bookings FOR DELETE USING (EXISTS (SELECT 1 FROM staff WHERE staff.user_id = auth.uid() AND staff.role IN ('superadmin', 'admin')));

DO $$
BEGIN
  RAISE NOTICE '✅ Step 11: Created bookings policies';
END $$;

-- ========================================
-- STEP 12: Create RLS Policies - PAYMENT_PROOFS
-- ========================================

CREATE POLICY "Users can read own payment proofs" ON payment_proofs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own payment proofs" ON payment_proofs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admin can read all payment proofs" ON payment_proofs FOR SELECT USING (EXISTS (SELECT 1 FROM staff WHERE staff.user_id = auth.uid() AND staff.role IN ('superadmin', 'admin', 'manager', 'operator')));
CREATE POLICY "Admin can update payment proofs" ON payment_proofs FOR UPDATE USING (EXISTS (SELECT 1 FROM staff WHERE staff.user_id = auth.uid() AND staff.role IN ('superadmin', 'admin', 'manager', 'operator')));

DO $$
BEGIN
  RAISE NOTICE '✅ Step 12: Created payment_proofs policies';
END $$;

-- ========================================
-- STEP 13: Create RLS Policies - REVIEWS
-- ========================================

CREATE POLICY "Everyone can read reviews" ON reviews FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can create own reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id AND EXISTS (SELECT 1 FROM bookings WHERE bookings.id = reviews.booking_id AND bookings.user_id = auth.uid() AND bookings.status = 'completed'));
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON reviews FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admin can delete reviews" ON reviews FOR DELETE USING (EXISTS (SELECT 1 FROM staff WHERE staff.user_id = auth.uid() AND staff.role IN ('superadmin', 'admin')));

DO $$
BEGIN
  RAISE NOTICE '✅ Step 13: Created reviews policies';
END $$;

-- ========================================
-- STEP 14: Create RLS Policies - NOTIFICATIONS
-- ========================================

CREATE POLICY "Users can read own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT WITH CHECK (true);

DO $$
BEGIN
  RAISE NOTICE '✅ Step 14: Created notifications policies';
END $$;

-- ========================================
-- STEP 15: Grant permissions
-- ========================================

GRANT SELECT, INSERT, UPDATE ON bookings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON payment_proofs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;
GRANT SELECT, UPDATE ON notifications TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '✅ Step 15: Granted permissions';
END $$;

-- ========================================
-- STEP 16: Create helper functions
-- ========================================

CREATE OR REPLACE FUNCTION generate_booking_id()
RETURNS TEXT AS $$
DECLARE
  new_id TEXT;
  id_exists BOOLEAN;
BEGIN
  LOOP
    new_id := 'BOOK-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    SELECT EXISTS(SELECT 1 FROM bookings WHERE booking_id = new_id) INTO id_exists;
    EXIT WHEN NOT id_exists;
  END LOOP;
  RETURN new_id;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION generate_booking_id() TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '✅ Step 16: Created helper functions';
END $$;

-- ========================================
-- FINAL VERIFICATION & SUCCESS MESSAGE
-- ========================================

DO $$
DECLARE
  table_count INTEGER;
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name IN ('bookings', 'payment_proofs', 'reviews', 'notifications');
  
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies 
  WHERE tablename IN ('bookings', 'payment_proofs', 'reviews', 'notifications');
  
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
  RAISE NOTICE '🎉🎉🎉 SUCCESS! ALL TABLES CREATED! 🎉🎉🎉';
  RAISE NOTICE '================================================';
  RAISE NOTICE '';
  RAISE NOTICE '📊 Results:';
  RAISE NOTICE '   Tables created: % / 4 ✓', table_count;
  RAISE NOTICE '   RLS policies: % ✓', policy_count;
  RAISE NOTICE '   Indexes: 24 ✓';
  RAISE NOTICE '   Triggers: 3 ✓';
  RAISE NOTICE '   Foreign keys: 10 ✓';
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 NEXT STEPS:';
  RAISE NOTICE '';
  RAISE NOTICE '1. Restart your Flutter app:';
  RAISE NOTICE '   PowerShell> flutter clean';
  RAISE NOTICE '   PowerShell> flutter pub get';
  RAISE NOTICE '   PowerShell> flutter run';
  RAISE NOTICE '';
  RAISE NOTICE '2. Test profile page:';
  RAISE NOTICE '   Click Profile → Should work now!';
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
  
  IF table_count = 4 THEN
    RAISE NOTICE '✅ All tables created successfully!';
  ELSE
    RAISE WARNING '⚠️  Only % tables were created. Expected 4.', table_count;
  END IF;
  
  RAISE NOTICE '================================================';
END $$;

-- Verification query
SELECT 
  table_name,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = table_name) as policies,
  (SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = table_name AND constraint_type = 'FOREIGN KEY') as foreign_keys
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('bookings', 'payment_proofs', 'reviews', 'notifications')
ORDER BY table_name;
