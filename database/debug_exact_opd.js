/**
 * Debug: coba buat PERSIS bkpsdm@bandungkab.go.id dan cek semua profiles
 */
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL     = "https://gbhprmibbcqfwjgrkfzq.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk";

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function run() {
  // 1. Cek semua profiles
  console.log("=== Semua profiles yang ada sekarang ===");
  const { data: allProf } = await sb.from("profiles").select("id, username, email, role").order("email");
  console.log(`Total: ${allProf?.length ?? 0}`);
  (allProf || []).forEach(p => console.log(`  ${p.email?.padEnd(45)} | ${p.username}`));

  // 2. Cek username conflicts
  console.log("\n=== Cek username 'bkpsdm' ===");
  const { data: conflict } = await sb.from("profiles").select("*").eq("username", "bkpsdm");
  console.log(`Profiles dengan username 'bkpsdm': ${conflict?.length ?? 0}`);
  (conflict || []).forEach(p => console.log(" ", JSON.stringify(p)));

  // 3. Test buat PERSIS bkpsdm@bandungkab.go.id
  console.log("\n=== Test buat bkpsdm@bandungkab.go.id ===");
  const { data, error } = await sb.auth.admin.createUser({
    email:         "bkpsdm@bandungkab.go.id",
    password:      "Sipelor@2026",
    email_confirm: true,
    user_metadata: { full_name: "Badan Kepegawaian dan Pengembangan SDM", username: "bkpsdm" },
  });

  if (error) {
    console.log("❌ GAGAL:", error.message, `(${error.code})`);

    // 4. Cek profiles setelah gagal (mungkin trigger sempat nulis)
    console.log("\n=== Profiles setelah gagal ===");
    const { data: afterProf } = await sb.from("profiles").select("id, username, email").order("email");
    console.log(`Total: ${afterProf?.length ?? 0}`);
    (afterProf || []).forEach(p => console.log(`  ${p.email?.padEnd(45)} | ${p.username}`));
  } else {
    console.log("✅ BERHASIL! ID:", data.user.id);

    // Hapus user test ini
    await sb.auth.admin.deleteUser(data.user.id);
    console.log("✅ User test dihapus.");
  }
}

run().catch(e => console.error("Unexpected:", e.message));
