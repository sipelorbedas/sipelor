-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Daftar OPD & Pimpinan Kabupaten Bandung           ║
-- ║   Tabel  : public.opd_organizations                                 ║
-- ║   Dibuat : 2026-03-06                                               ║
-- ║                                                                      ║
-- ║   CARA PAKAI:                                                        ║
-- ║     1. Buka Supabase Dashboard → SQL Editor                         ║
-- ║     2. Copy-paste seluruh isi file ini                              ║
-- ║     3. Klik "Run"                                                    ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────────────────────────────
-- OPSIONAL: Hapus data OPD lama sebelum insert ulang
-- (Uncomment jika ingin reset data)
-- ──────────────────────────────────────────────────────────────────────
-- DELETE FROM public.opd_organizations
--   WHERE name NOT ILIKE '%Bupati%';


-- ──────────────────────────────────────────────────────────────────────
-- BADAN / DINAS / SATUAN — 30 OPD
-- ──────────────────────────────────────────────────────────────────────
INSERT INTO public.opd_organizations
  (name, contact_person, phone, email, is_active, discount_percentage)
VALUES

  -- BADAN
  ('Badan Kepegawaian dan Pengembangan Sumber Daya Manusia',
   'Kepala Badan',                '022-5940095', 'bkpsdm@bandungkab.go.id',       true, 75),

  ('Badan Kesatuan Bangsa dan Politik',
   'Kepala Badan',                '022-5890157', 'bakesbangpol@bandungkab.go.id', true, 75),

  ('Badan Keuangan dan Aset Daerah',
   'Kepala Badan',                '022-5890143', 'bkad@bandungkab.go.id',         true, 75),

  ('Badan Pendapatan Daerah',
   'Kepala Badan',                '022-5890114', 'bapenda@bandungkab.go.id',      true, 75),

  ('Badan Perencanaan Pembangunan, Riset dan Inovasi Daerah',
   'Kepala Badan',                '022-5890126', 'bapperida@bandungkab.go.id',    true, 75),

  ('Badan Penanggulangan Bencana Daerah',
   'Kepala Pelaksana',            '022-5890135', 'bpbd@bandungkab.go.id',         true, 75),

  -- DINAS
  ('Dinas Kebudayaan',
   'Kepala Dinas',                '022-5890200', 'disbud@bandungkab.go.id',       true, 75),

  ('Dinas Kependudukan dan Pencatatan Sipil',
   'Kepala Dinas',                '022-5890201', 'disdukcapil@bandungkab.go.id',  true, 75),

  ('Dinas Ketahanan Pangan dan Perikanan',
   'Kepala Dinas',                '022-5890202', 'diskpp@bandungkab.go.id',       true, 75),

  ('Dinas Ketenagakerjaan',
   'Kepala Dinas',                '022-5890203', 'disnaker@bandungkab.go.id',     true, 75),

  ('Dinas Komunikasi dan Informatika, Statistik dan Persandian',
   'Kepala Dinas',                '022-5890204', 'diskominfo@bandungkab.go.id',   true, 75),

  ('Dinas Koperasi dan Usaha Kecil dan Menengah',
   'Kepala Dinas',                '022-5890205', 'diskopukm@bandungkab.go.id',    true, 75),

  ('Dinas Lingkungan Hidup',
   'Kepala Dinas',                '022-5890206', 'dlh@bandungkab.go.id',          true, 75),

  ('Dinas Pariwisata dan Ekonomi Kreatif',
   'Kepala Dinas',                '022-5890207', 'disparekraf@bandungkab.go.id',  true, 75),

  ('Dinas Pekerjaan Umum dan Tata Ruang',
   'Kepala Dinas',                '022-5890208', 'dpupr@bandungkab.go.id',        true, 75),

  ('Dinas Pemadam Kebakaran dan Penyelamatan',
   'Kepala Dinas',                '022-5890209', 'dpkp@bandungkab.go.id',         true, 75),

  ('Dinas Pemberdayaan Masyarakat dan Desa',
   'Kepala Dinas',                '022-5890210', 'dpmd@bandungkab.go.id',         true, 75),

  ('Dinas Pemuda dan Olahraga',
   'Kepala Dinas',                '022-5890237', 'dispora@bandungkab.go.id',      true, 75),

  ('Dinas Penanaman Modal dan Pelayanan Terpadu Satu Pintu',
   'Kepala Dinas',                '022-5890211', 'dpmptsp@bandungkab.go.id',      true, 75),

  ('Dinas Pendidikan',
   'Kepala Dinas',                '022-5890235', 'disdik@bandungkab.go.id',       true, 50),

  ('Dinas Pengendalian Penduduk, Keluarga Berencana, Pemberdayaan Perempuan dan Perlindungan Anak',
   'Kepala Dinas',                '022-5890212', 'dp2kbp3a@bandungkab.go.id',     true, 75),

  ('Dinas Perhubungan',
   'Kepala Dinas',                '022-5890213', 'dishub@bandungkab.go.id',       true, 75),

  ('Dinas Perpustakaan dan Arsip',
   'Kepala Dinas',                '022-5890214', 'dispusip@bandungkab.go.id',     true, 75),

  ('Dinas Pertanian',
   'Kepala Dinas',                '022-5890215', 'distani@bandungkab.go.id',      true, 75),

  ('Dinas Perumahan, Kawasan Permukiman dan Pertanahan',
   'Kepala Dinas',                '022-5890216', 'dpkpp@bandungkab.go.id',        true, 75),

  ('Dinas Sosial',
   'Kepala Dinas',                '022-5890217', 'dinsos@bandungkab.go.id',       true, 75),

  ('Dinas Kesehatan',
   'Kepala Dinas',                '022-5890236', 'dinkes@bandungkab.go.id',       true, 50),

  ('Dinas Perdagangan dan Perindustrian',
   'Kepala Dinas',                '022-5890218', 'disdagin@bandungkab.go.id',     true, 75),

  -- SATUAN
  ('Satuan Polisi Pamong Praja',
   'Kepala Satuan',               '022-5890219', 'satpolpp@bandungkab.go.id',     true, 75),

  -- DPRD
  ('Sekretaris DPRD',
   'Sekretaris DPRD',             '022-5890239', 'dprd@bandungkab.go.id',         true, 75)

