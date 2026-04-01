-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Fix: Patch username NULL di profiles OPD          ║
-- ║   File   : FIX_OPD_PROFILE_USERNAME_PATCH.sql                       ║
-- ║   Dibuat : 2026-03-06                                                ║
-- ║                                                                      ║
-- ║   MASALAH YANG DISELESAIKAN:                                         ║
-- ║     Akun OPD yang dibuat SEBELUM kolom username ditambahkan ke       ║
-- ║     script INSERT profiles memiliki profiles.username = NULL.        ║
-- ║     Akibatnya, RPC get_email_by_username dan query ilike ke          ║
-- ║     profiles tidak menemukan email → login Flutter gagal             ║
-- ║     (InvalidLoginCredentials / username not found).                  ║
-- ║                                                                      ║
-- ║   CARA PAKAI:                                                        ║
-- ║     Buka Supabase Dashboard → SQL Editor → jalankan file ini.       ║
-- ╚══════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 1 — Patch profiles yang emailnya = username@sipelor.go.id
--             (akun OPD tanpa email asli)
-- ══════════════════════════════════════════════════════════════════════
UPDATE public.profiles p
SET
  username   = o.username,
  updated_at = now()
FROM public.opd_organizations o
WHERE p.email = o.username || '@sipelor.go.id'
  AND o.username IS NOT NULL
  AND (p.username IS NULL OR p.username = '');


-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 2 — Patch profiles yang emailnya = email asli OPD
--             (akun OPD yang punya email real di opd_organizations)
-- ══════════════════════════════════════════════════════════════════════
UPDATE public.profiles p
SET
  username   = o.username,
  updated_at = now()
FROM public.opd_organizations o
WHERE o.email IS NOT NULL
  AND o.email != ''
  AND p.email = o.email
  AND o.username IS NOT NULL
  AND (p.username IS NULL OR p.username = '');


-- ══════════════════════════════════════════════════════════════════════
-- VERIFIKASI — Tampilkan status setelah patch
-- ══════════════════════════════════════════════════════════════════════
SELECT
  o.name                                                              AS "Nama OPD",
  o.username                                                          AS "Username OPD",
  p.username                                                          AS "Username Profile",
  COALESCE(NULLIF(o.email, ''), o.username || '@sipelor.go.id')      AS "Email Login",
  CASE WHEN p.username IS NOT NULL AND p.username != ''
       THEN '✅ OK' ELSE '❌ Masih NULL' END                          AS "Status Username",
  p.role                                                              AS "Role"
FROM public.opd_organizations o
LEFT JOIN auth.users u
  ON u.email = COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')
LEFT JOIN public.profiles p ON p.id = u.id
WHERE o.username IS NOT NULL
ORDER BY
  CASE
    WHEN o.name ILIKE 'Badan%'       THEN 1
    WHEN o.name ILIKE 'Dinas%'       THEN 2
    WHEN o.name ILIKE 'Satuan%'      THEN 3
    WHEN o.name ILIKE 'Sekretaris%'  THEN 4
    WHEN o.name ILIKE 'Kecamatan%'   THEN 5
    ELSE 6
  END,
  o.name;
