-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — MIGRASI AKUN LOGIN OPD & PIMPINAN (ALL-IN-ONE)       ║
-- ║   File    : MIGRATION_CREATE_ALL_OPD_AUTH_USERS.sql                     ║
-- ║   Dibuat  : 2026-03-06                                                   ║
-- ║                                                                          ║
-- ║   FUNGSI:                                                                ║
-- ║     Membuat akun di Authentication > Users (auth.users) dan             ║
-- ║     public.profiles untuk SEMUA OPD & Pimpinan yang ada di              ║
-- ║     tabel public.opd_organizations.                                      ║
-- ║                                                                          ║
-- ║   CARA PAKAI:                                                            ║
-- ║     1. Buka Supabase Dashboard                                           ║
-- ║     2. Masuk ke SQL Editor                                               ║
-- ║     3. Copy-paste seluruh isi file ini lalu klik Run                     ║
-- ║     4. Cek tabel hasil verifikasi di bagian bawah output                 ║
-- ║                                                                          ║
-- ║   IDEMPOTENT: Aman dijalankan berkali-kali.                              ║
-- ║     - Akun yang sudah ada di auth.users akan dilewati (SKIP).           ║
-- ║     - Profiles yang sudah ada akan di-update username-nya.              ║
-- ║                                                                          ║
-- ║   KREDENSIAL LOGIN:                                                      ║
-- ║     Email Login  : <email_opd>@bandungkab.go.id                         ║
-- ║                    (atau username@sipelor.go.id jika email kosong)       ║
-- ║     Password     : Sipelor@2026                                          ║
-- ║     Username App : sesuai kolom opd_organizations.username               ║
-- ║                    contoh: dispora, dinkes, kec.soreang, dprd, dll.      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════════
-- LANGKAH 0 — Aktifkan ekstensi pgcrypto (untuk hash password bcrypt)
-- ══════════════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ══════════════════════════════════════════════════════════════════════════
-- LANGKAH 1 — Pastikan kolom username & default_password tersedia
-- ══════════════════════════════════════════════════════════════════════════
ALTER TABLE public.opd_organizations
  ADD COLUMN IF NOT EXISTS username         text,
  ADD COLUMN IF NOT EXISTS default_password text NOT NULL DEFAULT 'Sipelor@2026';

CREATE UNIQUE INDEX IF NOT EXISTS idx_opd_organizations_username
  ON public.opd_organizations (username)
  WHERE username IS NOT NULL;


-- ══════════════════════════════════════════════════════════════════════════
-- LANGKAH 2 — Set username untuk setiap OPD (idempotent: ON CONFLICT)
-- ══════════════════════════════════════════════════════════════════════════

-- ── BADAN ─────────────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'bkpsdm'
  WHERE name ILIKE '%Kepegawaian dan Pengembangan Sumber Daya Manusia%' AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'bakesbangpol'
  WHERE name ILIKE '%Kesatuan Bangsa dan Politik%'                       AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'bkad'
  WHERE name ILIKE '%Keuangan dan Aset Daerah%'                          AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'bapenda'
  WHERE name ILIKE '%Pendapatan Daerah%'                                 AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'bapperida'
  WHERE name ILIKE '%Perencanaan Pembangunan, Riset%'                    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'bpbd'
  WHERE name ILIKE '%Penanggulangan Bencana Daerah%'                     AND (username IS NULL OR username = '');

