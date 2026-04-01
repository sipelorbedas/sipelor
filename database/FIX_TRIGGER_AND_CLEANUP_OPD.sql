-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Fix Trigger handle_new_user & Cleanup OPD        ║
-- ║   File    : FIX_TRIGGER_AND_CLEANUP_OPD.sql                        ║
-- ║   Dibuat  : 2026-03-06                                              ║
-- ║                                                                     ║
-- ║   MASALAH:                                                          ║
-- ║     Trigger on_auth_user_created mencoba INSERT ke profiles saat   ║
-- ║     auth.user dibuat. Karena script SQL sebelumnya sudah membuat   ║
-- ║     baris di profiles (email/username conflict), trigger GAGAL     ║
-- ║     → seluruh transaksi rollback → "Database error creating new    ║
-- ║       user" saat menjalankan node run_opd.js.                      ║
-- ║                                                                     ║
-- ║   FIX:                                                              ║
-- ║     1. Update trigger dengan ON CONFLICT DO UPDATE (idempotent)    ║
-- ║     2. Hapus orphaned profiles OPD (profiles tanpa auth.user)      ║
-- ║        yang berasal dari percobaan SQL migration sebelumnya        ║
-- ║                                                                     ║
-- ║   CARA PAKAI:                                                       ║
-- ║     Supabase Dashboard → SQL Editor → Jalankan file ini,          ║
-- ║     lalu jalankan kembali: node run_opd.js                         ║
-- ╚══════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 1 — Update trigger handle_new_user agar tahan conflict
--             (ON CONFLICT DO UPDATE menggantikan INSERT gagal)
-- ══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    'user',
    NOW(),
    NOW()
  )
  -- Jika id sudah ada di profiles (race condition / double-trigger), update saja
  ON CONFLICT (id) DO UPDATE
    SET email      = EXCLUDED.email,
        username   = COALESCE(EXCLUDED.username, profiles.username),
        full_name  = COALESCE(EXCLUDED.full_name, profiles.full_name),
        updated_at = NOW();
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Jangan pernah gagalkan pembuatan auth.user hanya karena profiles bermasalah
  RAISE WARNING 'handle_new_user: profiles insert/update gagal untuk %, error: %', NEW.email, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pastikan trigger sudah terpasang
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

DO $$ BEGIN RAISE NOTICE '✅ Trigger handle_new_user berhasil diperbarui'; END $$;


-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 2 — Hapus orphaned profiles OPD
--             (profiles yang email-nya cocok dengan OPD tapi tidak
--              punya auth.user → sisa dari percobaan SQL INSERT gagal)
-- ══════════════════════════════════════════════════════════════════════

-- Preview dulu (berapa baris yang akan dihapus)
SELECT
  p.id        AS "Profile ID",
  p.username  AS "Username",
  p.email     AS "Email",
  p.role      AS "Role"
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL
  AND p.email IN (
    SELECT COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')
    FROM   public.opd_organizations o
    WHERE  o.username IS NOT NULL
  );

-- Hapus orphaned profiles OPD (tidak ada auth.user-nya)
DELETE FROM public.profiles p
WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id)
  AND p.email IN (
    SELECT COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')
    FROM   public.opd_organizations o
    WHERE  o.username IS NOT NULL
  );

-- Tampilkan jumlah yang dihapus
DO $$
BEGIN
  RAISE NOTICE '✅ Orphaned OPD profiles berhasil dihapus.';
  RAISE NOTICE '   Sekarang jalankan kembali: node run_opd.js';
END;
$$;


-- ══════════════════════════════════════════════════════════════════════
-- VERIFIKASI — Pastikan tidak ada lagi orphaned profiles OPD
-- ══════════════════════════════════════════════════════════════════════
SELECT
  COUNT(*) AS "Orphaned OPD Profiles Tersisa (harus 0)"
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL
  AND p.email IN (
    SELECT COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')
    FROM   public.opd_organizations o
    WHERE  o.username IS NOT NULL
  );
