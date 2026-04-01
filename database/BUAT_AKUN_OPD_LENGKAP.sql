-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Buat Akun Login OPD (All-in-One)                 ║
-- ║   CARA PAKAI:                                                        ║
-- ║     1. Buka Supabase Dashboard → SQL Editor                         ║
-- ║     2. Copy-paste seluruh isi file ini                              ║
-- ║     3. Klik RUN                                                      ║
-- ║                                                                      ║
-- ║   File ini menggabungkan:                                            ║
-- ║     - Tambah kolom username di opd_organizations                     ║
-- ║     - Set username tiap OPD                                          ║
-- ║     - Buat akun auth.users + profiles                                ║
-- ║                                                                      ║
-- ║   Email login : username@sipelor.go.id                               ║
-- ║   Password    : Sipelor@2026                                         ║
-- ╚══════════════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 1: Aktifkan pgcrypto (untuk hash password)
-- ══════════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 2: Tambah kolom username di tabel opd_organizations
-- ══════════════════════════════════════════════════════════════════════
ALTER TABLE public.opd_organizations
  ADD COLUMN IF NOT EXISTS username         text,
  ADD COLUMN IF NOT EXISTS default_password text NOT NULL DEFAULT 'Sipelor@2026';

CREATE UNIQUE INDEX IF NOT EXISTS idx_opd_organizations_username
  ON public.opd_organizations (username)
  WHERE username IS NOT NULL;


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 3: Set username untuk setiap OPD
-- ══════════════════════════════════════════════════════════════════════

-- BADAN
UPDATE public.opd_organizations SET username = 'bkpsdm'       WHERE name ILIKE '%Kepegawaian dan Pengembangan Sumber Daya Manusia%';
UPDATE public.opd_organizations SET username = 'bakesbangpol'  WHERE name ILIKE '%Kesatuan Bangsa dan Politik%';
UPDATE public.opd_organizations SET username = 'bkad'          WHERE name ILIKE '%Keuangan dan Aset Daerah%';
UPDATE public.opd_organizations SET username = 'bapenda'       WHERE name ILIKE '%Pendapatan Daerah%';
UPDATE public.opd_organizations SET username = 'bapperida'     WHERE name ILIKE '%Perencanaan Pembangunan, Riset%';
UPDATE public.opd_organizations SET username = 'bpbd'          WHERE name ILIKE '%Penanggulangan Bencana Daerah%';

-- DINAS
UPDATE public.opd_organizations SET username = 'disbud'        WHERE name ILIKE '%Dinas Kebudayaan%';
UPDATE public.opd_organizations SET username = 'disdukcapil'   WHERE name ILIKE '%Kependudukan dan Pencatatan Sipil%';
UPDATE public.opd_organizations SET username = 'diskpp'        WHERE name ILIKE '%Ketahanan Pangan dan Perikanan%';
UPDATE public.opd_organizations SET username = 'disnaker'      WHERE name ILIKE '%Ketenagakerjaan%';
UPDATE public.opd_organizations SET username = 'diskominfo'    WHERE name ILIKE '%Komunikasi dan Informatika%';
UPDATE public.opd_organizations SET username = 'diskopukm'     WHERE name ILIKE '%Koperasi dan Usaha Kecil%';
UPDATE public.opd_organizations SET username = 'dlh'           WHERE name ILIKE '%Lingkungan Hidup%';
UPDATE public.opd_organizations SET username = 'disparekraf'   WHERE name ILIKE '%Pariwisata dan Ekonomi Kreatif%';
UPDATE public.opd_organizations SET username = 'dpupr'         WHERE name ILIKE '%Pekerjaan Umum dan Tata Ruang%';
UPDATE public.opd_organizations SET username = 'dpkp'          WHERE name ILIKE '%Pemadam Kebakaran%';
UPDATE public.opd_organizations SET username = 'dpmd'          WHERE name ILIKE '%Pemberdayaan Masyarakat dan Desa%';
UPDATE public.opd_organizations SET username = 'dispora'       WHERE name ILIKE '%Pemuda dan Olahraga%';
UPDATE public.opd_organizations SET username = 'dpmptsp'       WHERE name ILIKE '%Penanaman Modal dan Pelayanan Terpadu%';
UPDATE public.opd_organizations SET username = 'disdik'        WHERE name ILIKE '%Dinas Pendidikan%';
UPDATE public.opd_organizations SET username = 'dp2kbp3a'      WHERE name ILIKE '%Keluarga Berencana%';
UPDATE public.opd_organizations SET username = 'dishub'        WHERE name ILIKE '%Perhubungan%';
UPDATE public.opd_organizations SET username = 'dispusip'      WHERE name ILIKE '%Perpustakaan dan Arsip%';
UPDATE public.opd_organizations SET username = 'distani'       WHERE name ILIKE '%Dinas Pertanian%';
UPDATE public.opd_organizations SET username = 'dpkpp'         WHERE name ILIKE '%Perumahan, Kawasan Permukiman%';
UPDATE public.opd_organizations SET username = 'dinsos'        WHERE name ILIKE '%Dinas Sosial%';
UPDATE public.opd_organizations SET username = 'dinkes'        WHERE name ILIKE '%Dinas Kesehatan%';
UPDATE public.opd_organizations SET username = 'disdagin'      WHERE name ILIKE '%Perdagangan dan Perindustrian%';