-- ── DINAS ──────────────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'disbud'
  WHERE name ILIKE '%Dinas Kebudayaan%'                                  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'disdukcapil'
  WHERE name ILIKE '%Kependudukan dan Pencatatan Sipil%'                 AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'diskpp'
  WHERE name ILIKE '%Ketahanan Pangan dan Perikanan%'                    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'disnaker'
  WHERE name ILIKE '%Ketenagakerjaan%'                                   AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'diskominfo'
  WHERE name ILIKE '%Komunikasi dan Informatika%'                        AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'diskopukm'
  WHERE name ILIKE '%Koperasi dan Usaha Kecil%'                          AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dlh'
  WHERE name ILIKE '%Lingkungan Hidup%'                                  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'disparekraf'
  WHERE name ILIKE '%Pariwisata dan Ekonomi Kreatif%'                    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dpupr'
  WHERE name ILIKE '%Pekerjaan Umum dan Tata Ruang%'                     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dpkp'
  WHERE name ILIKE '%Pemadam Kebakaran%'                                 AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dpmd'
  WHERE name ILIKE '%Pemberdayaan Masyarakat dan Desa%'                  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dispora'
  WHERE name ILIKE '%Pemuda dan Olahraga%'                               AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dpmptsp'
  WHERE name ILIKE '%Penanaman Modal dan Pelayanan Terpadu%'             AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'disdik'
  WHERE name ILIKE '%Dinas Pendidikan%'                                  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dp2kbp3a'
  WHERE name ILIKE '%Keluarga Berencana%'                                AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dishub'
  WHERE name ILIKE '%Perhubungan%'                                       AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dispusip'
  WHERE name ILIKE '%Perpustakaan dan Arsip%'                            AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'distani'
  WHERE name ILIKE '%Dinas Pertanian%'                                   AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dpkpp'
  WHERE name ILIKE '%Perumahan, Kawasan Permukiman%'                     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dinsos'
  WHERE name ILIKE '%Dinas Sosial%'                                      AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dinkes'
  WHERE name ILIKE '%Dinas Kesehatan%'                                   AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'disdagin'
  WHERE name ILIKE '%Perdagangan dan Perindustrian%'                     AND (username IS NULL OR username = '');

-- ── SATUAN & DPRD (Pimpinan) ───────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'satpolpp'
  WHERE name ILIKE '%Polisi Pamong Praja%'                               AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'dprd'
  WHERE name ILIKE '%Sekretaris DPRD%'                                   AND (username IS NULL OR username = '');

-- ── KECAMATAN ─────────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'kec.arjasari'
  WHERE name = 'Kecamatan Arjasari'     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.baleendah'
  WHERE name = 'Kecamatan Baleendah'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.banjaran'
  WHERE name = 'Kecamatan Banjaran'     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.bojongsoang'
  WHERE name = 'Kecamatan Bojongsoang'  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cangkuang'
  WHERE name = 'Kecamatan Cangkuang'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cicalengka'
  WHERE name = 'Kecamatan Cicalengka'   AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cikancung'
  WHERE name = 'Kecamatan Cikancung'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cilengkrang'
  WHERE name = 'Kecamatan Cilengkrang'  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cileunyi'
  WHERE name = 'Kecamatan Cileunyi'     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cimaung'
  WHERE name = 'Kecamatan Cimaung'      AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.cimenyan'
  WHERE name = 'Kecamatan Cimenyan'     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.ciparay'
  WHERE name = 'Kecamatan Ciparay'      AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.ciwidey'
  WHERE name = 'Kecamatan Ciwidey'      AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.dayeuhkolot'
  WHERE name = 'Kecamatan Dayeuhkolot'  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.ibun'
  WHERE name = 'Kecamatan Ibun'         AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.katapang'
  WHERE name = 'Kecamatan Katapang'     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.kertasari'
  WHERE name = 'Kecamatan Kertasari'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.kutawaringin'
  WHERE name = 'Kecamatan Kutawaringin' AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.majalaya'
  WHERE name = 'Kecamatan Majalaya'     AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.margaasih'
  WHERE name = 'Kecamatan Margaasih'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.margahayu'
  WHERE name = 'Kecamatan Margahayu'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.nagreg'
  WHERE name = 'Kecamatan Nagreg'       AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.pacet'
  WHERE name = 'Kecamatan Pacet'        AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.pameungpeuk'
  WHERE name = 'Kecamatan Pameungpeuk'  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.pangalengan'
  WHERE name = 'Kecamatan Pangalengan'  AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.paseh'
  WHERE name = 'Kecamatan Paseh'        AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.pasirjambu'
  WHERE name = 'Kecamatan Pasirjambu'   AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.rancabali'
  WHERE name = 'Kecamatan Rancabali'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.rancaekek'
  WHERE name = 'Kecamatan Rancaekek'    AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.solokanjeruk'
  WHERE name = 'Kecamatan Solokanjeruk' AND (username IS NULL OR username = '');
