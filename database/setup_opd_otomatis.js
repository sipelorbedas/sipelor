/**
 * ╔══════════════════════════════════════════════════════════════════╗
 * ║  SIPELOR BEDAS — Setup Akun OPD Otomatis (via PostgreSQL)      ║
 * ║                                                                  ║
 * ║  CARA PAKAI:                                                     ║
 * ║    1. Isi DB_PASSWORD di bawah                                   ║
 * ║       (Supabase Dashboard → Project Settings → Database          ║
 * ║        → Database Password)                                      ║
 * ║    2. Jalankan di terminal:                                      ║
 * ║         cd database                                              ║
 * ║         npm install                                              ║
 * ║         node setup_opd_otomatis.js                               ║
 * ╚══════════════════════════════════════════════════════════════════╝
 */

// ── KONFIGURASI — isi DB_PASSWORD saja ─────────────────────────────────
const DB_PASSWORD    = 'nlvRxWoy5BdwmLmD';
// ↑ Supabase Dashboard → Project Settings → Database → Database Password
// ────────────────────────────────────────────────────────────────────────

const { Client } = require('pg');

const PROJECT_REF    = 'gbhprmibbcqfwjgrkfzq';
const DEFAULT_PW     = 'Sipelor@2026';

// ── Daftar username OPD ────────────────────────────────────────────────
const OPD_USERNAMES = [
  { username: 'bkpsdm',        match: '%Kepegawaian dan Pengembangan Sumber Daya Manusia%', exact: false },
  { username: 'bakesbangpol',  match: '%Kesatuan Bangsa dan Politik%',                       exact: false },
  { username: 'bkad',          match: '%Keuangan dan Aset Daerah%',                          exact: false },
  { username: 'bapenda',       match: '%Pendapatan Daerah%',                                 exact: false },
  { username: 'bapperida',     match: '%Perencanaan Pembangunan, Riset%',                    exact: false },
  { username: 'bpbd',          match: '%Penanggulangan Bencana Daerah%',                     exact: false },
  { username: 'disbud',        match: '%Dinas Kebudayaan%',                                  exact: false },
  { username: 'disdukcapil',   match: '%Kependudukan dan Pencatatan Sipil%',                 exact: false },
  { username: 'diskpp',        match: '%Ketahanan Pangan dan Perikanan%',                    exact: false },
  { username: 'disnaker',      match: '%Ketenagakerjaan%',                                   exact: false },
  { username: 'diskominfo',    match: '%Komunikasi dan Informatika%',                        exact: false },
  { username: 'diskopukm',     match: '%Koperasi dan Usaha Kecil%',                         exact: false },
  { username: 'dlh',           match: '%Lingkungan Hidup%',                                  exact: false },
  { username: 'disparekraf',   match: '%Pariwisata dan Ekonomi Kreatif%',                    exact: false },
  { username: 'dpupr',         match: '%Pekerjaan Umum dan Tata Ruang%',                    exact: false },
  { username: 'dpkp',          match: '%Pemadam Kebakaran%',                                 exact: false },
  { username: 'dpmd',          match: '%Pemberdayaan Masyarakat dan Desa%',                  exact: false },
  { username: 'dispora',       match: '%Pemuda dan Olahraga%',                               exact: false },
  { username: 'dpmptsp',       match: '%Penanaman Modal dan Pelayanan Terpadu%',             exact: false },
  { username: 'disdik',        match: '%Dinas Pendidikan%',                                  exact: false },
  { username: 'dp2kbp3a',      match: '%Keluarga Berencana%',                               exact: false },
  { username: 'dishub',        match: '%Perhubungan%',                                       exact: false },
  { username: 'dispusip',      match: '%Perpustakaan dan Arsip%',                            exact: false },
  { username: 'distani',       match: '%Dinas Pertanian%',                                   exact: false },
  { username: 'dpkpp',         match: '%Perumahan, Kawasan Permukiman%',                    exact: false },
  { username: 'dinsos',        match: '%Dinas Sosial%',                                      exact: false },
  { username: 'dinkes',        match: '%Dinas Kesehatan%',                                   exact: false },
  { username: 'disdagin',      match: '%Perdagangan dan Perindustrian%',                     exact: false },
  { username: 'satpolpp',      match: '%Polisi Pamong Praja%',                               exact: false },
  { username: 'dprd',          match: '%Sekretaris DPRD%',                                   exact: false },
  { username: 'kec.arjasari',     match: 'Kecamatan Arjasari',     exact: true },
  { username: 'kec.baleendah',    match: 'Kecamatan Baleendah',    exact: true },
  { username: 'kec.banjaran',     match: 'Kecamatan Banjaran',     exact: true },
  { username: 'kec.bojongsoang',  match: 'Kecamatan Bojongsoang',  exact: true },
  { username: 'kec.cangkuang',    match: 'Kecamatan Cangkuang',    exact: true },
  { username: 'kec.cicalengka',   match: 'Kecamatan Cicalengka',   exact: true },
  { username: 'kec.cikancung',    match: 'Kecamatan Cikancung',    exact: true },
  { username: 'kec.cilengkrang',  match: 'Kecamatan Cilengkrang',  exact: true },
  { username: 'kec.cileunyi',     match: 'Kecamatan Cileunyi',     exact: true },
  { username: 'kec.cimaung',      match: 'Kecamatan Cimaung',      exact: true },
  { username: 'kec.cimenyan',     match: 'Kecamatan Cimenyan',     exact: true },
  { username: 'kec.ciparay',      match: 'Kecamatan Ciparay',      exact: true },
  { username: 'kec.ciwidey',      match: 'Kecamatan Ciwidey',      exact: true },
  { username: 'kec.dayeuhkolot',  match: 'Kecamatan Dayeuhkolot',  exact: true },
  { username: 'kec.ibun',         match: 'Kecamatan Ibun',         exact: true },
  { username: 'kec.katapang',     match: 'Kecamatan Katapang',     exact: true },
  { username: 'kec.kertasari',    match: 'Kecamatan Kertasari',    exact: true },
  { username: 'kec.kutawaringin', match: 'Kecamatan Kutawaringin', exact: true },
  { username: 'kec.majalaya',     match: 'Kecamatan Majalaya',     exact: true },
  { username: 'kec.margaasih',    match: 'Kecamatan Margaasih',    exact: true },
  { username: 'kec.margahayu',    match: 'Kecamatan Margahayu',    exact: true },
  { username: 'kec.nagreg',       match: 'Kecamatan Nagreg',       exact: true },
  { username: 'kec.pacet',        match: 'Kecamatan Pacet',        exact: true },
  { username: 'kec.pameungpeuk',  match: 'Kecamatan Pameungpeuk',  exact: true },
  { username: 'kec.pangalengan',  match: 'Kecamatan Pangalengan',  exact: true },
  { username: 'kec.paseh',        match: 'Kecamatan Paseh',        exact: true },
  { username: 'kec.pasirjambu',   match: 'Kecamatan Pasirjambu',   exact: true },
  { username: 'kec.rancabali',    match: 'Kecamatan Rancabali',    exact: true },
  { username: 'kec.rancaekek',    match: 'Kecamatan Rancaekek',    exact: true },
  { username: 'kec.solokanjeruk', match: 'Kecamatan Solokanjeruk', exact: true },
  { username: 'kec.soreang',      match: 'Kecamatan Soreang',      exact: true },
];

