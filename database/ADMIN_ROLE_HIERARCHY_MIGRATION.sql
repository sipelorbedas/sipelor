-- ================================================
-- ADMIN ROLE HIERARCHY - SQL MIGRATION
-- ================================================
-- Purpose: Add role hierarchy with Superadmin and Admin permissions
-- Superadmin: Full access to all features
-- Admin: Limited access (Dashboard, Kelola Lapangan, Time Slots, Chat, Review, Laporan)
-- ================================================

-- Step 1a: Add 'superadmin' to enum type (if exists)
-- IMPORTANT: This must be in a SEPARATE transaction from usage
-- PostgreSQL requires enum values to be committed before use
DO $$
BEGIN
  -- Check if user_role ENUM type exists
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    -- Add 'superadmin' to the existing enum if not already present
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum 
      WHERE enumtypid = 'user_role'::regtype 
      AND enumlabel = 'superadmin'
    ) THEN
      -- Add the new enum value
      -- NOTE: Cannot be run inside a transaction with other commands that use it
      ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'superadmin';
      RAISE NOTICE 'Added superadmin to user_role enum - COMMIT REQUIRED';
      RAISE NOTICE 'Please run the rest of the migration after this completes';
    ELSE
      RAISE NOTICE 'superadmin already exists in user_role enum';
    END IF;
  ELSE
    RAISE NOTICE 'user_role enum does not exist - using TEXT with CHECK constraint';
  END IF;
END $$;

-- ⚠️ IMPORTANT: If the above added 'superadmin' to enum, STOP HERE
-- Run this script, wait for it to complete, then run Step 1b below separately

-- Step 1b: Update constraints (run AFTER Step 1a completes)
-- Drop and recreate CHECK constraint if using TEXT type
DO $$
BEGIN
  -- Drop existing CHECK constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE table_name = 'profiles' 
    AND column_name = 'role'
    AND constraint_name LIKE '%role%check%'
  ) THEN
    ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
    RAISE NOTICE 'Dropped existing profiles_role_check constraint';
  END IF;
  
  -- Add new constraint with 'superadmin' and 'admin'
  -- Only if the column is TEXT type (not ENUM)
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    ALTER TABLE profiles 
    ADD CONSTRAINT profiles_role_check 
    CHECK (role IN ('user', 'admin', 'superadmin'));
    RAISE NOTICE 'Added profiles_role_check constraint with superadmin';
  ELSE
    RAISE NOTICE 'Column uses enum type - no CHECK constraint needed';
  END IF;
END $$;

-- Step 2: Update existing admin users to specific roles
-- OPTION A: Keep existing admins as 'admin' (limited access)
-- No action needed - existing 'admin' users remain as 'admin'

-- OPTION B: Promote specific admin to 'superadmin'
-- Replace 'admin@example.com' with actual admin email
-- UPDATE profiles 
-- SET role = 'superadmin' 
-- WHERE email = 'admin@example.com' AND role = 'admin';

-- Step 3: Update RLS policies to recognize both 'admin' and 'superadmin'
-- Drop and recreate policies that check for admin role

-- For chat_messages table
DROP POLICY IF EXISTS "Admins can read all messages" ON chat_messages;
CREATE POLICY "Admins can read all messages" ON chat_messages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role IN ('admin', 'superadmin')
  )
);

-- For bookings table (if policies exist)
DROP POLICY IF EXISTS "Admins can read all bookings" ON bookings;
CREATE POLICY "Admins can read all bookings" ON bookings
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role IN ('admin', 'superadmin')
  )
);

DROP POLICY IF EXISTS "Admins can update bookings" ON bookings;
CREATE POLICY "Admins can update bookings" ON bookings
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role IN ('admin', 'superadmin')
  )
)
WITH CHECK (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role IN ('admin', 'superadmin')
  )
);

-- For reviews table
DROP POLICY IF EXISTS "Admins can manage all reviews" ON reviews;
CREATE POLICY "Admins can manage all reviews" ON reviews
FOR ALL
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role IN ('admin', 'superadmin')
  )
)
WITH CHECK (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role IN ('admin', 'superadmin')
  )
);

-- For fields table
DROP POLICY IF EXISTS "Admins can manage fields" ON fields;
CREATE POLICY "Admins can manage fields" ON fields
FOR ALL
TO authenticated
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

-- For time_slots table (if exists)
DROP POLICY IF EXISTS "Admins can manage time slots" ON time_slots;
CREATE POLICY "Admins can manage time slots" ON time_slots
FOR ALL
TO authenticated
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

-- For audit_logs table (Superadmin only)
DROP POLICY IF EXISTS "Superadmin can read audit logs" ON audit_logs;
CREATE POLICY "Superadmin can read audit logs" ON audit_logs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'superadmin'
  )
);

-- Step 4: Create helper function to check user role
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'superadmin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'superadmin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role FROM profiles
    WHERE id = auth.uid()
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Verification queries
-- Check current roles in the system
SELECT 
  role, 
  COUNT(*) as user_count 
FROM profiles 
GROUP BY role 
ORDER BY role;

-- List all admin and superadmin users
SELECT 
  id, 
  email, 
  full_name, 
  role,
  created_at
FROM profiles
WHERE role IN ('admin', 'superadmin')
ORDER BY role DESC, created_at DESC;

-- Verify RLS policies
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  roles, 
  cmd 
FROM pg_policies 
WHERE policyname LIKE '%admin%' OR policyname LIKE '%superadmin%'
ORDER BY tablename, policyname;

-- ================================================
-- MANUAL ACTION REQUIRED
-- ================================================
-- After running this migration:
-- 1. Identify which existing admin should be promoted to 'superadmin'
-- 2. Run: UPDATE profiles SET role = 'superadmin' WHERE email = 'your-admin@email.com';
-- 3. Test login as superadmin - should see all menu items
-- 4. Test login as admin - should see limited menu items
-- ================================================

-- ================================================
-- ROLE PERMISSIONS MATRIX
-- ================================================
-- Feature                  | Superadmin | Admin
-- -------------------------|------------|-------
-- Dashboard                | ✓          | ✓
-- Analytics & Reports      | ✓          | ✗
-- Kelola Lapangan          | ✓          | ✓
-- Time Slots               | ✓          | ✓
-- Audit Logs               | ✓          | ✗
-- Review Masukan           | ✓          | ✓
-- Chat                     | ✓          | ✓
-- Laporan (Future)         | ✓          | ✓
-- ================================================