UPDATE public.opd_organizations SET username = 'kec.soreang'
  WHERE name = 'Kecamatan Soreang'      AND (username IS NULL OR username = '');


-- ══════════════════════════════════════════════════════════════════════════
-- LANGKAH 3 — Buat auth.users + profiles untuk setiap OPD
--
--   LOGIKA EMAIL LOGIN:
--     Prioritas 1 : opd_organizations.email (misal bkpsdm@bandungkab.go.id)
--     Prioritas 2 : username@sipelor.go.id  (jika kolom email kosong)
--
--   Ini PENTING: email login di auth.users harus cocok dengan email yang
--   digunakan Flutter saat login. Kolom opd_organizations.email sudah
--   berisi email asli (@bandungkab.go.id) dan itulah yang dipakai.
-- ══════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  rec          RECORD;
  new_uid      UUID;
  login_email  TEXT;
  default_pw   TEXT := 'Sipelor@2026';
  enc_pw       TEXT;
  created_cnt  INT  := 0;
  skipped_cnt  INT  := 0;
  updated_cnt  INT  := 0;
BEGIN

  FOR rec IN
    SELECT id, name, username, email
    FROM   public.opd_organizations
    WHERE  username IS NOT NULL
    ORDER  BY name
  LOOP
    -- Tentukan email login
    login_email := COALESCE(NULLIF(trim(rec.email), ''), rec.username || '@sipelor.go.id');

    -- ── Jika akun sudah ada di auth.users: skip pembuatan, tapi patch profile ──
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = login_email) THEN
      RAISE NOTICE '[SKIP] auth.users sudah ada: %', login_email;
      skipped_cnt := skipped_cnt + 1;

      -- Patch profile yang mungkin belum punya username
      UPDATE public.profiles p
      SET    username   = rec.username,
             updated_at = now()
      FROM   auth.users u
      WHERE  u.email  = login_email
        AND  p.id     = u.id
        AND  (p.username IS NULL OR p.username = '');

      IF FOUND THEN
        RAISE NOTICE '  → Profile username di-patch: %', rec.username;
        updated_cnt := updated_cnt + 1;
      END IF;

      CONTINUE;
    END IF;

    -- ── Buat UUID baru & hash password bcrypt ──────────────────────────────
    new_uid := gen_random_uuid();
    enc_pw  := crypt(default_pw, gen_salt('bf', 10));

    -- ── Insert ke auth.users (semua kolom wajib Supabase) ─────────────────
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at,
      is_sso_user,
      deleted_at,
      is_anonymous
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',   -- instance_id (fixed di Supabase)
      new_uid,
      'authenticated',
      'authenticated',
      login_email,
      enc_pw,
      now(),          -- email_confirmed_at (langsung dikonfirmasi, tidak perlu verifikasi email)
      NULL,           -- invited_at
      '',             -- confirmation_token
      NULL,           -- confirmation_sent_at
      '',             -- recovery_token
      NULL,           -- recovery_sent_at
      '',             -- email_change_token_new
      '',             -- email_change
      NULL,           -- email_change_sent_at
      NULL,           -- last_sign_in_at
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object(
        'full_name', rec.name,
        'opd_id',    rec.id::text,
        'username',  rec.username
      ),
      false,          -- is_super_admin
      now(),          -- created_at
      now(),          -- updated_at
      NULL,           -- phone
      NULL,           -- phone_confirmed_at
      '',             -- phone_change
      '',             -- phone_change_token
      NULL,           -- phone_change_sent_at
      '',             -- email_change_token_current
      0,              -- email_change_confirm_status
      NULL,           -- banned_until
      '',             -- reauthentication_token
      NULL,           -- reauthentication_sent_at
      false,          -- is_sso_user
      NULL,           -- deleted_at
      false           -- is_anonymous
    );

    -- ── Insert / Update ke public.profiles ────────────────────────────────
    -- PENTING: username wajib diisi agar RPC get_email_by_username berjalan
    INSERT INTO public.profiles (
      id, username, email, full_name, role, created_at, updated_at
    ) VALUES (
      new_uid,
      rec.username,
      login_email,
      rec.name,
      'operator',     -- role OPD: operator
      now(),
      now()
    )
    ON CONFLICT (id) DO UPDATE
      SET username   = EXCLUDED.username,
          email      = EXCLUDED.email,
          full_name  = EXCLUDED.full_name,
          role       = EXCLUDED.role,
          updated_at = now();

    RAISE NOTICE '[OK] Dibuat: %-%-% → %', rec.name, ' (', rec.username, login_email;
    created_cnt := created_cnt + 1;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '══════════════════════════════════════════════════════';
  RAISE NOTICE 'SELESAI MIGRASI AUTH USERS';
  RAISE NOTICE '  Dibuat baru  : %', created_cnt;
  RAISE NOTICE '  Dilewati     : %', skipped_cnt;
  RAISE NOTICE '  Profile patch: %', updated_cnt;
  RAISE NOTICE '══════════════════════════════════════════════════════';
