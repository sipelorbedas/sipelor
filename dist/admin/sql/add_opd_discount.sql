-- ═══════════════════════════════════════════════════════════════
-- SIPELOR BEDAS — Tambah Kolom Diskon ke OPD & Bookings
-- Jalankan via Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- 1. Tambah kolom discount_percentage ke opd_organizations
--    Nilai: 0–100 (persentase diskon harga lapangan)
--    Default: 0 (tidak ada diskon)
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.opd_organizations
  ADD COLUMN IF NOT EXISTS discount_percentage numeric(5,2) NOT NULL DEFAULT 0
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- ──────────────────────────────────────────────────────────────
-- 2. Tambah kolom diskon ke tabel bookings
--    discount_percentage : persentase diskon yang dipakai saat booking
--    discount_amount     : nominal potongan (sudah dihitung)
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS discount_percentage numeric(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_amount     bigint       DEFAULT 0;

-- ──────────────────────────────────────────────────────────────
-- 3. Update sample data diskon (opsional)
--    Sesuaikan dengan kebijakan diskon DISPORA Kab. Bandung
-- ──────────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET discount_percentage = 100 WHERE name ILIKE '%Bupati%' OR name ILIKE '%Pimpinan%';
UPDATE public.opd_organizations SET discount_percentage = 75  WHERE name ILIKE '%Dispora%' OR name ILIKE '%Olahraga%';
UPDATE public.opd_organizations SET discount_percentage = 50  WHERE name ILIKE '%Pendidikan%';
UPDATE public.opd_organizations SET discount_percentage = 50  WHERE name ILIKE '%Kesehatan%';
UPDATE public.opd_organizations SET discount_percentage = 25  WHERE name ILIKE '%Pariwisata%';

-- ──────────────────────────────────────────────────────────────
-- SELESAI
-- Setelah menjalankan SQL ini, fitur diskon OPD sudah aktif.
-- ═══════════════════════════════════════════════════════════════
