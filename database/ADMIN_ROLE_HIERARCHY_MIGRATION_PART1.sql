-- ================================================
-- ADMIN ROLE HIERARCHY - PART 1: Add Enum Value
-- ================================================
-- ⚠️ IMPORTANT: Run this FIRST, wait for completion
-- Then run PART 2 in a separate SQL execution
-- ================================================

-- Add 'superadmin' to user_role enum (if enum exists)
-- This MUST be committed before it can be used
DO $$
BEGIN
  -- Check if user_role ENUM type exists
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    -- Check if 'superadmin' already exists
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum 
      WHERE enumtypid = 'user_role'::regtype 
      AND enumlabel = 'superadmin'
    ) THEN
      -- Add the new enum value
      ALTER TYPE user_role ADD VALUE 'superadmin';
      RAISE NOTICE '✅ Added superadmin to user_role enum';
      RAISE NOTICE '⚠️  Please wait for this to complete, then run PART 2';
    ELSE
      RAISE NOTICE '✅ superadmin already exists in user_role enum';
      RAISE NOTICE '✅ You can proceed to run PART 2';
    END IF;
  ELSE
    RAISE NOTICE 'ℹ️  user_role is not an enum type';
    RAISE NOTICE '✅ You can proceed to run PART 2';
  END IF;
END $$;

-- ================================================
-- Verification: Check enum values
-- ================================================
SELECT 
  enumlabel as role_value,
  enumsortorder as sort_order
FROM pg_enum 
WHERE enumtypid = 'user_role'::regtype
ORDER BY enumsortorder;

-- Expected output: user, admin, superadmin
-- ================================================
-- NEXT STEP: Run ADMIN_ROLE_HIERARCHY_MIGRATION_PART2.sql
-- ================================================
