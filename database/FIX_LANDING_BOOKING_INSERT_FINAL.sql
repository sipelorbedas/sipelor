-- =====================================================
-- SIPELOR BEDAS — Fix Booking Landing Page Tidak Muncul di Admin
-- =====================================================
-- Masalah: Booking dari landing/booking.html tidak muncul
-- di admin dashboard karena INSERT ke tabel bookings GAGAL.
--
-- Penyebab:
--   1. RLS policy INSERT mensyaratkan auth.uid() = user_id,
--      padahal "Anonymous Sign-in" belum aktif di Supabase
--      → auth.uid() = NULL → policy check selalu FALSE.
--   2. FK constraint user_id → auth.users(id) menolak UUID
--      random (fallback saat anonymous auth mati).
--
-- Solusi:
--   A. Buat fungsi RPC SECURITY DEFINER yang bypass RLS sepenuhnya.
--   B. Tambah policy INSERT untuk role `anon` (fallback).
--   C. Tambah policy INSERT untuk role `authenticated`
--      (saat anonymous auth aktif / user sudah login).
--   D. Hapus FK constraint user_id jika ada (agar random UUID diterima).
--   E. Pastikan admin bisa SELECT semua booking.
--
-- Cara pakai:
--   1. Buka Supabase Dashboard → SQL Editor
--   2. Paste seluruh script ini, klik Run
--   3. Refresh halaman admin
-- =====================================================


-- ═══════════════════════════════════════════════════
-- STEP 1: Hapus FK constraint user_id (jika ada)
-- Memungkinkan random UUID sebagai fallback user_id
-- ═══════════════════════════════════════════════════
DO $$
BEGIN
  ALTER TABLE public.bookings
    DROP CONSTRAINT IF EXISTS bookings_user_id_fkey;
  RAISE NOTICE '✅ Step 1: FK bookings_user_id_fkey dihapus (atau tidak ada)';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️  Step 1 warning: %', SQLERRM;
END $$;


-- ═══════════════════════════════════════════════════
-- STEP 2: Hapus policy INSERT lama yang konflik
-- ═══════════════════════════════════════════════════
DROP POLICY IF EXISTS "Users can create bookings"             ON public.bookings;
DROP POLICY IF EXISTS "Users can create own bookings"         ON public.bookings;
DROP POLICY IF EXISTS "Anon can create bookings"              ON public.bookings;
DROP POLICY IF EXISTS "Authenticated can create bookings"     ON public.bookings;
DROP POLICY IF EXISTS "Authenticated can insert own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow insert for authenticated"        ON public.bookings;
DROP POLICY IF EXISTS "Anon can insert bookings"              ON public.bookings;


-- ═══════════════════════════════════════════════════
-- STEP 3: Policy INSERT untuk authenticated
-- (saat signInAnonymously() berhasil)
-- ═══════════════════════════════════════════════════
CREATE POLICY "Authenticated can insert own bookings"
  ON public.bookings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid()::text = user_id::text);


-- ═══════════════════════════════════════════════════
-- STEP 4: Policy INSERT untuk anon role
-- (saat signInAnonymously() gagal / tidak diaktifkan)
-- ═══════════════════════════════════════════════════
CREATE POLICY "Anon can insert bookings"
  ON public.bookings
  FOR INSERT
  TO anon
  WITH CHECK (true);


-- ═══════════════════════════════════════════════════
-- STEP 5: Grant INSERT ke kedua role
-- ═══════════════════════════════════════════════════
GRANT INSERT ON public.bookings TO authenticated;
GRANT INSERT ON public.bookings TO anon;


