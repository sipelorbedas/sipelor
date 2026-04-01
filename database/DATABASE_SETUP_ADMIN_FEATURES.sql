-- ================================================
-- SIPELOR BEDAS - Admin Features Database Setup
-- ================================================
-- Run this script in Supabase SQL Editor
-- Date: 2026-01-26
-- ================================================

-- 1. STAFF TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'operator', 'manager')),
  assigned_venues UUID[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for staff table
CREATE INDEX IF NOT EXISTS idx_staff_user ON staff(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_email ON staff(email);
CREATE INDEX IF NOT EXISTS idx_staff_active ON staff(is_active);

-- RLS Policies for staff
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage staff" ON staff;
DROP POLICY IF EXISTS "Staff can view themselves" ON staff;

CREATE POLICY "Admins can manage staff" ON staff
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM staff s
      WHERE s.user_id = auth.uid()::uuid
      AND s.role = 'admin'
      AND s.is_active = true
    )
  );

CREATE POLICY "Staff can view themselves" ON staff
  FOR SELECT USING (user_id = auth.uid()::uuid);


-- 2. MAINTENANCE SCHEDULES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  field_id UUID REFERENCES fields(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  assigned_to UUID REFERENCES staff(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for maintenance_schedules table
CREATE INDEX IF NOT EXISTS idx_maintenance_venue ON maintenance_schedules(venue_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_field ON maintenance_schedules(field_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_dates ON maintenance_schedules(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_status ON maintenance_schedules(status);

-- RLS Policies for maintenance_schedules
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view maintenance schedules" ON maintenance_schedules;
DROP POLICY IF EXISTS "Staff can manage maintenance schedules" ON maintenance_schedules;

CREATE POLICY "Anyone can view maintenance schedules" ON maintenance_schedules
  FOR SELECT USING (true);

CREATE POLICY "Staff can manage maintenance schedules" ON maintenance_schedules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM staff s
      WHERE s.user_id = auth.uid()::uuid
      AND s.is_active = true
    )
  );


-- 3. REPORT CONFIGS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS report_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL CHECK (type IN ('revenue', 'bookings', 'performance')),
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly')),
  recipients TEXT[] NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_sent TIMESTAMP,
  next_scheduled TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(type, frequency)
);

-- Indexes for report_configs table
CREATE INDEX IF NOT EXISTS idx_report_configs_active ON report_configs(is_active);
CREATE INDEX IF NOT EXISTS idx_report_configs_scheduled ON report_configs(next_scheduled) WHERE is_active = true;

-- RLS Policies for report_configs
ALTER TABLE report_configs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Only admins can manage report configs" ON report_configs;

CREATE POLICY "Only admins can manage report configs" ON report_configs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM staff s
      WHERE s.user_id = auth.uid()::uuid
      AND s.role = 'admin'
      AND s.is_active = true
    )
  );


-- 4. CHAT MESSAGES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'system')),
  message TEXT NOT NULL,
  image_url TEXT,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for chat_messages table
CREATE INDEX IF NOT EXISTS idx_chat_booking ON chat_messages(booking_id);
CREATE INDEX IF NOT EXISTS idx_chat_sender ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_created ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_unread ON chat_messages(read) WHERE read = false;

-- RLS Policies for chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read their own booking chats" ON chat_messages;
DROP POLICY IF EXISTS "Users and staff can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update read status on their messages" ON chat_messages;

CREATE POLICY "Users can read their own booking chats" ON chat_messages
  FOR SELECT USING (
    auth.uid()::uuid IN (
      SELECT user_id FROM bookings WHERE id = chat_messages.booking_id
    )
    OR EXISTS (
      SELECT 1 FROM staff s
      WHERE s.user_id = auth.uid()::uuid
      AND s.is_active = true
    )
  );

CREATE POLICY "Users and staff can send messages" ON chat_messages
  FOR INSERT WITH CHECK (
    auth.uid()::uuid = sender_id
  );

CREATE POLICY "Users can update read status on their messages" ON chat_messages
  FOR UPDATE USING (
    auth.uid()::uuid IN (
      SELECT user_id FROM bookings WHERE id = chat_messages.booking_id
    )
    OR EXISTS (
      SELECT 1 FROM staff s
      WHERE s.user_id = auth.uid()::uuid
      AND s.is_active = true
    )
  );

-- Enable Realtime for chat_messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;


-- 5. UPDATE FIELDS TABLE (if status column doesn't exist)
-- ================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fields' AND column_name = 'status'
  ) THEN
    ALTER TABLE fields ADD COLUMN status TEXT DEFAULT 'available' CHECK (status IN ('available', 'booked', 'maintenance'));
    CREATE INDEX idx_fields_status ON fields(status);
  END IF;
END$$;


-- 6. FUNCTION: Auto-update updated_at timestamp
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
CREATE TRIGGER update_staff_updated_at
  BEFORE UPDATE ON staff
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_schedules_updated_at
  BEFORE UPDATE ON maintenance_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_configs_updated_at
  BEFORE UPDATE ON report_configs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- 7. INSERT DEFAULT DATA (Optional)
-- ================================================

-- Create admin staff entry for existing admin user (update with actual user_id)
-- INSERT INTO staff (user_id, name, email, role, is_active)
-- VALUES (
--   'YOUR_ADMIN_USER_ID_HERE',
--   'Super Admin',
--   'admin@sipelor.com',
--   'admin',
--   true
-- ) ON CONFLICT (email) DO NOTHING;


-- ================================================
-- SETUP COMPLETE!
-- ================================================
-- Next Steps:
-- 1. Deploy Supabase Edge Function for email reports
-- 2. Setup cron job for automated reports
-- 3. Enable Realtime in Supabase Dashboard for chat_messages table
-- 4. Update admin user_id in INSERT statement above and run it
-- 5. Test all features in the app
-- ================================================
