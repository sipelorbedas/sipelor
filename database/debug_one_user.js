/**
 * Debug: Coba buat 1 user dan tampilkan FULL error object
 */
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL     = "https://gbhprmibbcqfwjgrkfzq.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk";

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function debug() {
  console.log("=== DEBUG: Coba buat 1 user test ===\n");

  // 1. Cek koneksi + list user pertama
  const list = await sb.auth.admin.listUsers({ perPage: 1 });
  if (list.error) {
    console.error("❌ Koneksi gagal:", list.error);
    process.exit(1);
  }
  console.log("✅ Koneksi OK. Total users:", list.data?.total_count ?? "?");

  // 2. Coba buat user test
  console.log("\n--- Mencoba buat akun: bkpsdm@bandungkab.go.id ---");
  const { data, error } = await sb.auth.admin.createUser({
    email:         "bkpsdm@bandungkab.go.id",
    password:      "Sipelor@2026",
    email_confirm: true,
    user_metadata: { full_name: "Badan Kepegawaian dan Pengembangan SDM", username: "bkpsdm" },
  });

  if (error) {
    console.error("\n❌ ERROR LENGKAP:");
    console.error("  message :", error.message);
    console.error("  status  :", error.status);
    console.error("  code    :", error.code);
    console.error("  details :", error.details);
    console.error("  hint    :", error.hint);
    console.error("  full obj:", JSON.stringify(error, null, 2));
  } else {
    console.log("\n✅ BERHASIL! User ID:", data.user.id);
    console.log("   Email:", data.user.email);
  }

  // 3. Cek apakah email sudah ada di auth.users via profiles
  console.log("\n--- Cek profiles untuk email ini ---");
  const { data: prof, error: profErr } = await sb
    .from("profiles")
    .select("id, username, email, role")
    .eq("email", "bkpsdm@bandungkab.go.id")
    .maybeSingle();

  if (profErr) console.error("  profiles error:", profErr.message);
  else if (prof) console.log("  Profile ditemukan:", JSON.stringify(prof, null, 2));
  else console.log("  Tidak ada profile untuk email ini.");
}

debug().catch(e => {
  console.error("Unexpected:", e.message);
  process.exit(1);
});