ON CONFLICT DO NOTHING;


-- ──────────────────────────────────────────────────────────────────────
-- KECAMATAN — 31 Kecamatan se-Kabupaten Bandung
-- ──────────────────────────────────────────────────────────────────────
INSERT INTO public.opd_organizations
  (name, contact_person, phone, email, is_active, discount_percentage)
VALUES

  ('Kecamatan Arjasari',      'Camat Arjasari',      '022-5890301', 'kec.arjasari@bandungkab.go.id',      true, 50),
  ('Kecamatan Baleendah',     'Camat Baleendah',     '022-5890302', 'kec.baleendah@bandungkab.go.id',     true, 50),
  ('Kecamatan Banjaran',      'Camat Banjaran',      '022-5890303', 'kec.banjaran@bandungkab.go.id',      true, 50),
  ('Kecamatan Bojongsoang',   'Camat Bojongsoang',   '022-5890304', 'kec.bojongsoang@bandungkab.go.id',   true, 50),
  ('Kecamatan Cangkuang',     'Camat Cangkuang',     '022-5890305', 'kec.cangkuang@bandungkab.go.id',     true, 50),
  ('Kecamatan Cicalengka',    'Camat Cicalengka',    '022-5890306', 'kec.cicalengka@bandungkab.go.id',    true, 50),
  ('Kecamatan Cikancung',     'Camat Cikancung',     '022-5890307', 'kec.cikancung@bandungkab.go.id',     true, 50),
  ('Kecamatan Cilengkrang',   'Camat Cilengkrang',   '022-5890308', 'kec.cilengkrang@bandungkab.go.id',   true, 50),
  ('Kecamatan Cileunyi',      'Camat Cileunyi',      '022-5890309', 'kec.cileunyi@bandungkab.go.id',      true, 50),
  ('Kecamatan Cimaung',       'Camat Cimaung',       '022-5890310', 'kec.cimaung@bandungkab.go.id',       true, 50),
  ('Kecamatan Cimenyan',      'Camat Cimenyan',      '022-5890311', 'kec.cimenyan@bandungkab.go.id',      true, 50),
  ('Kecamatan Ciparay',       'Camat Ciparay',       '022-5890312', 'kec.ciparay@bandungkab.go.id',       true, 50),
  ('Kecamatan Ciwidey',       'Camat Ciwidey',       '022-5890313', 'kec.ciwidey@bandungkab.go.id',       true, 50),
  ('Kecamatan Dayeuhkolot',   'Camat Dayeuhkolot',   '022-5890314', 'kec.dayeuhkolot@bandungkab.go.id',   true, 50),
  ('Kecamatan Ibun',          'Camat Ibun',          '022-5890315', 'kec.ibun@bandungkab.go.id',          true, 50),
  ('Kecamatan Katapang',      'Camat Katapang',      '022-5890316', 'kec.katapang@bandungkab.go.id',      true, 50),
  ('Kecamatan Kertasari',     'Camat Kertasari',     '022-5890317', 'kec.kertasari@bandungkab.go.id',     true, 50),
  ('Kecamatan Kutawaringin',  'Camat Kutawaringin',  '022-5890318', 'kec.kutawaringin@bandungkab.go.id',  true, 50),
  ('Kecamatan Majalaya',      'Camat Majalaya',      '022-5890319', 'kec.majalaya@bandungkab.go.id',      true, 50),
  ('Kecamatan Margaasih',     'Camat Margaasih',     '022-5890320', 'kec.margaasih@bandungkab.go.id',     true, 50),
  ('Kecamatan Margahayu',     'Camat Margahayu',     '022-5890321', 'kec.margahayu@bandungkab.go.id',     true, 50),
  ('Kecamatan Nagreg',        'Camat Nagreg',        '022-5890322', 'kec.nagreg@bandungkab.go.id',        true, 50),
  ('Kecamatan Pacet',         'Camat Pacet',         '022-5890323', 'kec.pacet@bandungkab.go.id',         true, 50),
  ('Kecamatan Pameungpeuk',   'Camat Pameungpeuk',   '022-5890324', 'kec.pameungpeuk@bandungkab.go.id',   true, 50),
  ('Kecamatan Pangalengan',   'Camat Pangalengan',   '022-5890325', 'kec.pangalengan@bandungkab.go.id',   true, 50),
  ('Kecamatan Paseh',         'Camat Paseh',         '022-5890326', 'kec.paseh@bandungkab.go.id',         true, 50),
  ('Kecamatan Pasirjambu',    'Camat Pasirjambu',    '022-5890327', 'kec.pasirjambu@bandungkab.go.id',    true, 50),
  ('Kecamatan Rancabali',     'Camat Rancabali',     '022-5890328', 'kec.rancabali@bandungkab.go.id',     true, 50),
  ('Kecamatan Rancaekek',     'Camat Rancaekek',     '022-5890329', 'kec.rancaekek@bandungkab.go.id',     true, 50),
  ('Kecamatan Solokanjeruk',  'Camat Solokanjeruk',  '022-5890330', 'kec.solokanjeruk@bandungkab.go.id',  true, 50),
  ('Kecamatan Soreang',       'Camat Soreang',       '022-5890331', 'kec.soreang@bandungkab.go.id',       true, 50)

ON CONFLICT DO NOTHING;


-- ──────────────────────────────────────────────────────────────────────
-- VERIFIKASI — Cek data yang baru di-insert
-- ──────────────────────────────────────────────────────────────────────
SELECT
  name,
  contact_person,
  email,
  discount_percentage,
  is_active
FROM public.opd_organizations
ORDER BY
  CASE
    WHEN name ILIKE 'Badan%'    THEN 1
    WHEN name ILIKE 'Dinas%'    THEN 2
    WHEN name ILIKE 'Satuan%'   THEN 3
    WHEN name ILIKE 'Sekretaris%' THEN 4
    WHEN name ILIKE 'Kecamatan%' THEN 5
    ELSE 6
  END,
  name;
