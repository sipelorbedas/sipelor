-- =============================================
-- SIPELOR BEDAS — Setup Admin User di Supabase
-- =============================================
-- Jalankan via: Supabase Dashboard → SQL Editor
-- =============================================

-- ─────────────────────────────────────────────
-- LANGKAH 1: Buat user di Supabase Auth
-- Dashboard → Authentication → Users → Add User
-- Isi email & password, lalu kembali ke sini.
-- ─────────────────────────────────────────────

-- ─────────────────────────────────────────────
-- LANGKAH 2: Jalankan SQL di bawah ini
-- Ganti nilai di blok KONFIGURASI sebelum run.
-- ─────────────────────────────────────────────

DO $$
DECLARE
  -- ══════════════════════════════════════════
  -- KONFIGURASI — sesuaikan nilai di bawah ini
  -- ══════════════════════════════════════════
  v_email     TEXT := 'sipelorbedas@gmail.com';   -- email yang didaftarkan di Auth
  v_username  TEXT := 'sipelorbedas';             -- username unik (bebas, tanpa spasi)
  v_full_name TEXT := 'Admin SIPELOR';            -- nama lengkap
  v_role      user_role := 'superadmin';           -- admin | superadmin | manager | operator
  -- ══════════════════════════════════════════

  v_user_id UUID;
BEGIN
  -- Ambil user ID dari Auth
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = v_email
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION
      'User "%" tidak ditemukan di Supabase Auth. '
      'Daftarkan dulu via Authentication → Users → Add User.',
      v_email;
  END IF;

  -- Insert atau update profil
  INSERT INTO public.profiles (
    id,
    username,
    email,
    full_name,
    role,
    created_at,
    updated_at
  )
  VALUES (
    v_user_id,
    v_username,
    v_email,
    v_full_name,
    v_role,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
    SET username   = EXCLUDED.username,
        email      = EXCLUDED.email,
        full_name  = EXCLUDED.full_name,
        role       = EXCLUDED.role,
        updated_at = NOW();

  RAISE NOTICE '✅ Berhasil! User "%" (%) sekarang punya role: %',
    v_full_name, v_email, v_role;
END $$;


-- ─────────────────────────────────────────────
-- VERIFIKASI — jalankan setelah DO block berhasil
-- ─────────────────────────────────────────────
SELECT
  u.email,
  p.username,
  p.full_name,
  p.role,
  p.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email = 'sipelorbedas@gmail.com';


-- ─────────────────────────────────────────────
-- (OPSIONAL) Cek struktur tabel profiles
-- Berguna untuk debug kolom apa saja yang ada
-- ─────────────────────────────────────────────
/*
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'profiles'
ORDER BY ordinal_position;
*/


-- ─────────────────────────────────────────────
-- (OPSIONAL) Buat tabel profiles jika belum ada
-- ─────────────────────────────────────────────
/*
CREATE TABLE IF NOT EXISTS public.profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username     TEXT NOT NULL UNIQUE,
  email        TEXT,
  full_name    TEXT,
  role         TEXT DEFAULT 'user'
                CHECK (role IN ('user','operator','manager','admin','superadmin')),
  phone        TEXT,
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin read all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','superadmin','manager','operator')
    )
  );

CREATE POLICY "User read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);
*/
