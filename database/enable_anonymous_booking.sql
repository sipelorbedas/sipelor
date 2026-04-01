-- =====================================================
-- SIPELOR BEDAS — Enable Public / Anonymous Booking
-- =====================================================
-- Jalankan script ini di Supabase SQL Editor jika
-- "Anonymous Sign-in" TIDAK diaktifkan di Authentication
-- Settings → Providers → Anonymous.
--
-- CATATAN: Jika Anonymous Auth SUDAH diaktifkan,
-- script ini TIDAK perlu dijalankan.
-- =====================================================

-- 1. Izinkan siapa saja (anon role) INSERT ke bookings
CREATE POLICY IF NOT EXISTS "Anon can create bookings"
  ON bookings FOR INSERT
  TO anon
  WITH CHECK (true);

-- 2. Izinkan siapa saja (anon role) INSERT ke payment_proofs
CREATE POLICY IF NOT EXISTS "Anon can create payment proofs"
  ON payment_proofs FOR INSERT
  TO anon
  WITH CHECK (true);

-- 3. Izinkan anon UPSERT ke profiles (untuk guest profile)
CREATE POLICY IF NOT EXISTS "Anon can upsert guest profile"
  ON profiles FOR INSERT
  TO anon
  WITH CHECK (true);

-- 4. Grant akses ke anon role
GRANT INSERT ON bookings TO anon;
GRANT INSERT ON payment_proofs TO anon;
GRANT INSERT, UPDATE ON profiles TO anon;

-- Verifikasi
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE tablename IN ('bookings', 'payment_proofs', 'profiles')
  AND 'anon' = ANY(roles)
ORDER BY tablename;
