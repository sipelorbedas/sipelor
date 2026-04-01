-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Tambah Username & Password Login OPD             ║
-- ║   Tabel  : public.opd_organizations                                 ║
-- ║   Dibuat : 2026-03-06                                               ║
-- ║                                                                      ║
-- ║   CARA PAKAI:                                                        ║
-- ║     1. Buka Supabase Dashboard → SQL Editor                         ║
-- ║     2. Jalankan BAGIAN 1 dan 2 dulu                                 ║
-- ║     3. Untuk membuat akun login, jalankan BAGIAN 3                  ║
-- ╚══════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 1 — Tambah kolom username & default_password
-- ══════════════════════════════════════════════════════════════════════
ALTER TABLE public.opd_organizations
  ADD COLUMN IF NOT EXISTS username         text UNIQUE,
  ADD COLUMN IF NOT EXISTS default_password text NOT NULL DEFAULT 'Sipelor@2026';

-- Index username untuk lookup cepat
CREATE UNIQUE INDEX IF NOT EXISTS idx_opd_organizations_username
  ON public.opd_organizations (username)
  WHERE username IS NOT NULL;


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 2 — Update username untuk setiap OPD & Kecamatan
-- ══════════════════════════════════════════════════════════════════════

-- ── BADAN ─────────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'bkpsdm'
  WHERE name ILIKE '%Kepegawaian dan Pengembangan Sumber Daya Manusia%';

UPDATE public.opd_organizations SET username = 'bakesbangpol'
  WHERE name ILIKE '%Kesatuan Bangsa dan Politik%';

UPDATE public.opd_organizations SET username = 'bkad'
  WHERE name ILIKE '%Keuangan dan Aset Daerah%';

UPDATE public.opd_organizations SET username = 'bapenda'
  WHERE name ILIKE '%Pendapatan Daerah%';

UPDATE public.opd_organizations SET username = 'bapperida'
  WHERE name ILIKE '%Perencanaan Pembangunan, Riset%';

UPDATE public.opd_organizations SET username = 'bpbd'
  WHERE name ILIKE '%Penanggulangan Bencana Daerah%';

-- ── DINAS ──────────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'disbud'
  WHERE name ILIKE '%Dinas Kebudayaan%';

UPDATE public.opd_organizations SET username = 'disdukcapil'
  WHERE name ILIKE '%Kependudukan dan Pencatatan Sipil%';

UPDATE public.opd_organizations SET username = 'diskpp'
  WHERE name ILIKE '%Ketahanan Pangan dan Perikanan%';

UPDATE public.opd_organizations SET username = 'disnaker'
  WHERE name ILIKE '%Ketenagakerjaan%';

UPDATE public.opd_organizations SET username = 'diskominfo'
  WHERE name ILIKE '%Komunikasi dan Informatika%';

UPDATE public.opd_organizations SET username = 'diskopukm'
  WHERE name ILIKE '%Koperasi dan Usaha Kecil%';

UPDATE public.opd_organizations SET username = 'dlh'
  WHERE name ILIKE '%Lingkungan Hidup%';

UPDATE public.opd_organizations SET username = 'disparekraf'
  WHERE name ILIKE '%Pariwisata dan Ekonomi Kreatif%';

UPDATE public.opd_organizations SET username = 'dpupr'
  WHERE name ILIKE '%Pekerjaan Umum dan Tata Ruang%';

UPDATE public.opd_organizations SET username = 'dpkp'
  WHERE name ILIKE '%Pemadam Kebakaran%';

UPDATE public.opd_organizations SET username = 'dpmd'
  WHERE name ILIKE '%Pemberdayaan Masyarakat dan Desa%';

UPDATE public.opd_organizations SET username = 'dispora'
  WHERE name ILIKE '%Pemuda dan Olahraga%';

UPDATE public.opd_organizations SET username = 'dpmptsp'
  WHERE name ILIKE '%Penanaman Modal dan Pelayanan Terpadu%';

UPDATE public.opd_organizations SET username = 'disdik'
  WHERE name ILIKE '%Dinas Pendidikan%';

UPDATE public.opd_organizations SET username = 'dp2kbp3a'
  WHERE name ILIKE '%Keluarga Berencana%';

UPDATE public.opd_organizations SET username = 'dishub'
  WHERE name ILIKE '%Perhubungan%';

UPDATE public.opd_organizations SET username = 'dispusip'
  WHERE name ILIKE '%Perpustakaan dan Arsip%';

UPDATE public.opd_organizations SET username = 'distani'
  WHERE name ILIKE '%Dinas Pertanian%';

UPDATE public.opd_organizations SET username = 'dpkpp'
  WHERE name ILIKE '%Perumahan, Kawasan Permukiman%';

UPDATE public.opd_organizations SET username = 'dinsos'
  WHERE name ILIKE '%Dinas Sosial%';

