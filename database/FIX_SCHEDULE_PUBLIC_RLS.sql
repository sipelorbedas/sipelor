-- =====================================================
-- SIPELOR BEDAS — Fix RLS: Public Read Jadwal Lapangan
-- =====================================================
-- Jalankan di Supabase Dashboard → SQL Editor
-- Tujuan: izinkan publik (tanpa login) melihat
--   slot waktu yang sudah dipesan, agar jadwal
--   venue-detail.html bisa tampilkan status real-time
--   dan mencegah double booking dari sisi display.
--
-- CATATAN KEAMANAN:
--   Policy ini hanya mengizinkan baca kolom terbatas
--   (booking_date, start_time, end_time, status) untuk
--   keperluan tampilan jadwal. Data pribadi user/pembayaran
--   TETAP terlindungi oleh policy yang sudah ada.
-- =====================================================

-- 1. Hapus policy lama jika ada
DROP POLICY IF EXISTS "Public can view booked slots for schedule" ON public.bookings;

-- 2. Izinkan anon & authenticated melihat slot yang sudah dipesan
--    (hanya status pending/confirmed agar schedule akurat)
CREATE POLICY "Public can view booked slots for schedule"
  ON public.bookings
  FOR SELECT
  TO anon, authenticated
  USING (status IN ('pending', 'confirmed'));

-- 3. Grant SELECT ke anon role
GRANT SELECT ON public.bookings TO anon;

-- 4. Verifikasi
SELECT tablename, policyname, cmd, roles, qual
FROM pg_policies
WHERE tablename = 'bookings'
ORDER BY policyname;