-- SATUAN & DPRD
UPDATE public.opd_organizations SET username = 'satpolpp'      WHERE name ILIKE '%Polisi Pamong Praja%';
UPDATE public.opd_organizations SET username = 'dprd'          WHERE name ILIKE '%Sekretaris DPRD%';

-- KECAMATAN
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
-- BAGIAN 4: Buat akun auth.users + profiles untuk tiap OPD
-- ══════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  rec          RECORD;
  new_uid      UUID;
  login_email  TEXT;
  default_pw   TEXT := 'Sipelor@2026';
  enc_pw       TEXT;
  created_cnt  INT  := 0;
  skipped_cnt  INT  := 0;
BEGIN

  FOR rec IN
    SELECT id, name, username, email
    FROM   public.opd_organizations
    WHERE  username IS NOT NULL
    ORDER  BY name
  LOOP
    login_email := COALESCE(NULLIF(trim(rec.email), ''), rec.username || '@sipelor.go.id');

    IF EXISTS (SELECT 1 FROM auth.users WHERE email = login_email) THEN
      RAISE NOTICE '[SKIP] Sudah ada: %', login_email;
      skipped_cnt := skipped_cnt + 1;
      CONTINUE;
    END IF;

    new_uid := gen_random_uuid();
    enc_pw  := crypt(default_pw, gen_salt('bf'));

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at,
      recovery_token, recovery_sent_at, email_change_token_new, email_change,
      email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
      is_super_admin, created_at, updated_at, phone, phone_confirmed_at,
      phone_change, phone_change_token, phone_change_sent_at,
      email_change_token_current, email_change_confirm_status, banned_until,
      reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      new_uid,
      'authenticated',
      'authenticated',
      login_email,
      enc_pw,
      now(),
      NULL, '', NULL, '', NULL, '', '', NULL, NULL,
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', rec.name, 'opd_id', rec.id::text, 'username', rec.username),
      false, now(), now(),
      NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false
    );

    INSERT INTO public.profiles (
      id, username, email, full_name, role, created_at, updated_at
    ) VALUES (
      new_uid, rec.username, login_email, rec.name, 'operator', now(), now()
    )
    ON CONFLICT (id) DO UPDATE
      SET username   = EXCLUDED.username,
          email      = EXCLUDED.email,
          full_name  = EXCLUDED.full_name,
          role       = EXCLUDED.role,
          updated_at = now();

    RAISE NOTICE '[OK] Dibuat: % → %', rec.name, login_email;
    created_cnt := created_cnt + 1;
  END LOOP;

  RAISE NOTICE '====================================================';
  RAISE NOTICE 'SELESAI! Dibuat: %  |  Dilewati (sudah ada): %', created_cnt, skipped_cnt;
  RAISE NOTICE '====================================================';
END;
$$;


-- ══════════════════════════════════════════════════════════════════════
-- BAGIAN 5: Patch profiles lama yang username-nya masih NULL
-- ══════════════════════════════════════════════════════════════════════
UPDATE public.profiles p
SET    username   = o.username,
       updated_at = now()
FROM   public.opd_organizations o
WHERE  (
         p.email = o.username || '@sipelor.go.id'
         OR (o.email IS NOT NULL AND o.email != '' AND p.email = o.email)
       )
  AND  o.username IS NOT NULL
  AND  (p.username IS NULL OR p.username = '');


-- ══════════════════════════════════════════════════════════════════════
-- VERIFIKASI: Tampilkan status semua OPD
-- ══════════════════════════════════════════════════════════════════════
SELECT
  o.name                                                              AS "Nama OPD",
  o.username                                                          AS "Username",
  COALESCE(NULLIF(o.email, ''), o.username || '@sipelor.go.id')      AS "Email Login",
  CASE WHEN u.id IS NOT NULL THEN 'OK' ELSE 'BELUM DIBUAT' END       AS "Auth User",
  CASE WHEN p.id IS NOT NULL THEN 'OK' ELSE 'BELUM DIBUAT' END       AS "Profile",
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
  END, o.name;
