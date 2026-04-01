/**
 * Debug: Cek auth users yang sudah ada dengan email bandungkab.go.id
 * dan cari tahu kenapa createUser gagal
 */
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL     = "https://gbhprmibbcqfwjgrkfzq.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk";

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function debug() {
  console.log("=== Cek existing auth users bandungkab.go.id ===\n");

  // List semua users, ambil per halaman
  let page = 1;
  let allUsers = [];
  while (true) {
    const { data, error } = await sb.auth.admin.listUsers({ page, perPage: 100 });
    if (error) { console.error("listUsers error:", error.message); break; }
    allUsers = allUsers.concat(data.users);
    if (data.users.length < 100) break;
    page++;
  }

  const opdUsers = allUsers.filter(u =>
    u.email && (u.email.includes("bandungkab.go.id") || u.email.includes("sipelor.go.id"))
  );

  console.log(`Total semua user : ${allUsers.length}`);
  console.log(`User OPD (bandungkab/sipelor): ${opdUsers.length}`);

  if (opdUsers.length > 0) {
    console.log("\n--- Daftar user OPD yang sudah ada di auth.users ---");
    opdUsers.forEach(u => {
      console.log(`  ID: ${u.id}`);
      console.log(`  Email: ${u.email}`);
      console.log(`  Created: ${u.created_at}`);
      console.log(`  Email confirmed: ${u.email_confirmed_at ? 'YES' : 'NO'}`);
      console.log(`  Identities: ${u.identities?.length ?? 0}`);
      console.log(`  ---`);
    });
  } else {
    console.log("\n⚠ Tidak ada user OPD di auth.users → createUser harusnya bisa!");
    console.log("  Kemungkinan masalah ada di trigger atau constraint lain.");
  }

  // Cek profile yang masih ada
  console.log("\n--- Profiles OPD yang ada di public.profiles ---");
  const { data: profiles, error: profErr } = await sb
    .from("profiles")
    .select("id, username, email, role")
    .or("email.like.%bandungkab.go.id,email.like.%sipelor.go.id")
    .order("email");

  if (profErr) console.error("profiles error:", profErr.message);
  else {
    console.log(`Total profiles OPD: ${profiles.length}`);
    profiles.forEach(p => {
      const hasAuthUser = opdUsers.some(u => u.id === p.id);
      console.log(`  ${p.email.padEnd(45)} | username: ${(p.username||'').padEnd(20)} | auth: ${hasAuthUser ? '✅' : '❌ ORPHANED'}`);
    });
  }
}

debug().catch(e => {
  console.error("Unexpected:", e.message);
  process.exit(1);
});