UPDATE public.opd_organizations SET username = 'dinkes'
  WHERE name ILIKE '%Dinas Kesehatan%';

UPDATE public.opd_organizations SET username = 'disdagin'
  WHERE name ILIKE '%Perdagangan dan Perindustrian%';

-- ── SATUAN & DPRD ──────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'satpolpp'
  WHERE name ILIKE '%Polisi Pamong Praja%';

UPDATE public.opd_organizations SET username = 'dprd'
  WHERE name ILIKE '%Sekretaris DPRD%';

-- ── KECAMATAN ─────────────────────────────────────────────────────────
UPDATE public.opd_organizations SET username = 'kec.arjasari'     WHERE name = 'Kecamatan Arjasari';
UPDATE public.opd_organizations SET username = 'kec.baleendah'    WHERE name = 'Kecamatan Baleendah';
UPDATE public.opd_organizations SET username = 'kec.banjaran'     WHERE name = 'Kecamatan Banjaran';
UPDATE public.opd_organizations SET username = 'kec.bojongsoang'  WHERE name = 'Kecamatan Bojongsoang';
UPDATE public.opd_organizations SET username = 'kec.cangkuang'    WHERE name = 'Kecamatan Cangkuang';
UPDATE public.opd_organizations SET username = 'kec.cicalengka'   WHERE name = 'Kecamatan Cicalengka';
UPDATE public.opd_organizations SET username = 'kec.cikancung'    WHERE name = 'Kecamatan Cikancung';
UPDATE public.opd_organizations SET username = 'kec.cilengkrang'  WHERE name = 'Kecamatan Cilengkrang';
UPDATE public.opd_organizations SET username = 'kec.cileunyi'     WHERE name = 'Kecamatan Cileunyi';
UPDATE public.opd_organizations SET username = 'kec.cimaung'      WHERE name = 'Kecamatan Cimaung';
UPDATE public.opd_organizations SET username = 'kec.cimenyan'     WHERE name = 'Kecamatan Cimenyan';
UPDATE public.opd_organizations SET username = 'kec.ciparay'      WHERE name = 'Kecamatan Ciparay';
UPDATE public.opd_organizations SET username = 'kec.ciwidey'      WHERE name = 'Kecamatan Ciwidey';
UPDATE public.opd_organizations SET username = 'kec.dayeuhkolot'  WHERE name = 'Kecamatan Dayeuhkolot';
UPDATE public.opd_organizations SET username = 'kec.ibun'         WHERE name = 'Kecamatan Ibun';
UPDATE public.opd_organizations SET username = 'kec.katapang'     WHERE name = 'Kecamatan Katapang';
UPDATE public.opd_organizations SET username = 'kec.kertasari'    WHERE name = 'Kecamatan Kertasari';
UPDATE public.opd_organizations SET username = 'kec.kutawaringin' WHERE name = 'Kecamatan Kutawaringin';
UPDATE public.opd_organizations SET username = 'kec.majalaya'     WHERE name = 'Kecamatan Majalaya';
UPDATE public.opd_organizations SET username = 'kec.margaasih'    WHERE name = 'Kecamatan Margaasih';
UPDATE public.opd_organizations SET username = 'kec.margahayu'    WHERE name = 'Kecamatan Margahayu';
UPDATE public.opd_organizations SET username = 'kec.nagreg'       WHERE name = 'Kecamatan Nagreg';
UPDATE public.opd_organizations SET username = 'kec.pacet'        WHERE name = 'Kecamatan Pacet';
UPDATE public.opd_organizations SET username = 'kec.pameungpeuk'  WHERE name = 'Kecamatan Pameungpeuk';
UPDATE public.opd_organizations SET username = 'kec.pangalengan'  WHERE name = 'Kecamatan Pangalengan';
UPDATE public.opd_organizations SET username = 'kec.paseh'        WHERE name = 'Kecamatan Paseh';
UPDATE public.opd_organizations SET username = 'kec.pasirjambu'   WHERE name = 'Kecamatan Pasirjambu';
UPDATE public.opd_organizations SET username = 'kec.rancabali'    WHERE name = 'Kecamatan Rancabali';
UPDATE public.opd_organizations SET username = 'kec.rancaekek'    WHERE name = 'Kecamatan Rancaekek';
UPDATE public.opd_organizations SET username = 'kec.solokanjeruk' WHERE name = 'Kecamatan Solokanjeruk';
UPDATE public.opd_organizations SET username = 'kec.soreang'      WHERE name = 'Kecamatan Soreang';


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 3 — Buat akun login Supabase (auth.users + profiles)
--            ⚠️ Pastikan extension pgcrypto aktif:
--               Supabase Dashboard → Database → Extensions → pgcrypto → Enable
--            ⚠️ Jalankan via SQL Editor dengan role superadmin/service
-- ══════════════════════════════════════════════════════════════════════

