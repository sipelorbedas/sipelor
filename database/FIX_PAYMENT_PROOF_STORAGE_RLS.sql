-- ============================================
-- FIX PAYMENT PROOF STORAGE RLS POLICY
-- ============================================
-- Problem: Admin tidak bisa lihat gambar bukti pembayaran
-- Solution: Fix RLS policies untuk storage bucket 'payment-proofs'
-- 
-- Cara pakai:
-- 1. Login ke Supabase Dashboard
-- 2. Buka SQL Editor
-- 3. Copy-paste script ini
-- 4. Klik RUN
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║     🔧 FIXING PAYMENT PROOF STORAGE RLS POLICIES          ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ This script will:                                         ║';
    RAISE NOTICE '║ 1. Enable RLS on payment-proofs storage bucket            ║';
    RAISE NOTICE '║ 2. Create policy for users to upload their proofs         ║';
    RAISE NOTICE '║ 3. Create policy for admins to view all proofs            ║';
    RAISE NOTICE '║ 4. Create policy for users to view their own proofs       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ============================================
-- STEP 1: DROP EXISTING STORAGE POLICIES
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 STEP 1: Dropping existing storage policies...';
    RAISE NOTICE '-------------------------------------------';
END $$;

-- Drop all existing policies on payment-proofs bucket
DROP POLICY IF EXISTS "Users can upload own payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for payment proofs" ON storage.objects;

DO $$ 
BEGIN
    RAISE NOTICE '✅ Old storage policies dropped';
END $$;

-- ============================================
-- STEP 2: CREATE NEW STORAGE POLICIES
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 STEP 2: Creating new storage policies...';
    RAISE NOTICE '-------------------------------------------';
END $$;

-- Policy 1: Users can upload their own payment proofs
CREATE POLICY "Users can upload own payment proofs"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'payment-proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Users can view their own payment proofs
CREATE POLICY "Users can view own payment proofs"
ON storage.objects FOR SELECT TO authenticated
USING (
    bucket_id = 'payment-proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Admins can view ALL payment proofs
CREATE POLICY "Admins can view all payment proofs"
ON storage.objects FOR SELECT TO authenticated
USING (
    bucket_id = 'payment-proofs' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

-- Policy 4: Admins can delete payment proofs (optional, for cleanup)
CREATE POLICY "Admins can delete payment proofs"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'payment-proofs' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

DO $$ 
BEGIN
    RAISE NOTICE '✅ Storage policies created successfully';
END $$;

-- ============================================
-- STEP 3: VERIFY BUCKET EXISTS AND RLS ENABLED
-- ============================================
DO $$ 
DECLARE
    bucket_exists BOOLEAN;
    rls_enabled BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 STEP 3: Verifying bucket configuration...';
    RAISE NOTICE '-------------------------------------------';
    
    -- Check if bucket exists
    SELECT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'payment-proofs'
    ) INTO bucket_exists;
    
    IF NOT bucket_exists THEN
        RAISE WARNING '⚠️  Bucket "payment-proofs" does not exist!';
        RAISE NOTICE '💡 Creating bucket...';
        
        -- Create bucket if not exists
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'payment-proofs',
            'payment-proofs',
            false, -- NOT public, use signed URLs
            5242880, -- 5MB limit
            ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
        );
        
        RAISE NOTICE '✅ Bucket created successfully';
    ELSE
        RAISE NOTICE '✅ Bucket exists';
        
        -- Check if RLS is enabled
        SELECT public INTO rls_enabled
        FROM storage.buckets 
        WHERE id = 'payment-proofs';
        
        IF rls_enabled THEN
            RAISE WARNING '⚠️  Bucket is set to PUBLIC!';
            RAISE NOTICE '💡 Changing to PRIVATE for better security...';
            
            UPDATE storage.buckets 
            SET public = false 
            WHERE id = 'payment-proofs';
            
            RAISE NOTICE '✅ Bucket set to private';
        ELSE
            RAISE NOTICE '✅ Bucket is private (secure)';
        END IF;
    END IF;
END $$;

-- ============================================
-- STEP 4: LIST ALL STORAGE POLICIES
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📜 STEP 4: Current storage policies for payment-proofs:';
    RAISE NOTICE '-------------------------------------------';
END $$;

SELECT 
    policyname AS "Policy Name",
    cmd AS "Command",
    permissive AS "Type"
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND (
    policyname ILIKE '%payment%proof%' OR
    qual::text LIKE '%payment-proofs%' OR
    with_check::text LIKE '%payment-proofs%'
  )
ORDER BY policyname;

-- ============================================
-- FINAL STATUS
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                    ✅ FIX COMPLETED!                       ║';
    RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
    RAISE NOTICE '║ Storage RLS policies have been updated successfully.      ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ What to do next:                                          ║';
    RAISE NOTICE '║ 1. Restart your Flutter app                               ║';
    RAISE NOTICE '║ 2. Login as admin                                         ║';
    RAISE NOTICE '║ 3. Open admin dashboard booking table                     ║';
    RAISE NOTICE '║ 4. Click "Lihat Bukti" on any booking                     ║';
    RAISE NOTICE '║ 5. Payment proof images should now display! ✅            ║';
    RAISE NOTICE '║                                                            ║';
    RAISE NOTICE '║ Security notes:                                           ║';
    RAISE NOTICE '║ - Bucket is private (not public)                          ║';
    RAISE NOTICE '║ - Users can only upload to their own folder               ║';
    RAISE NOTICE '║ - Users can only view their own proofs                    ║';
    RAISE NOTICE '║ - Admins can view all proofs                              ║';
    RAISE NOTICE '║ - Signed URLs are used for secure access                  ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;
