/**
 * ╔══════════════════════════════════════════════════════════════════╗
 * ║  SIPELOR BEDAS — Buat Akun Auth OPD / Pimpinan                 ║
 * ║  File   : database/create_opd_users.js                         ║
 * ║                                                                  ║
 * ║  CARA PAKAI:                                                     ║
 * ║    1. Pastikan Node.js sudah terinstall                          ║
 * ║    2. Di terminal/cmd, masuk ke folder database/:               ║
 * ║         cd database                                              ║
 * ║    3. Install dependency (sekali saja):                          ║
 * ║         npm install @supabase/supabase-js                        ║
 * ║    4. Isi SUPABASE_URL dan SERVICE_ROLE_KEY di bawah            ║
 * ║       (ambil dari Supabase Dashboard → Project Settings → API)  ║
 * ║    5. Jalankan:                                                  ║
 * ║         node create_opd_users.js                                 ║
 * ╚══════════════════════════════════════════════════════════════════╝
 */

// ── KONFIGURASI — isi dengan nilai dari Supabase Dashboard ─────────────
const SUPABASE_URL      = 'https://gbhprmibbcqfwjgrkfzq.supabase.co';
const SERVICE_ROLE_KEY  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk';
// ↑ Supabase Dashboard → Project Settings → API → service_role (secret)
// ⚠️  JANGAN gunakan anon key — harus service_role key!
// ⚠️  JANGAN pernah expose service_role key di frontend / commit ke git!

const DEFAULT_PASSWORD  = 'Sipelor@2026';
// ────────────────────────────────────────────────────────────────────────

const { createClient } = require('@supabase/supabase-js');

// Admin client — gunakan service_role key agar bisa createUser
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession:   false,
  },
});

async function main() {
  console.log('🚀 SIPELOR — Membuat akun OPD / Pimpinan...\n');

  // Validasi konfigurasi
  if (SERVICE_ROLE_KEY === 'GANTI_DENGAN_SERVICE_ROLE_KEY_ANDA') {
    console.error('❌ ERROR: Isi SERVICE_ROLE_KEY terlebih dahulu!');
    console.error('   Supabase Dashboard → Project Settings → API → service_role (secret)');
    console.error('   Pastikan key mengandung "role":"service_role" bukan "role":"anon"');
    process.exit(1);
  }

  // Deteksi anon key (role:"anon" di JWT payload)
  try {
    const payload = JSON.parse(Buffer.from(SERVICE_ROLE_KEY.split('.')[1], 'base64').toString());
    if (payload.role === 'anon') {
      console.error('❌ ERROR: KEY SALAH! Anda menggunakan anon key bukan service_role key!');
      console.error('');
      console.error('   Yang diisi : anon key (role: "anon")');
      console.error('   Yang dibutuhkan: service_role key (role: "service_role")');
      console.error('');
      console.error('   Cara mendapatkan service_role key:');
      console.error('   1. Buka https://supabase.com/dashboard');
      console.error('   2. Pilih project Sipelor Bedas');
      console.error('   3. Project Settings → API');
      console.error('   4. Salin "service_role" key (bagian "Project API keys")');
      console.error('   5. Tempel di baris SERVICE_ROLE_KEY pada file ini');
      process.exit(1);
    }
    if (payload.role !== 'service_role') {
      console.warn(`⚠️  PERINGATAN: Role key adalah "${payload.role}", seharusnya "service_role"`);
    } else {
      console.log('✅ service_role key terdeteksi dengan benar.\n');
    }
  } catch (_) {
    // Jika gagal decode JWT, lanjutkan saja
  }

  // Ambil semua OPD yang sudah punya username
  const { data: opdList, error: opdErr } = await supabase
    .from('opd_organizations')
    .select('id, name, username, email')
    .not('username', 'is', null)
    .order('name');

  if (opdErr) {
    console.error('❌ Gagal ambil data OPD:', opdErr.message);
    process.exit(1);
  }

  console.log(`📋 Ditemukan ${opdList.length} OPD dengan username\n`);
  console.log('─'.repeat(60));

  let created  = 0;
  let skipped  = 0;
  let failed   = 0;

  for (const opd of opdList) {
    const loginEmail = (opd.email && opd.email.trim() !== '')
      ? opd.email.trim()
      : `${opd.username}@sipelor.go.id`;

    process.stdout.write(`→ ${opd.name.padEnd(45)} `);

    // Cek apakah user sudah ada (cek via profiles dulu)
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id, username')
      .eq('email', loginEmail)
      .maybeSingle();

    if (existingProfile) {
      // User sudah ada — pastikan username ter-set di profiles
      if (!existingProfile.username) {
        await supabase
          .from('profiles')
          .update({ username: opd.username, updated_at: new Date().toISOString() })
          .eq('id', existingProfile.id);
        console.log(`[SKIP, patch username] ${loginEmail}`);
      } else {
        console.log(`[SKIP, sudah ada]      ${loginEmail}`);
      }
      skipped++;
      continue;
    }

    // Buat user baru via Supabase Admin API
    const { data: newUser, error: createErr } = await supabase.auth.admin.createUser({
      email:             loginEmail,
      password:          DEFAULT_PASSWORD,
      email_confirm:     true,          // langsung confirmed, tidak perlu verifikasi
      user_metadata: {
        full_name: opd.name,
        opd_id:    opd.id,
        username:  opd.username,
      },
    });

    if (createErr) {
      console.log(`[GAGAL] ${createErr.message}`);
      failed++;
      continue;
    }

    // Insert / update profile
    const { error: profErr } = await supabase
      .from('profiles')
      .upsert({
        id:         newUser.user.id,
        username:   opd.username,
        email:      loginEmail,
        full_name:  opd.name,
        role:       'operator',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }, { onConflict: 'id' });

    if (profErr) {
      console.log(`[Auth OK, profile gagal] ${profErr.message}`);
      // Auth user berhasil dibuat meski profile gagal
      created++;
    } else {
      console.log(`[OK] ${loginEmail}`);
      created++;
    }
  }

  console.log('─'.repeat(60));
  console.log(`\n✅ Selesai!`);
  console.log(`   Dibuat  : ${created}`);
  console.log(`   Dilewati: ${skipped}`);
  console.log(`   Gagal   : ${failed}`);
  console.log('\n📌 Verifikasi di Supabase Dashboard → Authentication → Users');
  console.log(`   Password default semua akun: ${DEFAULT_PASSWORD}`);

  // Patch profiles yang username-nya masih null (untuk akun lama)
  if (skipped > 0) {
    console.log('\n🔧 Patching profiles lama yang username-nya null...');
    for (const opd of opdList) {
      const loginEmail = (opd.email && opd.email.trim() !== '')
        ? opd.email.trim()
        : `${opd.username}@sipelor.go.id`;

      const { data: prof } = await supabase
        .from('profiles')
        .select('id, username')
        .eq('email', loginEmail)
        .maybeSingle();

      if (prof && !prof.username) {
        await supabase
          .from('profiles')
          .update({ username: opd.username, updated_at: new Date().toISOString() })
          .eq('id', prof.id);
        console.log(`   Patched: ${opd.username} → ${loginEmail}`);
      }
    }
    console.log('   Patch selesai.');
  }
}

main().catch(err => {
  console.error('❌ Unexpected error:', err);
  process.exit(1);
});
