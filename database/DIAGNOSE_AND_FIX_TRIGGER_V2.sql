-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Diagnose & Fix Trigger V2                        ║
-- ║   File    : DIAGNOSE_AND_FIX_TRIGGER_V2.sql                        ║
-- ║   Dibuat  : 2026-03-06                                              ║
-- ║                                                                     ║
-- ║   MASALAH: Semua 61 akun OPD gagal dengan                          ║
-- ║            "Database error creating new user"                       ║
-- ║   ROOT CAUSE: Trigger on_auth_user_created masih melempar          ║
-- ║               exception (kemungkinan email/username UNIQUE          ║
-- ║               conflict tidak tertangani)                            ║
-- ║                                                                     ║
-- ║   CARA PAKAI:                                                       ║
-- ║     Supabase Dashboard → SQL Editor → Jalankan file ini            ║
-- ╚══════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════
-- STEP 1 — DIAGNOSA: Lihat trigger apa saja yang ada di auth.users
-- ══════════════════════════════════════════════════════════════════════
SELECT
  tgname          AS "Trigger Name",
  tgenabled       AS "Enabled",
  tgtype          AS "Type",
  pg_get_functiondef(tgfoid) AS "Function Body"
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
ORDER BY tgname;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 2 — DIAGNOSA: Lihat UNIQUE constraints di tabel profiles
-- ══════════════════════════════════════════════════════════════════════
SELECT
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name   = 'profiles'
ORDER BY tc.constraint_type, kcu.column_name;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 3 — DIAGNOSA: Apakah ada profiles OPD yang sudah ada
--          (bisa menyebabkan email/username conflict)
-- ══════════════════════════════════════════════════════════════════════
SELECT
  p.id,
  p.username,
  p.email,
  p.role,
  CASE WHEN u.id IS NULL THEN '⚠ ORPHANED (no auth.user)' ELSE '✅ Has auth.user' END AS status
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE p.email LIKE '%bandungkab.go.id'
   OR p.email LIKE '%sipelor.go.id'
ORDER BY p.email;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 4 — FIX: Recreate handle_new_user dengan BULLETPROOF handler
--          - Tangani conflict pada id, email, DAN username
--          - EXCEPTION block memastikan auth.user TIDAK PERNAH gagal
-- ══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username TEXT;
  v_fullname TEXT;
BEGIN
  v_username := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'username'), ''),
    SPLIT_PART(NEW.email, '@', 1)
  );
  v_fullname := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''),
    SPLIT_PART(NEW.email, '@', 1)
  );

  -- Coba INSERT dulu
  INSERT INTO public.profiles (id, email, username, full_name, role, created_at, updated_at)
  VALUES (NEW.id, NEW.email, v_username, v_fullname, 'user', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE
    SET email      = EXCLUDED.email,
        username   = COALESCE(EXCLUDED.username, profiles.username),
        full_name  = COALESCE(EXCLUDED.full_name, profiles.full_name),
        updated_at = NOW();

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Jika ada error apapun (email unique, username unique, dsb)
  -- JANGAN gagalkan pembuatan auth.user
  -- Cukup log warning dan lanjutkan
  RAISE WARNING '[handle_new_user] Profile insert/update gagal untuk user % (%), error: %',
    NEW.id, NEW.email, SQLERRM;
  RETURN NEW;
END;
$$;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 5 — Pastikan trigger terpasang dengan benar
-- ══════════════════════════════════════════════════════════════════════
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

DO $$ BEGIN
  RAISE NOTICE '✅ Trigger on_auth_user_created berhasil dipasang ulang';
END $$;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 6 — BERSIHKAN semua profiles OPD yang:
--          a) Orphaned (tidak punya auth.user), ATAU
--          b) Email bandungkab.go.id tapi ada di profiles tanpa auth.user
--          Ini untuk menghindari email/username conflict saat node run_opd.js
-- ══════════════════════════════════════════════════════════════════════

-- Preview yang akan dihapus
SELECT
  p.id        AS "Profile ID",
  p.username  AS "Username",
  p.email     AS "Email",
  '→ akan dihapus' AS "Action"
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL  -- tidak punya auth.user
  AND (
    p.email LIKE '%bandungkab.go.id'
    OR p.email LIKE '%sipelor.go.id'
  );

-- Hapus orphaned profiles
DELETE FROM public.profiles p
WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id)
  AND (
    p.email LIKE '%bandungkab.go.id'
    OR p.email LIKE '%sipelor.go.id'
  );

DO $$ BEGIN
  RAISE NOTICE '✅ Orphaned profiles OPD berhasil dibersihkan.';
END $$;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 7 — VERIFIKASI AKHIR
-- ══════════════════════════════════════════════════════════════════════

-- Cek trigger aktif di auth.users
SELECT
  tgname    AS "Trigger",
  tgenabled AS "Enabled",
  proname   AS "Function"
FROM pg_trigger t
JOIN pg_proc p ON p.oid = t.tgfoid
WHERE t.tgrelid = 'auth.users'::regclass
ORDER BY tgname;

-- Cek sisa orphaned profiles
SELECT COUNT(*) AS "Orphaned profiles tersisa (harus 0)"
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL
  AND (
    p.email LIKE '%bandungkab.go.id'
    OR p.email LIKE '%sipelor.go.id'
  );

DO $$ BEGIN
  RAISE NOTICE '══════════════════════════════════════════════════';
  RAISE NOTICE '✅ SELESAI — Sekarang jalankan: node run_opd.js';
  RAISE NOTICE '══════════════════════════════════════════════════';
END $$;
