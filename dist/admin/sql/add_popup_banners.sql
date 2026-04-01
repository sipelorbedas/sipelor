-- ═══════════════════════════════════════════════════════════════
-- SIPELOR BEDAS — Tabel Popup Banner (Iklan / Pengumuman)
-- Jalankan via Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════════

-- 1. Buat tabel popup_banners
CREATE TABLE IF NOT EXISTS public.popup_banners (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url   TEXT        NOT NULL,
  link_url    TEXT,
  is_active   BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Tambah kolom updated_at jika belum ada (migrasi untuk tabel lama)
ALTER TABLE public.popup_banners
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Aktifkan RLS
ALTER TABLE public.popup_banners ENABLE ROW LEVEL SECURITY;

-- 3. Hapus policy lama dulu (CREATE POLICY tidak mendukung IF NOT EXISTS)
DROP POLICY IF EXISTS "popup_select_authenticated" ON public.popup_banners;
DROP POLICY IF EXISTS "popup_admin_all"            ON public.popup_banners;

-- 4. Pengguna terautentikasi bisa membaca popup aktif (untuk Flutter app)
CREATE POLICY "popup_select_authenticated"
  ON public.popup_banners FOR SELECT
  TO authenticated
  USING (is_active = true);

-- 5. Admin bisa mengelola semua popup
CREATE POLICY "popup_admin_all"
  ON public.popup_banners FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

-- 6. Buat Storage Bucket "popup-banners" (public) via SQL
--    Bucket ini dipakai oleh admin web untuk upload gambar popup.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'popup-banners',
  'popup-banners',
  true,                        -- public: gambar popup boleh dibaca siapa saja
  5242880,                     -- max 5 MB per file
  ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;  -- aman dijalankan berulang kali

-- 7. Storage RLS policies untuk bucket "popup-banners"
--    Hapus dulu agar aman dijalankan ulang
DROP POLICY IF EXISTS "popup_banners_public_read"   ON storage.objects;
DROP POLICY IF EXISTS "popup_banners_admin_insert"  ON storage.objects;
DROP POLICY IF EXISTS "popup_banners_admin_delete"  ON storage.objects;

-- Siapa saja bisa membaca gambar popup (public bucket)
CREATE POLICY "popup_banners_public_read"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'popup-banners');

-- Hanya admin / superadmin yang bisa upload
CREATE POLICY "popup_banners_admin_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'popup-banners' AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

-- Hanya admin / superadmin yang bisa hapus
CREATE POLICY "popup_banners_admin_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'popup-banners' AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SELESAI — semua langkah sudah terintegrasi dalam satu script.
-- Tidak perlu membuat bucket secara manual di Dashboard.
-- ═══════════════════════════════════════════════════════════════
