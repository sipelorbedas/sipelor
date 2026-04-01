/**
 * Debug isolasi: apakah masalah di trigger, domain, atau umum?
 */
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL     = "https://gbhprmibbcqfwjgrkfzq.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk";

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function test(label, email) {
  process.stdout.write(`[${label}] ${email} → `);
  const { data, error } = await sb.auth.admin.createUser({
    email, password: "Test@123456", email_confirm: true,
    user_metadata: { full_name: label, username: "test_" + Date.now() },
  });
  if (error) {
    console.log(`❌ ${error.message} (code: ${error.code})`);
    return false;
  }
  console.log(`✅ OK → id: ${data.user.id}`);
  // Hapus langsung agar bersih
  await sb.auth.admin.deleteUser(data.user.id);
  return true;
}

async function checkTriggerBody() {
  console.log("\n--- Cek isi function handle_new_user via RPC ---");
  const { data, error } = await sb.rpc("check_trigger_function");
  if (error) {
    // RPC tidak ada, skip
    console.log("  (RPC check_trigger_function tidak tersedia, skip)");
  } else {
    console.log("  Trigger body:", data);
  }
}

async function run() {
  console.log("=== ISOLASI MASALAH ===\n");

  // Test 1: email gmail biasa
  const t1 = await test("gmail biasa", `sipelor.test.${Date.now()}@gmail.com`);

  // Test 2: email bandungkab.go.id baru
  const t2 = await test("bandungkab baru", `sipelor.test.${Date.now()}@bandungkab.go.id`);

  // Test 3: email sipelor.go.id
  const t3 = await test("sipelor.go.id", `sipelor.test.${Date.now()}@sipelor.go.id`);

  console.log("\n=== KESIMPULAN ===");
  if (!t1 && !t2 && !t3) {
    console.log("❌ Semua email gagal → masalah ada di TRIGGER (handle_new_user belum ter-update)");
    console.log("   → Perlu jalankan SQL fix di Supabase SQL Editor secara manual");
    console.log("   → Atau jalankan SQL: ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_created;");
  } else if (t1 && !t2) {
    console.log("❌ Gmail OK tapi bandungkab.go.id gagal → domain restriction atau email constraint");
  } else if (t1 && t2 && t3) {
    console.log("✅ Semua email bisa dibuat! Orphaned profiles sudah bersih. Jalankan run_opd.js lagi.");
  } else {
    console.log("Hasil campuran, perlu investigasi lebih lanjut.");
  }

  // Cek apakah ada auth hooks di Supabase
  console.log("\n--- Cek trigger via SQL RPC ---");
  const { data: triggers, error: trigErr } = await sb
    .rpc("get_auth_triggers")
    .catch(() => ({ data: null, error: { message: "RPC tidak tersedia" } }));

  if (trigErr) {
    console.log("  Tidak bisa cek trigger via RPC:", trigErr.message);
    console.log("  → Pastikan di Supabase Dashboard → SQL Editor, jalankan:");
    console.log("    SELECT tgname, tgenabled FROM pg_trigger WHERE tgrelid = \\'auth.users\\'::regclass;");
  }
}

run().catch(e => {
  console.error("Unexpected:", e.message);
  process.exit(1);
});