-- ═══════════════════════════════════════════════════
-- STEP 6: Buat RPC SECURITY DEFINER (solusi paling robust)
-- Fungsi ini bypass RLS sepenuhnya dan berjalan sebagai
-- pemilik fungsi (postgres/superuser).
-- Dipanggil dari booking.js sebagai strategi utama.
-- ═══════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.create_booking_from_landing(
  p_booking_id      TEXT,
  p_user_id         TEXT,
  p_field_id        TEXT,
  p_venue_id        TEXT,
  p_booking_date    TEXT,
  p_start_time      TEXT,
  p_end_time        TEXT,
  p_duration_hours  INTEGER,
  p_total_amount    INTEGER,
  p_notes           TEXT DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_booking json;
BEGIN
  INSERT INTO public.bookings (
    booking_id,
    user_id,
    field_id,
    venue_id,
    booking_date,
    start_time,
    end_time,
    duration_hours,
    total_amount,
    status,
    payment_status,
    notes,
    created_at,
    updated_at
  )
  VALUES (
    p_booking_id,
    p_user_id::uuid,
    p_field_id::uuid,
    p_venue_id::uuid,
    p_booking_date::date,
    p_start_time,
    p_end_time,
    p_duration_hours,
    p_total_amount,
    'pending',
    'pending',
    p_notes,
    NOW(),
    NOW()
  )
  RETURNING to_json(bookings.*) INTO new_booking;

  RETURN new_booking;

EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'create_booking_from_landing error: %', SQLERRM;
END;
$$;

-- Grant execute ke semua role (anon = tidak login, authenticated = sudah login)
GRANT EXECUTE ON FUNCTION public.create_booking_from_landing
  TO anon, authenticated;


-- ═══════════════════════════════════════════════════
-- STEP 7: Fix admin SELECT policies untuk bookings
-- ═══════════════════════════════════════════════════
DROP POLICY IF EXISTS "Admin can read all bookings"  ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can read own bookings"  ON public.bookings;

-- User baca booking milik sendiri
CREATE POLICY "Users can read own bookings"
  ON public.bookings
  FOR SELECT
  TO authenticated
  USING (auth.uid()::text = user_id::text);

-- Admin / staff baca SEMUA booking
CREATE POLICY "Admin can read all bookings"
  ON public.bookings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id::text = auth.uid()::text
        AND p.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;


-- ═══════════════════════════════════════════════════
-- STEP 8: Fix admin SELECT policies untuk payment_proofs
-- ═══════════════════════════════════════════════════
DROP POLICY IF EXISTS "Admin can read all payment proofs"   ON public.payment_proofs;
DROP POLICY IF EXISTS "Admin can read all payment_proofs"   ON public.payment_proofs;
DROP POLICY IF EXISTS "Admins can read all payment proofs"  ON public.payment_proofs;
DROP POLICY IF EXISTS "Users can read own payment_proofs"   ON public.payment_proofs;
DROP POLICY IF EXISTS "Users can read own payment proofs"   ON public.payment_proofs;

-- User baca bukti bayar booking milik sendiri
CREATE POLICY "Users can read own payment proofs"
  ON public.payment_proofs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id::text = booking_id::text
        AND b.user_id::text = auth.uid()::text
    )
  );

-- Admin / staff baca SEMUA bukti bayar
CREATE POLICY "Admin can read all payment proofs"
  ON public.payment_proofs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id::text = auth.uid()::text
        AND p.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- Izinkan anon INSERT bukti bayar (upload bukti transfer)
DROP POLICY IF EXISTS "Anon can create payment proofs" ON public.payment_proofs;
CREATE POLICY "Anon can create payment proofs"
  ON public.payment_proofs
  FOR INSERT
  TO anon
  WITH CHECK (true);

GRANT INSERT ON public.payment_proofs TO anon;
GRANT INSERT ON public.payment_proofs TO authenticated;

ALTER TABLE public.payment_proofs ENABLE ROW LEVEL SECURITY;


-- ═══════════════════════════════════════════════════
-- STEP 9: Izinkan anon UPSERT ke profiles (guest profile)
-- ═══════════════════════════════════════════════════
DROP POLICY IF EXISTS "Anon can upsert guest profile" ON public.profiles;
CREATE POLICY "Anon can upsert guest profile"
  ON public.profiles
  FOR INSERT
  TO anon
  WITH CHECK (true);

GRANT INSERT, UPDATE ON public.profiles TO anon;


-- ═══════════════════════════════════════════════════
-- VERIFIKASI — tampilkan semua policy aktif
-- ═══════════════════════════════════════════════════
SELECT
  tablename,
  policyname,
  cmd        AS operation,
  roles,
  permissive
FROM pg_policies
WHERE tablename IN ('bookings', 'payment_proofs', 'profiles')
ORDER BY tablename, cmd, policyname;
