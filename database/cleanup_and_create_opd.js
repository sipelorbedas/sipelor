/**
 * ╔══════════════════════════════════════════════════════════════════════╗
 * ║  SIPELOR BEDAS — Cleanup Orphaned Profiles + Buat Akun OPD         ║
 * ║                                                                      ║
 * ║  STEP 1: Hapus 61 orphaned profiles (email ada di profiles          ║
 * ║          tapi tidak punya auth.user → blokir createUser)            ║
 * ║  STEP 2: Buat 61 akun OPD via Admin API                             ║
 * ╚══════════════════════════════════════════════════════════════════════╝
 */

const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL     = "https://gbhprmibbcqfwjgrkfzq.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODkwODA1NywiZXhwIjoyMDg0NDg0MDU3fQ.fX7iMk2pejs1ChSEKHk3OFs2nq2q0kbXrLL1dZMKCRk";
const PW = "Sipelor@2026";

const OPD = [
  ["bkpsdm",       "Badan Kepegawaian dan Pengembangan SDM",          "bkpsdm@bandungkab.go.id"],
  ["bakesbangpol", "Badan Kesatuan Bangsa dan Politik",                "bakesbangpol@bandungkab.go.id"],
  ["bkad",         "Badan Keuangan dan Aset Daerah",                   "bkad@bandungkab.go.id"],
  ["bapenda",      "Badan Pendapatan Daerah",                          "bapenda@bandungkab.go.id"],
  ["bapperida",    "Badan Perencanaan Pembangunan Riset Inovasi",      "bapperida@bandungkab.go.id"],
  ["bpbd",         "Badan Penanggulangan Bencana Daerah",              "bpbd@bandungkab.go.id"],
  ["disbud",       "Dinas Kebudayaan",                                 "disbud@bandungkab.go.id"],
  ["disdukcapil",  "Dinas Kependudukan dan Pencatatan Sipil",          "disdukcapil@bandungkab.go.id"],
  ["diskpp",       "Dinas Ketahanan Pangan dan Perikanan",             "diskpp@bandungkab.go.id"],
  ["disnaker",     "Dinas Ketenagakerjaan",                            "disnaker@bandungkab.go.id"],
  ["diskominfo",   "Dinas Komunikasi dan Informatika",                 "diskominfo@bandungkab.go.id"],
  ["diskopukm",    "Dinas Koperasi dan Usaha Kecil Menengah",          "diskopukm@bandungkab.go.id"],
  ["dlh",          "Dinas Lingkungan Hidup",                           "dlh@bandungkab.go.id"],
  ["disparekraf",  "Dinas Pariwisata dan Ekonomi Kreatif",             "disparekraf@bandungkab.go.id"],
  ["dpupr",        "Dinas Pekerjaan Umum dan Tata Ruang",              "dpupr@bandungkab.go.id"],
  ["dpkp",         "Dinas Pemadam Kebakaran",                          "dpkp@bandungkab.go.id"],
  ["dpmd",         "Dinas Pemberdayaan Masyarakat dan Desa",           "dpmd@bandungkab.go.id"],
  ["dispora",      "Dinas Pemuda dan Olahraga",                        "dispora@bandungkab.go.id"],
  ["dpmptsp",      "Dinas Penanaman Modal dan Pelayanan Terpadu",      "dpmptsp@bandungkab.go.id"],
  ["disdik",       "Dinas Pendidikan",                                 "disdik@bandungkab.go.id"],
  ["dp2kbp3a",     "Dinas Pengendalian Penduduk dan KB",               "dp2kbp3a@bandungkab.go.id"],
  ["dishub",       "Dinas Perhubungan",                                "dishub@bandungkab.go.id"],
  ["dispusip",     "Dinas Perpustakaan dan Arsip",                     "dispusip@bandungkab.go.id"],
  ["distani",      "Dinas Pertanian",                                  "distani@bandungkab.go.id"],
  ["dpkpp",        "Dinas Perumahan dan Kawasan Permukiman",           "dpkpp@bandungkab.go.id"],
  ["dinsos",       "Dinas Sosial",                                     "dinsos@bandungkab.go.id"],
  ["dinkes",       "Dinas Kesehatan",                                  "dinkes@bandungkab.go.id"],
  ["disdagin",     "Dinas Perdagangan dan Perindustrian",              "disdagin@bandungkab.go.id"],
  ["satpolpp",     "Satuan Polisi Pamong Praja",                       "satpolpp@bandungkab.go.id"],
  ["dprd",         "Sekretariat DPRD",                                 "dprd@bandungkab.go.id"],
  ["kec.arjasari",    "Kecamatan Arjasari",    "kec.arjasari@bandungkab.go.id"],
  ["kec.baleendah",   "Kecamatan Baleendah",   "kec.baleendah@bandungkab.go.id"],
  ["kec.banjaran",    "Kecamatan Banjaran",    "kec.banjaran@bandungkab.go.id"],
  ["kec.bojongsoang", "Kecamatan Bojongsoang", "kec.bojongsoang@bandungkab.go.id"],
  ["kec.cangkuang",   "Kecamatan Cangkuang",   "kec.cangkuang@bandungkab.go.id"],
  ["kec.cicalengka",  "Kecamatan Cicalengka",  "kec.cicalengka@bandungkab.go.id"],
  ["kec.cikancung",   "Kecamatan Cikancung",   "kec.cikancung@bandungkab.go.id"],
  ["kec.cilengkrang", "Kecamatan Cilengkrang", "kec.cilengkrang@bandungkab.go.id"],
  ["kec.cileunyi",    "Kecamatan Cileunyi",    "kec.cileunyi@bandungkab.go.id"],
  ["kec.cimaung",     "Kecamatan Cimaung",     "kec.cimaung@bandungkab.go.id"],
  ["kec.cimenyan",    "Kecamatan Cimenyan",    "kec.cimenyan@bandungkab.go.id"],
  ["kec.ciparay",     "Kecamatan Ciparay",     "kec.ciparay@bandungkab.go.id"],
  ["kec.ciwidey",     "Kecamatan Ciwidey",     "kec.ciwidey@bandungkab.go.id"],
  ["kec.dayeuhkolot", "Kecamatan Dayeuhkolot", "kec.dayeuhkolot@bandungkab.go.id"],
  ["kec.ibun",        "Kecamatan Ibun",        "kec.ibun@bandungkab.go.id"],
  ["kec.katapang",    "Kecamatan Katapang",    "kec.katapang@bandungkab.go.id"],
  ["kec.kertasari",   "Kecamatan Kertasari",   "kec.kertasari@bandungkab.go.id"],
  ["kec.kutawaringin","Kecamatan Kutawaringin","kec.kutawaringin@bandungkab.go.id"],
  ["kec.majalaya",    "Kecamatan Majalaya",    "kec.majalaya@bandungkab.go.id"],
  ["kec.margaasih",   "Kecamatan Margaasih",   "kec.margaasih@bandungkab.go.id"],
  ["kec.margahayu",   "Kecamatan Margahayu",   "kec.margahayu@bandungkab.go.id"],
  ["kec.nagreg",      "Kecamatan Nagreg",      "kec.nagreg@bandungkab.go.id"],
  ["kec.pacet",       "Kecamatan Pacet",       "kec.pacet@bandungkab.go.id"],
  ["kec.pameungpeuk", "Kecamatan Pameungpeuk", "kec.pameungpeuk@bandungkab.go.id"],
  ["kec.pangalengan", "Kecamatan Pangalengan", "kec.pangalengan@bandungkab.go.id"],
  ["kec.paseh",       "Kecamatan Paseh",       "kec.paseh@bandungkab.go.id"],
  ["kec.pasirjambu",  "Kecamatan Pasirjambu",  "kec.pasirjambu@bandungkab.go.id"],
  ["kec.rancabali",   "Kecamatan Rancabali",   "kec.rancabali@bandungkab.go.id"],
  ["kec.rancaekek",   "Kecamatan Rancaekek",   "kec.rancaekek@bandungkab.go.id"],
  ["kec.solokanjeruk","Kecamatan Solokanjeruk","kec.solokanjeruk@bandungkab.go.id"],
  ["kec.soreang",     "Kecamatan Soreang",     "kec.soreang@bandungkab.go.id"],
];