END;
$$;


-- ══════════════════════════════════════════════════════════════════════════
-- LANGKAH 4 — Patch semua profiles OPD yang username-nya masih NULL
--             (untuk akun yang sudah ada sebelum script ini dijalankan)
-- ══════════════════════════════════════════════════════════════════════════

-- Case A: email login = username@sipelor.go.id (tidak ada email asli)
UPDATE public.profiles p
SET    username   = o.username,
       updated_at = now()
FROM   public.opd_organizations o
WHERE  p.email = o.username || '@sipelor.go.id'
  AND  o.username IS NOT NULL
  AND  (p.username IS NULL OR p.username = '');

-- Case B: email login = email asli OPD (@bandungkab.go.id)
UPDATE public.profiles p
SET    username   = o.username,
       updated_at = now()
FROM   public.opd_organizations o
WHERE  o.email IS NOT NULL
  AND  o.email != ''
  AND  p.email = o.email
  AND  o.username IS NOT NULL
  AND  (p.username IS NULL OR p.username = '');


-- ══════════════════════════════════════════════════════════════════════════
-- VERIFIKASI — Status akhir semua akun OPD
--
--   Kolom "Auth User" : ✅ Ada = akun berhasil di Authentication > Users
--                       ❌ BELUM  = akun belum terbuat
--   Kolom "Profile"   : ✅ Ada = profil ada & username ter-set
--                       ⚠ ADA/NULL = profil ada tapi username masih NULL
--                       ❌ BELUM  = profil belum ada
-- ══════════════════════════════════════════════════════════════════════════
SELECT
  o.name                                                                AS "Nama OPD",
  o.username                                                            AS "Username Login",
  COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')  AS "Email Login",
  CASE
    WHEN u.id IS NOT NULL THEN '✅ Ada'
    ELSE                       '❌ BELUM DIBUAT'
  END                                                                   AS "Auth User",
  CASE
    WHEN p.id IS NOT NULL AND (p.username IS NOT NULL AND p.username != '') THEN '✅ Ada'
    WHEN p.id IS NOT NULL AND (p.username IS NULL OR p.username = '')       THEN '⚠ Ada / Username NULL'
    ELSE                                                                         '❌ BELUM DIBUAT'
  END                                                                   AS "Profile",
  p.role                                                                AS "Role"
FROM public.opd_organizations o
LEFT JOIN auth.users u
  ON  u.email = COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')
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
