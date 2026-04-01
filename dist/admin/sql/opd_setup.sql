-- ═══════════════════════════════════════════════════════════════
-- SIPELOR BEDAS — OPD / Pimpinan Booking System
-- Jalankan via Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────
-- 1. Tabel opd_organizations
--    Menyimpan daftar OPD dan Pimpinan yang dapat memblokir jadwal
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.opd_organizations (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text          NOT NULL,          -- Nama OPD / Pimpinan
  contact_person  text,                            -- Nama PIC
  phone           text,                            -- No. Telepon PIC
  email           text,                            -- Email PIC
  is_active       boolean       NOT NULL DEFAULT true,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  updated_at      timestamptz   NOT NULL DEFAULT now()
);

-- Index untuk query aktif
CREATE INDEX IF NOT EXISTS idx_opd_organizations_active
  ON public.opd_organizations (is_active);

-- ──────────────────────────────────────────────────────────────
-- 2. Tambah kolom ke tabel bookings
--    booking_type : 'regular' | 'opd' | 'pimpinan'
--    opd_id       : FK ke opd_organizations (nullable)
--    booked_for_label : label tampilan, contoh "Acara Bupati Cup 2026"
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS booking_type     text DEFAULT 'regular'
    CHECK (booking_type IN ('regular', 'opd', 'pimpinan')),
  ADD COLUMN IF NOT EXISTS opd_id           uuid REFERENCES public.opd_organizations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS booked_for_label text;

-- Index untuk filter cepat
CREATE INDEX IF NOT EXISTS idx_bookings_type
  ON public.bookings (booking_type);
CREATE INDEX IF NOT EXISTS idx_bookings_opd_id
  ON public.bookings (opd_id)
  WHERE opd_id IS NOT NULL;

-- ──────────────────────────────────────────────────────────────
-- 3. Row Level Security (RLS)
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.opd_organizations ENABLE ROW LEVEL SECURITY;

-- Admin dapat membaca & mengelola semua OPD
CREATE POLICY "Admin manages OPD" ON public.opd_organizations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- User biasa hanya dapat membaca OPD yang aktif (untuk tampilan label di app)
CREATE POLICY "Users read active OPD" ON public.opd_organizations
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- ──────────────────────────────────────────────────────────────
-- 4. Sample data OPD (opsional, hapus jika tidak diperlukan)
-- ──────────────────────────────────────────────────────────────
INSERT INTO public.opd_organizations (name, contact_person, phone, email, is_active)
VALUES
  ('Bupati / Pimpinan Daerah',  'Sekretariat Daerah',   '022-5891234', 'setda@bandungkab.go.id',        true),
  ('Dinas Pendidikan',          'Kepala Dinas',          '022-5891235', 'disdik@bandungkab.go.id',       true),
  ('Dinas Kesehatan',           'Kepala Dinas',          '022-5891236', 'dinkes@bandungkab.go.id',       true),
  ('Dinas Pemuda dan Olahraga', 'Kepala Dinas DISPORA',  '022-5891237', 'dispora@bandungkab.go.id',      true),
  ('Dinas Pariwisata',          'Kepala Dinas',          '022-5891238', 'dispar@bandungkab.go.id',       true),
  ('Sekretariat DPRD',          'Sekretaris DPRD',       '022-5891239', 'dprd@bandungkab.go.id',         true)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- SELESAI
-- Jalankan SQL ini di: Supabase Dashboard → SQL Editor → New Query
-- ──────────────────────────────────────────────────────────────