const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function run() {
  // ── STEP 1: Ambil daftar auth.users yang sudah ada ──────────────────
  console.log("══════════════════════════════════════════════════════════════════════");
  console.log("STEP 1 — Ambil daftar auth.users yang sudah ada");
  console.log("══════════════════════════════════════════════════════════════════════");

  let allAuthUsers = [];
  let page = 1;
  while (true) {
    const { data, error } = await sb.auth.admin.listUsers({ page, perPage: 100 });
    if (error) { console.error("❌ listUsers error:", error.message); process.exit(1); }
    allAuthUsers = allAuthUsers.concat(data.users);
    if (data.users.length < 100) break;
    page++;
  }
  const authEmailSet = new Set(allAuthUsers.map(u => u.email?.toLowerCase()));
  console.log(`✅ Total auth.users: ${allAuthUsers.length}`);

  // ── STEP 2: Hapus orphaned profiles (email ada, auth.user tidak ada) ─
  console.log("\n══════════════════════════════════════════════════════════════════════");
  console.log("STEP 2 — Hapus orphaned profiles OPD (blokir email UNIQUE)");
  console.log("══════════════════════════════════════════════════════════════════════");

  const opdEmails = OPD.map(([,, email]) => email.toLowerCase());
  const orphanedEmails = opdEmails.filter(email => !authEmailSet.has(email));

  console.log(`→ ${orphanedEmails.length} profiles akan dihapus...`);

  if (orphanedEmails.length > 0) {
    // Hapus satu per satu agar RLS tidak memblokir
    let deleted = 0;
    for (const email of orphanedEmails) {
      const { error: delErr } = await sb
        .from("profiles")
        .delete()
        .eq("email", email);
      if (delErr) {
        console.error(`  ❌ Gagal hapus ${email}: ${delErr.message}`);
      } else {
        deleted++;
      }
    }
    console.log(`✅ ${deleted} orphaned profiles berhasil dihapus.`);
  } else {
    console.log("✅ Tidak ada orphaned profiles — lanjut ke STEP 3.");
  }

  // ── STEP 3: Buat akun OPD ────────────────────────────────────────────
  console.log("\n══════════════════════════════════════════════════════════════════════");
  console.log(`STEP 3 — Buat ${OPD.length} akun OPD / Pimpinan`);
  console.log("══════════════════════════════════════════════════════════════════════");

  let ok = 0, skip = 0, fail = 0;

  for (const [uname, name, email] of OPD) {
    process.stdout.write(`→ ${uname.padEnd(20)} ${email.padEnd(42)} `);

    // Cek apakah sudah ada di auth.users
    if (authEmailSet.has(email.toLowerCase())) {
      // Pastikan profile username ter-set
      const existUser = allAuthUsers.find(u => u.email?.toLowerCase() === email.toLowerCase());
      if (existUser) {
        const { data: prof } = await sb
          .from("profiles").select("id, username").eq("id", existUser.id).maybeSingle();
        if (prof && !prof.username) {
          await sb.from("profiles")
            .update({ username: uname, updated_at: new Date().toISOString() })
            .eq("id", existUser.id);
          console.log("[SKIP, patch username]");
        } else {
          console.log("[SKIP - sudah ada]");
        }
      } else {
        console.log("[SKIP - sudah ada]");
      }
      skip++;
      continue;
    }

    // Buat user baru
    const { data, error } = await sb.auth.admin.createUser({
      email,
      password:      PW,
      email_confirm: true,
      user_metadata: { full_name: name, username: uname },
    });

    if (error) {
      if (error.message.toLowerCase().includes("already") ||
          error.message.toLowerCase().includes("registered")) {
        console.log("[SKIP - sudah ada]");
        skip++;
      } else {
        console.log(`[GAGAL] ${error.message}`);
        fail++;
      }
      continue;
    }

    // Upsert profile
    const { error: profErr } = await sb.from("profiles").upsert({
      id:         data.user.id,
      username:   uname,
      email,
      full_name:  name,
      role:       "operator",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, { onConflict: "id" });

    if (profErr) {
      console.log(`[Auth ✅ ⚠ Profile: ${profErr.message}]`);
    } else {
      console.log("[OK] ✅");
    }
    ok++;
    // Tambahkan ke set agar tidak dobel
    authEmailSet.add(email.toLowerCase());
  }

  console.log("══════════════════════════════════════════════════════════════════════");
  console.log(`\n📊 HASIL:`);
  console.log(`   ✅ Dibuat   : ${ok}`);
  console.log(`   ⏭  Dilewati : ${skip}`);
  console.log(`   ❌ Gagal    : ${fail}`);
  console.log(`\n🔑 Password semua akun: ${PW}`);
  console.log(`📌 Cek di Supabase Dashboard → Authentication → Users`);
}

run().catch(e => {
  console.error("❌ Unexpected error:", e.message);
  process.exit(1);
});
