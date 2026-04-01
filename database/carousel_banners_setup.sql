-- ============================================================
-- SIPELOR BEDAS — Setup Tabel & Storage Carousel Banners
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Buat tabel carousel_banners
-- ============================================================
CREATE TABLE IF NOT EXISTS carousel_banners (
  id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  title           TEXT        NOT NULL,
  subtitle        TEXT,
  badge_text      TEXT,
  image_url       TEXT,             -- URL publik dari Supabase Storage
  gradient_start  TEXT        DEFAULT '#D946EF',
  gradient_end    TEXT        DEFAULT '#F97316',
  sort_order      INTEGER     DEFAULT 0,
  is_active       BOOLEAN     DEFAULT TRUE,
  link_url        TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Auto-update kolom updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_carousel_banners_updated_at ON carousel_banners;
CREATE TRIGGER set_carousel_banners_updated_at
  BEFORE UPDATE ON carousel_banners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Row Level Security (RLS)
-- ============================================================
ALTER TABLE carousel_banners ENABLE ROW LEVEL SECURITY;

-- Semua orang (termasuk anonymous / Flutter app) bisa READ banner aktif
CREATE POLICY "Public read active carousel banners"
  ON carousel_banners FOR SELECT
  USING (is_active = TRUE);

-- Admin/superadmin bisa SELECT semua (termasuk yang nonaktif)
CREATE POLICY "Admin full read carousel banners"
  ON carousel_banners FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager')
    )
  );

-- Admin bisa INSERT
CREATE POLICY "Admin insert carousel banners"
  ON carousel_banners FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager')
    )
  );

-- Admin bisa UPDATE
CREATE POLICY "Admin update carousel banners"
  ON carousel_banners FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager')
    )
  );

-- Admin bisa DELETE
CREATE POLICY "Admin delete carousel banners"
  ON carousel_banners FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager')
    )
  );

-- 4. Index untuk performa
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_carousel_banners_active_sort
  ON carousel_banners (is_active, sort_order);

-- 5. Seed data awal (opsional — hapus jika tidak perlu)
-- ============================================================
INSERT INTO carousel_banners (title, subtitle, badge_text, gradient_start, gradient_end, sort_order, is_active)
VALUES
  ('Diskon Sewa Stadion', 'Hemat hingga 30%',          'DISKON 30%', '#D946EF', '#F97316', 0, TRUE),
  ('Bupati Cup 2026',     'Daftar sekarang!',           'GRATIS',     '#3B82F6', '#8B5CF6', 1, TRUE),
  ('Paket Latihan',       'Promo spesial minggu ini',   'DISKON 25%', '#10B981', '#14B8A6', 2, TRUE),
  ('Early Bird Tiket',    'Beli sekarang lebih murah',  'DISKON 20%', '#EC4899', '#EF4444', 3, TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================
-- STORAGE BUCKET — carousel-banners
-- Jalankan via: Supabase Dashboard → Storage → New bucket
-- ATAU via SQL berikut:
-- ============================================================

-- Buat bucket public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'carousel-banners',
  'carousel-banners',
  TRUE,                              -- public bucket — siapapun bisa baca URL
  5242880,                           -- 5 MB max per file
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Policy storage: admin bisa upload
CREATE POLICY "Admin upload carousel images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'carousel-banners'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager')
    )
  );

-- Policy storage: admin bisa hapus
CREATE POLICY "Admin delete carousel images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'carousel-banners'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin', 'manager')
    )
  );

-- Policy storage: semua orang bisa baca file (public bucket)
CREATE POLICY "Public read carousel images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'carousel-banners');

-- ============================================================
-- SELESAI ✅
-- Langkah selanjutnya:
-- 1. Jalankan SQL ini di Supabase Dashboard → SQL Editor
-- 2. Pastikan bucket "carousel-banners" terbuat (cek di Storage)
-- 3. Deploy web admin — akan muncul menu "Carousel Banner"
-- 4. Jalankan Flutter app — PromoCarousel otomatis fetch dari DB
-- ============================================================