-- Aktifkan pgcrypto jika belum aktif
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Fungsi helper: buat auth user + profile untuk satu OPD
-- Dipanggil lewat INSERT SELECT di bawah
DO $$
DECLARE
  rec        RECORD;
  new_uid    UUID;
  login_email TEXT;
  default_pw  TEXT := 'Sipelor@2026';   -- ← Ganti password awal di sini
BEGIN
  FOR rec IN
    SELECT id, name, username, email
    FROM public.opd_organizations
    WHERE username IS NOT NULL
    ORDER BY name
  LOOP
    -- Email login = username@sipelor.go.id jika email OPD tidak ada
    login_email := COALESCE(NULLIF(trim(rec.email), ''), rec.username || '@sipelor.go.id');

    -- Lewati jika email sudah ada di auth.users
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = login_email) THEN
      RAISE NOTICE 'Skip (sudah ada): %', login_email;
      CONTINUE;
    END IF;

    -- Buat UUID baru
    new_uid := gen_random_uuid();

    -- Insert ke auth.users
    INSERT INTO auth.users (
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_user_meta_data,
      raw_app_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token
    ) VALUES (
      new_uid,
      'authenticated',
      'authenticated',
      login_email,
      crypt(default_pw, gen_salt('bf', 12)),
      now(),
      jsonb_build_object('full_name', rec.name, 'opd_id', rec.id),
      '{"provider":"email","providers":["email"]}',
      now(),
      now(),
      '',
      ''
    );

    -- Insert ke profiles
    INSERT INTO public.profiles (id, username, email, full_name, role, created_at, updated_at)
    VALUES (
      new_uid,
      rec.username,
      login_email,
      rec.name,
      'operator',   -- role: operator (bisa baca jadwal, tidak bisa kelola admin)
      now(),
      now()
    )
    ON CONFLICT (id) DO NOTHING;

    -- Catat auth_user_id di opd_organizations (opsional, jika kolom ada)
    -- UPDATE public.opd_organizations SET auth_user_id = new_uid WHERE id = rec.id;

    RAISE NOTICE 'Dibuat: % → %', rec.name, login_email;
  END LOOP;
END;
$$;


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 4 — Patch profiles OPD yang username-nya masih NULL
--            Jalankan ini jika akun OPD sudah dibuat sebelum fix SQL
--            (yaitu sebelum kolom username ditambahkan ke INSERT profiles)
-- ══════════════════════════════════════════════════════════════════════

-- Update profiles yang email-nya cocok dengan pola username@sipelor.go.id
-- (akun OPD tanpa email real → email dibuat dari username)
UPDATE public.profiles p
SET
  username   = o.username,
  updated_at = now()
FROM public.opd_organizations o
WHERE p.email = o.username || '@sipelor.go.id'
  AND o.username IS NOT NULL
  AND (p.username IS NULL OR p.username = '');

-- Update profiles yang email-nya cocok langsung dengan email OPD
-- (akun OPD yang punya email real → email OPD dipakai sebagai login)
UPDATE public.profiles p
SET
  username   = o.username,
  updated_at = now()
FROM public.opd_organizations o
WHERE p.email = o.email
  AND o.username IS NOT NULL
  AND o.email IS NOT NULL
  AND o.email != ''
  AND (p.username IS NULL OR p.username = '');

-- Tampilkan berapa profil yang berhasil dipatch
SELECT
  COUNT(*) FILTER (WHERE o.username IS NOT NULL AND p.username = o.username) AS "Profil OPD Terpatch",
  COUNT(*) FILTER (WHERE o.username IS NOT NULL AND p.username IS NULL)       AS "Profil OPD Masih NULL"
FROM public.profiles p
JOIN public.opd_organizations o
  ON p.email = o.username || '@sipelor.go.id'
  OR p.email = o.email;


-- ══════════════════════════════════════════════════════════════════════
-- VERIFIKASI — Tampilkan semua kredensial yang dihasilkan
-- ══════════════════════════════════════════════════════════════════════
SELECT
  o.name                                                         AS "Nama OPD",
  o.username                                                     AS "Username",
  COALESCE(NULLIF(o.email, ''), o.username || '@sipelor.go.id') AS "Email Login",
  o.default_password                                             AS "Password Default",
  o.is_active                                                    AS "Aktif"
FROM public.opd_organizations o
WHERE o.username IS NOT NULL
ORDER BY
  CASE
    WHEN o.name ILIKE 'Badan%'     THEN 1
    WHEN o.name ILIKE 'Dinas%'     THEN 2
    WHEN o.name ILIKE 'Satuan%'    THEN 3
    WHEN o.name ILIKE 'Sekretaris%' THEN 4
    WHEN o.name ILIKE 'Kecamatan%' THEN 5
    ELSE 6
  END,
  o.name;
