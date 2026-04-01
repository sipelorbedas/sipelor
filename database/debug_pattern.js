/**
 * Debug: isolasi lebih dalam — apakah masalah ada di
 * email tertentu, username tertentu, atau password?
 */
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL     = "https://gbhprmibbcqfwjgrkfzq.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk";

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function tryCreate(label, opts) {
  process.stdout.write(`[${label}] → `);
  const { data, error } = await sb.auth.admin.createUser({
    email_confirm: true,
    ...opts,
  });
  if (error) {
    console.log(`❌ ${error.message}`);
    return false;
  }
  console.log(`✅ OK (${data.user.id})`);
  await sb.auth.admin.deleteUser(data.user.id).catch(() => {});
  return true;
}

async function run() {
  // Test A: email baru di bandungkab, password Sipelor@2026
  await tryCreate("email baru + Sipelor@2026", {
    email: `testonly.${Date.now()}@bandungkab.go.id`,
    password: "Sipelor@2026",
    user_metadata: { full_name: "Test Only", username: `test_${Date.now()}` },
  });

  // Test B: PERSIS bkpsdm + password beda
  await tryCreate("bkpsdm + Test@123456", {
    email: "bkpsdm@bandungkab.go.id",
    password: "Test@123456",
    user_metadata: { full_name: "Badan Kepegawaian", username: "bkpsdm" },
  });

  // Test C: PERSIS bkpsdm + Sipelor@2026 tapi tanpa user_metadata
  await tryCreate("bkpsdm + no metadata", {
    email: "bkpsdm@bandungkab.go.id",
    password: "Sipelor@2026",
  });

  // Test D: email bkpsdm tapi username lain
  await tryCreate("bkpsdm email + username lain", {
    email: "bkpsdm@bandungkab.go.id",
    password: "Sipelor@2026",
    user_metadata: { full_name: "Test", username: `rnd_${Date.now()}` },
  });

  // Test E: email lain tapi username bkpsdm
  await tryCreate("email lain + username bkpsdm", {
    email: `rnd${Date.now()}@bandungkab.go.id`,
    password: "Sipelor@2026",
    user_metadata: { full_name: "Test", username: "bkpsdm" },
  });

  // Cek apakah opd_organizations punya trigger
  console.log("\n=== Cek tabel opd_organizations ===");
  const { data: opdOrg, error: opdErr } = await sb
    .from("opd_organizations")
    .select("id, username, email, opd_name")
    .eq("username", "bkpsdm")
    .maybeSingle();
  if (opdErr) console.log("opd_organizations error:", opdErr.message);
  else console.log("opd_organizations bkpsdm:", JSON.stringify(opdOrg));
}

run().catch(e => console.error("Unexpected:", e.message));
