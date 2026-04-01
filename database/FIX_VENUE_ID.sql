-- ========================================
-- FIX: NULL venue_id in fields table
-- ========================================
-- Problem: All fields have venue_id = NULL, causing booking errors
-- Solution: Create venue and link all fields to it
-- ========================================

-- STEP 1: Check if "STADION JALAK HARUPAT" venue exists
SELECT id, name, type, address, description 
FROM venues 
WHERE LOWER(name) LIKE '%jalak harupat%';

-- If no venue exists, create it:
-- STEP 2: Create the venue (if it doesn't exist)
-- Replace the UUID below or let the database generate one
INSERT INTO venues (
  id,
  name,
  type,
  address,
  description,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(), -- Or use a specific UUID like '550e8400-e29b-41d4-a716-446655440000'
  'STADION JALAK HARUPAT',
  'Stadion',
  'Jalak Harupat', -- Update with full address if available
  'Stadion olahraga untuk berbagai pertandingan liga',
  NOW(),
  NOW()
)
RETURNING id, name;

-- STEP 3: After creating the venue, copy the venue ID from the result above
-- Then update all fields to use that venue_id
-- Replace <venue_id_from_step_2> with the actual UUID returned from step 2

-- Example: If the venue ID from step 2 is '550e8400-e29b-41d4-a716-446655440000'
UPDATE fields 
SET 
  venue_id = '550e8400-e29b-41d4-a716-446655440000', -- Replace with actual venue ID
  updated_at = NOW()
WHERE venue_name = 'STADION JALAK HARUPAT'
  AND venue_id IS NULL;

-- STEP 4: Verify the fix - check that all fields now have venue_id
SELECT 
  f.id,
  f.area,
  f.venue_name,
  f.venue_id,
  v.name as actual_venue_name,
  v.type as venue_type
FROM fields f
LEFT JOIN venues v ON f.venue_id = v.id
WHERE f.venue_name = 'STADION JALAK HARUPAT';

-- Expected result: All records should show venue_id and actual_venue_name populated

-- STEP 5: Check for any remaining NULL venue_ids
SELECT 
  id,
  area,
  venue_name,
  venue_id
FROM fields
WHERE venue_id IS NULL;

-- If any fields still have NULL venue_id, they need to be linked to appropriate venues

-- ========================================
-- ALTERNATIVE: Quick fix if you know the venue already exists
-- ========================================
-- If you already have a venue in the venues table, run this:

-- 1. First, find the venue ID:
SELECT id, name, type FROM venues ORDER BY name;

-- 2. Then update all fields with that venue ID:
-- UPDATE fields 
-- SET venue_id = '<existing_venue_id>', updated_at = NOW()
-- WHERE venue_name = 'STADION JALAK HARUPAT' AND venue_id IS NULL;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check all venues
SELECT id, name, type, address FROM venues ORDER BY name;

-- Check all fields with their venue relationships
SELECT 
  f.id as field_id,
  f.area,
  f.venue_name,
  f.venue_type,
  f.venue_id,
  v.name as linked_venue_name
FROM fields f
LEFT JOIN venues v ON f.venue_id = v.id
ORDER BY f.venue_name, f.area;

-- Count fields by venue status
SELECT 
  CASE 
    WHEN venue_id IS NULL THEN 'NULL venue_id (NEEDS FIX)'
    ELSE 'Has venue_id (OK)'
  END as status,
  COUNT(*) as count
FROM fields
GROUP BY 
  CASE 
    WHEN venue_id IS NULL THEN 'NULL venue_id (NEEDS FIX)'
    ELSE 'Has venue_id (OK)'
  END;
