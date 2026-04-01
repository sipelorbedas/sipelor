-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Hapus Zombie auth.users (INSERT SQL langsung)    ║
-- ║   File    : FORCE_DELETE_ZOMBIE_AUTH_USERS.sql                      ║
-- ║   Dibuat  : 2026-03-06                                              ║
-- ║                                                                     ║
-- ║   MASALAH:                                                          ║
-- ║     Script SQL sebelumnya INSERT langsung ke auth.users tanpa       ║
-- ║     auth.identities → record ada di DB, TIDAK muncul di Admin API  ║
-- ║     → GoTrue gagal buat user baru karena email UNIQUE conflict      ║
-- ║                                                                     ║
-- ║   FIX:                                                              ║
-- ║     Hapus semua auth.users OPD (bandungkab.go.id/sipelor.go.id)    ║
-- ║     yang tidak punya auth.identities (zombie users)                 ║
-- ║     Hapus juga profiles terkait                                     ║
-- ║                                                                     ║
-- ║   CARA PAKAI:                                                       ║
-- ║     Supabase Dashboard → SQL Editor → Jalankan file ini            ║
-- ║     Lalu jalankan: node run_opd.js                                  ║
-- ╚══════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════
-- PREVIEW: Zombie auth.users yang akan dihapus
--          (ada di auth.users tapi tidak punya auth.identities)
-- ══════════════════════════════════════════════════════════════════════
SELECT
  u.id,
  u.email,
  u.created_at,
  u.encrypted_password IS NOT NULL AS has_password,
  COUNT(i.id) AS identities_count,
  '→ AKAN DIHAPUS (zombie)' AS action
FROM auth.users u
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE (
    u.email LIKE '%bandungkab.go.id'
    OR u.email LIKE '%sipelor.go.id'
  )
  AND u.email != 'buaptibandung@bandungkab.go.id'  -- jaga bupati yang valid
GROUP BY u.id, u.email, u.created_at, u.encrypted_password
HAVING COUNT(i.id) = 0  -- tidak punya identities → zombie
ORDER BY u.email;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 1: Hapus profiles terkait zombie auth.users
-- ══════════════════════════════════════════════════════════════════════
DELETE FROM public.profiles p
WHERE p.id IN (
  SELECT u.id
  FROM auth.users u
  LEFT JOIN auth.identities i ON i.user_id = u.id
  WHERE (
      u.email LIKE '%bandungkab.go.id'
      OR u.email LIKE '%sipelor.go.id'
    )
    AND u.email != 'buaptibandung@bandungkab.go.id'
  GROUP BY u.id
  HAVING COUNT(i.id) = 0
);

DO $$ BEGIN RAISE NOTICE '✅ STEP 1: Profiles zombie dihapus'; END $$;


-- ══════════════════════════════════════════════════════════════════════
-- STEP 2: Hapus zombie auth.users
--         (tidak punya identities → tidak bisa login via Supabase API)
-- ══════════════════════════════════════════════════════════════════════
DELETE FROM auth.users u
WHERE (
    u.email LIKE '%bandungkab.go.id'
    OR u.email LIKE '%sipelor.go.id'
  )
  AND u.email != 'buaptibandung@bandungkab.go.id'
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i WHERE i.user_id = u.id
  );

DO $$ BEGIN RAISE NOTICE '✅ STEP 2: Zombie auth.users dihapus'; END $$;


-- ══════════════════════════════════════════════════════════════════════
-- VERIFIKASI: Pastikan tidak ada zombie tersisa
-- ══════════════════════════════════════════════════════════════════════
SELECT
  COUNT(*) AS "Zombie auth.users tersisa (harus 0)"
FROM auth.users u
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE (
    u.email LIKE '%bandungkab.go.id'
    OR u.email LIKE '%sipelor.go.id'
  )
GROUP BY u.id
HAVING COUNT(i.id) = 0;


-- ══════════════════════════════════════════════════════════════════════
-- TAMPILKAN semua auth.users yang tersisa (valid)
-- ══════════════════════════════════════════════════════════════════════
SELECT
  u.email,
  COUNT(i.id) AS identities,
  u.created_at
FROM auth.users u
LEFT JOIN auth.identities i ON i.user_id = u.id
GROUP BY u.id, u.email, u.created_at
ORDER BY u.created_at;


DO $$ BEGIN
  RAISE NOTICE '══════════════════════════════════════════════════════';
  RAISE NOTICE '✅ SELESAI — Sekarang jalankan: node run_opd.js';
  RAISE NOTICE '══════════════════════════════════════════════════════';
END $$;
