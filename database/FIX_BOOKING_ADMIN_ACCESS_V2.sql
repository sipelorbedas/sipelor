-- ============================================================
-- FIX ADMIN BOOKING ACCESS — V2 (Consolidated)
-- ============================================================
-- Masalah yang diselesaikan:
--   1. Data pemesanan tidak muncul di admin panel
--   2. Role manager/operator bisa login tapi tidak bisa lihat data
--      (kebijakan lama hanya izinkan admin/superadmin)
--   3. Kebijakan lama menggunakan tabel 'staff', namun app.js
--      membaca role dari tabel 'profiles'
--
-- Cara pakai:
--   1. Buka Supabase Dashboard → SQL Editor
--   2. Copy-paste seluruh script ini → klik RUN
-- ============================================================

DO $$ BEGIN
  RAISE NOTICE '╔══════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║  FIX BOOKING ADMIN ACCESS V2 — mulai eksekusi...            ║';
  RAISE NOTICE '╚══════════════════════════════════════════════════════════════╝';
END $$;

-- ────────────────────────────────────────────────────────────
-- STEP 1: Hapus semua policy lama di tabel bookings
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE r RECORD;
BEGIN
  RAISE NOTICE '🔧 STEP 1: Menghapus semua policy lama pada tabel bookings...';
  FOR r IN (
    SELECT policyname FROM pg_policies
    WHERE tablename = 'bookings' AND schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON bookings', r.policyname);
    RAISE NOTICE '   ✓ Dihapus: %', r.policyname;
  END LOOP;
  RAISE NOTICE '✅ Semua policy lama bookings dihapus';
END $$;

-- ────────────────────────────────────────────────────────────
-- STEP 2: Buat ulang policy bookings
--   Pengguna biasa: CRUD milik sendiri
--   Admin roles (dari profiles.role): akses semua data
--   Roles yang didukung: admin, superadmin, manager, operator
--   (sesuai dengan checkAuth di app.js)
-- ────────────────────────────────────────────────────────────

-- Pengguna: lihat booking milik sendiri
CREATE POLICY "Users can read own bookings"
  ON bookings FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Pengguna: buat booking milik sendiri
CREATE POLICY "Users can create own bookings"
  ON bookings FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Pengguna: update booking milik sendiri
CREATE POLICY "Users can update own bookings"
  ON bookings FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admin (semua role admin): lihat SEMUA booking
CREATE POLICY "Admins can read all bookings"
  ON bookings FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- Admin (semua role admin): update SEMUA booking
CREATE POLICY "Admins can update all bookings"
  ON bookings FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- Hanya admin/superadmin: hapus booking
CREATE POLICY "Admins can delete bookings"
  ON bookings FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

DO $$ BEGIN
  RAISE NOTICE '✅ STEP 2: Policy bookings berhasil dibuat (6 policy)';
END $$;

-- ────────────────────────────────────────────────────────────
-- STEP 3: Hapus semua policy lama di tabel payment_proofs
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE r RECORD;
BEGIN
  RAISE NOTICE '🔧 STEP 3: Menghapus semua policy lama pada tabel payment_proofs...';
  FOR r IN (
    SELECT policyname FROM pg_policies
    WHERE tablename = 'payment_proofs' AND schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON payment_proofs', r.policyname);
    RAISE NOTICE '   ✓ Dihapus: %', r.policyname;
  END LOOP;
  RAISE NOTICE '✅ Semua policy lama payment_proofs dihapus';
END $$;

-- ────────────────────────────────────────────────────────────
-- STEP 4: Buat ulang policy payment_proofs
-- ────────────────────────────────────────────────────────────

-- Pengguna: lihat bukti bayar milik sendiri
CREATE POLICY "Users can read own payment proofs"
  ON payment_proofs FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Pengguna: upload bukti bayar milik sendiri
CREATE POLICY "Users can create own payment proofs"
  ON payment_proofs FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Admin: lihat SEMUA bukti bayar
CREATE POLICY "Admins can read all payment proofs"
  ON payment_proofs FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- Admin: update SEMUA bukti bayar (verifikasi/tolak)
CREATE POLICY "Admins can update payment proofs"
  ON payment_proofs FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

DO $$ BEGIN
  RAISE NOTICE '✅ STEP 4: Policy payment_proofs berhasil dibuat (4 policy)';
END $$;

-- ────────────────────────────────────────────────────────────
-- STEP 5: Verifikasi hasil
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE
  b_count  INTEGER;
  pp_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO b_count  FROM pg_policies WHERE tablename = 'bookings'       AND schemaname = 'public';
  SELECT COUNT(*) INTO pp_count FROM pg_policies WHERE tablename = 'payment_proofs' AND schemaname = 'public';

  RAISE NOTICE '';
  RAISE NOTICE '🔍 STEP 5: Verifikasi policy...';
  RAISE NOTICE '   bookings       : % policy (diharapkan 6)', b_count;
  RAISE NOTICE '   payment_proofs : % policy (diharapkan 4)', pp_count;

  IF b_count >= 6 AND pp_count >= 4 THEN
    RAISE NOTICE '✅ Semua policy lengkap!';
  ELSE
    RAISE WARNING '⚠️  Policy tidak lengkap — periksa output di atas';
  END IF;
END $$;

-- ────────────────────────────────────────────────────────────
-- STEP 6: Tampilkan ringkasan policy aktif
-- ────────────────────────────────────────────────────────────
SELECT
  tablename       AS "Tabel",
  policyname      AS "Policy",
  cmd             AS "Operasi",
  permissive      AS "Tipe"
FROM pg_policies
WHERE tablename IN ('bookings', 'payment_proofs') AND schemaname = 'public'
ORDER BY tablename, policyname;

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔══════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║                    ✅ SELESAI!                               ║';
  RAISE NOTICE '╠══════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ Langkah selanjutnya:                                         ║';
  RAISE NOTICE '║  1. Refresh halaman admin panel di browser                   ║';
  RAISE NOTICE '║  2. Login ulang jika perlu                                   ║';
  RAISE NOTICE '║  3. Buka Manajemen Pemesanan — data seharusnya muncul        ║';
  RAISE NOTICE '║                                                               ║';
  RAISE NOTICE '║ Jika masih kosong, jalankan VERIFY_ADMIN_ACCESS.sql          ║';
  RAISE NOTICE '║ untuk memastikan ada data booking & user admin di database   ║';
  RAISE NOTICE '╚══════════════════════════════════════════════════════════════╝';
END $$;