async function main() {
  if (DB_PASSWORD === 'GANTI_DENGAN_DB_PASSWORD_ANDA') {
    console.error('❌ ERROR: Isi DB_PASSWORD terlebih dahulu!');
    console.error('   Supabase Dashboard → Project Settings → Database → Database Password');
    process.exit(1);
  }

  const client = new Client({
    host:     `db.${PROJECT_REF}.supabase.co`,
    port:     5432,
    database: 'postgres',
    user:     'postgres',
    password: DB_PASSWORD,
    ssl:      { rejectUnauthorized: false },
  });

  console.log('🚀 SIPELOR — Setup Akun OPD Otomatis\n');
  console.log('🔌 Menghubungkan ke database Supabase...');
  await client.connect();
  console.log('✅ Terhubung!\n');

  // ── STEP 1: Aktifkan pgcrypto ─────────────────────────────────────
  console.log('🔧 Step 1/4 — Aktifkan pgcrypto...');
  await client.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`);
  console.log('✅ pgcrypto siap\n');

  // ── STEP 2: Tambah kolom username ────────────────────────────────
  console.log('🔧 Step 2/4 — Tambah kolom username ke opd_organizations...');
  await client.query(`
    ALTER TABLE public.opd_organizations
      ADD COLUMN IF NOT EXISTS username         text,
      ADD COLUMN IF NOT EXISTS default_password text NOT NULL DEFAULT 'Sipelor@2026';
    CREATE UNIQUE INDEX IF NOT EXISTS idx_opd_organizations_username
      ON public.opd_organizations (username)
      WHERE username IS NOT NULL;
  `);
  console.log('✅ Kolom siap\n');

  // ── STEP 3: Set username tiap OPD ────────────────────────────────
  console.log('📝 Step 3/4 — Set username tiap OPD...');
  let setCount = 0;
  for (const opd of OPD_USERNAMES) {
    const whereClause = opd.exact
      ? `name = $1 AND username IS NULL`
      : `name ILIKE $1 AND username IS NULL`;
    const res = await client.query(
      `UPDATE public.opd_organizations SET username = $2 WHERE ${whereClause}`,
      [opd.match, opd.username]
    );
    if (res.rowCount > 0) setCount++;
  }
  console.log(`✅ ${setCount} OPD di-set username-nya\n`);

  // ── STEP 4: Buat akun auth.users + profiles ───────────────────────
  console.log('👤 Step 4/4 — Membuat akun login...\n');
  console.log('─'.repeat(70));

  const { rows: opdList } = await client.query(`
    SELECT id, name, username, email
    FROM   public.opd_organizations
    WHERE  username IS NOT NULL
    ORDER  BY name
  `);

  console.log(`   Total OPD: ${opdList.length}\n`);

  let created = 0, skipped = 0, failed = 0;

  for (const opd of opdList) {
    const loginEmail = (opd.email && opd.email.trim() !== '')
      ? opd.email.trim()
      : `${opd.username}@sipelor.go.id`;

    process.stdout.write(`→ ${opd.name.substring(0, 42).padEnd(42)} `);

    try {
      // Cek apakah sudah ada di auth.users
      const { rows: existing } = await client.query(
        `SELECT id FROM auth.users WHERE email = $1`,
        [loginEmail]
      );

      if (existing.length > 0) {
        // Sudah ada — pastikan profile punya username
        await client.query(`
          INSERT INTO public.profiles (id, username, email, full_name, role, created_at, updated_at)
          VALUES ($1,$2,$3,$4,'operator',now(),now())
          ON CONFLICT (id) DO UPDATE
            SET username   = EXCLUDED.username,
                updated_at = now()
          WHERE profiles.username IS NULL OR profiles.username = ''
        `, [existing[0].id, opd.username, loginEmail, opd.name]);
        console.log(`[SKIP - sudah ada]  ${loginEmail}`);
        skipped++;
        continue;
      }

      // Buat auth.users baru
      const { rows: newUser } = await client.query(`
        INSERT INTO auth.users (
          instance_id, id, aud, role, email, encrypted_password,
          email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at,
          recovery_token, recovery_sent_at,
          email_change_token_new, email_change, email_change_sent_at,
          last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
          is_super_admin, created_at, updated_at,
          phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at,
          email_change_token_current, email_change_confirm_status,
          banned_until, reauthentication_token, reauthentication_sent_at,
          is_sso_user, deleted_at, is_anonymous
        ) VALUES (
          '00000000-0000-0000-0000-000000000000',
          gen_random_uuid(),
          'authenticated', 'authenticated',
          $1, crypt($2, gen_salt('bf')),
          now(), NULL, '', NULL, '', NULL, '', '', NULL, NULL,
          '{"provider":"email","providers":["email"]}'::jsonb,
          jsonb_build_object('full_name',$3,'opd_id',$4::text,'username',$5),
          false, now(), now(),
          NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false
        ) RETURNING id
      `, [loginEmail, DEFAULT_PW, opd.name, opd.id, opd.username]);

      const newId = newUser[0].id;

      // Buat profile
      await client.query(`
        INSERT INTO public.profiles (id, username, email, full_name, role, created_at, updated_at)
        VALUES ($1,$2,$3,$4,'operator',now(),now())
        ON CONFLICT (id) DO UPDATE
          SET username   = EXCLUDED.username,
              email      = EXCLUDED.email,
              full_name  = EXCLUDED.full_name,
              role       = 'operator',
              updated_at = now()
      `, [newId, opd.username, loginEmail, opd.name]);

      console.log(`[OK]  ${loginEmail}`);
      created++;

    } catch (err) {
      console.log(`[GAGAL] ${err.message.split('\n')[0]}`);
      failed++;
    }
  }

  console.log('─'.repeat(70));
  console.log(`\n✅ Selesai!`);
  console.log(`   Dibuat  : ${created}`);
  console.log(`   Dilewati: ${skipped}  (sudah ada)`);
  console.log(`   Gagal   : ${failed}`);
  console.log(`\n📌 Cek: Supabase Dashboard → Authentication → Users`);
  console.log(`   Login Flutter → username: dispora  password: ${DEFAULT_PW}`);

  await client.end();
}

main().catch(err => {
  console.error('\n❌ Error:', err.message.split('\n')[0]);
  if (
    err.message.includes('password authentication') ||
    err.message.includes('ECONNREFUSED') ||
    err.message.includes('ENOTFOUND')
  ) {
    console.error('\n💡 Tips: Pastikan DB_PASSWORD benar.');
    console.error('   Supabase Dashboard → Project Settings → Database → Database Password');
    console.error('   Jika lupa, klik "Reset database password" di halaman tersebut.');
  }
  process.exit(1);
});
