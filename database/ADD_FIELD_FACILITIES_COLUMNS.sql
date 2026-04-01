-- ========================================
-- MIGRATION: Add Facility Columns to Fields Table
-- ========================================
-- Description: Adds ukuran_lapangan, kapasitas, and facility flags
-- to the fields table for enhanced venue information
-- Date: 2026-02-05
-- ========================================

-- Add new columns to fields table
DO $$ 
BEGIN
  -- Add ukuran_lapangan column (Text)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'ukuran_lapangan'
  ) THEN
    ALTER TABLE fields ADD COLUMN ukuran_lapangan TEXT;
    RAISE NOTICE 'Added column: ukuran_lapangan';
  ELSE
    RAISE NOTICE 'Column ukuran_lapangan already exists';
  END IF;

  -- Add kapasitas column (Text)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'kapasitas'
  ) THEN
    ALTER TABLE fields ADD COLUMN kapasitas TEXT;
    RAISE NOTICE 'Added column: kapasitas';
  ELSE
    RAISE NOTICE 'Column kapasitas already exists';
  END IF;

  -- Add tempat_parkir column (Boolean, default false)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'tempat_parkir'
  ) THEN
    ALTER TABLE fields ADD COLUMN tempat_parkir BOOLEAN DEFAULT false;
    RAISE NOTICE 'Added column: tempat_parkir';
  ELSE
    RAISE NOTICE 'Column tempat_parkir already exists';
  END IF;

  -- Add mushola column (Boolean, default false)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'mushola'
  ) THEN
    ALTER TABLE fields ADD COLUMN mushola BOOLEAN DEFAULT false;
    RAISE NOTICE 'Added column: mushola';
  ELSE
    RAISE NOTICE 'Column mushola already exists';
  END IF;

  -- Add cctv column (Boolean, default false)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'cctv'
  ) THEN
    ALTER TABLE fields ADD COLUMN cctv BOOLEAN DEFAULT false;
    RAISE NOTICE 'Added column: cctv';
  ELSE
    RAISE NOTICE 'Column cctv already exists';
  END IF;

  -- Add ruang_tunggu column (Boolean, default false)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'ruang_tunggu'
  ) THEN
    ALTER TABLE fields ADD COLUMN ruang_tunggu BOOLEAN DEFAULT false;
    RAISE NOTICE 'Added column: ruang_tunggu';
  ELSE
    RAISE NOTICE 'Column ruang_tunggu already exists';
  END IF;

  -- Add ruang_ganti column (Boolean, default false)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fields' AND column_name = 'ruang_ganti'
  ) THEN
    ALTER TABLE fields ADD COLUMN ruang_ganti BOOLEAN DEFAULT false;
    RAISE NOTICE 'Added column: ruang_ganti';
  ELSE
    RAISE NOTICE 'Column ruang_ganti already exists';
  END IF;

END$$;

-- ========================================
-- VERIFICATION: Check if columns were added
-- ========================================

SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'fields'
AND column_name IN (
  'ukuran_lapangan',
  'kapasitas',
  'tempat_parkir',
  'mushola',
  'cctv',
  'ruang_tunggu',
  'ruang_ganti'
)
ORDER BY column_name;

-- ========================================
-- NOTES
-- ========================================
-- 1. This migration is safe to run multiple times (idempotent)
-- 2. Default values for boolean fields are set to false
-- 3. Text fields (ukuran_lapangan, kapasitas) allow NULL values
-- 4. You can update existing records manually or via the admin panel
-- 
-- Example update for existing records:
-- UPDATE fields SET
--   ukuran_lapangan = '16.8m x 24.95m',
--   kapasitas = '14 orang',
--   tempat_parkir = true,
--   mushola = true,
--   cctv = true,
--   ruang_tunggu = true,
--   ruang_ganti = true
-- WHERE id = 'your-field-id';
-- ========================================
