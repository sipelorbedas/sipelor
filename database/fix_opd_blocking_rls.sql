-- ╔══════════════════════════════════════════════════════════════════╗
-- ║    FIX: Pemblokiran Jadwal OPD/Pimpinan Tidak Muncul di App     ║
-- ║    Masalah: RLS mencegah user biasa melihat booking OPD/admin  ║
-- ╚══════════════════════════════════════════════════════════════════╝
--
-- CARA PAKAI:
--   1. Buka Supabase Dashboard → SQL Editor
--   2. Copy-paste seluruh isi file ini
--   3. Klik "Run"
--   4. Restart Flutter app

-- ══════════════════════════════════════════════════════════════════
-- BAGIAN 1: RPC Function (Solusi Utama)
-- Fungsi SECURITY DEFINER memungkinkan semua user melihat slot yang
-- diblokir tanpa terhalang RLS. Ini adalah cara paling aman karena
-- hanya menampilkan data minimum yang diperlukan untuk cek ketersediaan.
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_blocked_slots(
  p_field_id  UUID,
  p_date      DATE
)
RETURNS TABLE (
  id                UUID,
  booking_id        TEXT,
  start_time        TEXT,
  end_time          TEXT,
  status            TEXT,
  booking_type      TEXT,
  booked_for_label  TEXT,
  opd_id            UUID,
  has_payment_proof BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER            -- Bypass RLS, jalankan sebagai pemilik fungsi
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.id,
    b.booking_id::TEXT,
    b.start_time::TEXT,
    b.end_time::TEXT,
    b.status::TEXT,
    COALESCE(b.booking_type, 'regular')::TEXT AS booking_type,
    b.booked_for_label,
    b.opd_id,
    EXISTS (
      SELECT 1
      FROM   payment_proofs pp
      WHERE  pp.booking_id = b.id
    ) AS has_payment_proof
  FROM bookings b
  WHERE
    b.field_id    = p_field_id
    AND b.booking_date = p_date
    AND b.status   IN ('pending', 'confirmed');
END;
$$;

-- Izinkan user terautentikasi menjalankan fungsi ini
GRANT EXECUTE ON FUNCTION get_blocked_slots(UUID, DATE) TO authenticated;


-- ══════════════════════════════════════════════════════════════════
-- BAGIAN 2: RLS Policy (Alternatif / Pelengkap)
-- Jika ingin solusi tanpa RPC, tambahkan policy ini agar semua user
-- bisa melihat booking 'confirmed' untuk keperluan cek ketersediaan.
-- Catatan: policy ini berjalan berdampingan dengan policy yang ada.
-- ══════════════════════════════════════════════════════════════════

-- Hapus policy lama jika sudah ada (agar tidak duplikat)
DROP POLICY IF EXISTS "Users can view confirmed bookings for availability" ON bookings;

-- Policy baru: semua user terautentikasi bisa melihat booking confirmed
CREATE POLICY "Users can view confirmed bookings for availability"
ON bookings
FOR SELECT
TO authenticated
USING (status = 'confirmed');

-- Policy yang sudah ada (pastikan ini sudah ada):
-- CREATE POLICY "Users can view their own bookings"
-- ON bookings FOR SELECT TO authenticated
-- USING (user_id = auth.uid());


-- ══════════════════════════════════════════════════════════════════
-- BAGIAN 3: Verifikasi
-- Jalankan query ini untuk memastikan fungsi berhasil dibuat
-- ══════════════════════════════════════════════════════════════════

-- Cek apakah fungsi sudah ada
SELECT
  routine_name,
  security_type,
  routine_definition IS NOT NULL AS has_definition
FROM information_schema.routines
WHERE routine_name = 'get_blocked_slots'
  AND routine_schema = 'public';

-- Lihat semua booking OPD/Pimpinan (jalankan sebagai superadmin):
-- SELECT id, booking_id, booking_type, status, field_id, booking_date, start_time, end_time
-- FROM bookings
-- WHERE booking_type IN ('opd', 'pimpinan')
-- ORDER BY booking_date DESC;
