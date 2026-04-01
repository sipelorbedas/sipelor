#!/bin/bash
# ============================================================
# Build Script — SIPELOR BEDAS Admin Panel (Linux/Mac)
# ============================================================
# Mengemas website/admin/ menjadi paket siap deploy di dist/admin/
# Jalankan dari root project:
#   bash scripts/build_admin.sh
# ============================================================

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/website/admin"
DIST="$ROOT/dist/admin"
ZIP_DIR="$ROOT/dist"
CONFIG="$SRC/js/config.js"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ZIP_NAME="sipelor-admin-$TIMESTAMP.zip"
ZIP_PATH="$ZIP_DIR/$ZIP_NAME"

echo ""
echo "============================================"
echo "  SIPELOR BEDAS — Admin Panel Build"
echo "============================================"
echo ""

# ── 1. Verifikasi source folder ──────────────────────────────
if [ ! -d "$SRC" ]; then
    echo "❌ ERROR: Folder website/admin/ tidak ditemukan!"
    exit 1
fi

# ── 2. Cek konfigurasi ───────────────────────────────────────
echo "🔍 Memeriksa konfigurasi Supabase..."

if grep -q "DEMO_MODE.*true" "$CONFIG"; then
    echo "⚠️  DEMO_MODE aktif — build ini menggunakan data palsu."
    echo "   Ubah ke 'false' di website/admin/js/config.js untuk produksi."
    IS_DEMO=true
else
    IS_DEMO=false
fi

SUPABASE_URL=$(grep -oP "SUPABASE_URL\s*:\s*'\K[^']+" "$CONFIG" || echo "(tidak ditemukan)")

if [ "$SUPABASE_URL" = "YOUR_SUPABASE_URL" ] || [ "$SUPABASE_URL" = "(tidak ditemukan)" ]; then
    echo "❌ ERROR: SUPABASE_URL belum diisi di js/config.js!"
    exit 1
fi

echo ""
echo "  ✅ Supabase URL : $SUPABASE_URL"
echo "  ✅ Anon Key     : ******* (tersembunyi)"
echo "  $([ "$IS_DEMO" = true ] && echo '⚠️' || echo '✅') Demo Mode    : $IS_DEMO"
echo ""

# ── 3. Bersihkan & siapkan output ───────────────────────────
echo "🧹 Membersihkan output lama..."
rm -rf "$DIST"
mkdir -p "$DIST"
mkdir -p "$ZIP_DIR"
echo "  dist/admin/ siap."

# ── 4. Copy file admin ───────────────────────────────────────
echo "📁 Menyalin file admin..."
cp -r "$SRC/." "$DIST/"
FILE_COUNT=$(find "$DIST" -type f | wc -l | tr -d ' ')
echo "  Total file: $FILE_COUNT"

# ── 5. Buat BUILD_INFO.txt ───────────────────────────────────
cat > "$DIST/BUILD_INFO.txt" << EOF
SIPELOR BEDAS — Admin Panel
============================
Build Time  : $(date "+%d %B %Y %H:%M:%S")
Source      : website/admin/
Supabase URL: $SUPABASE_URL
Demo Mode   : $IS_DEMO

CARA DEPLOY:
1. Upload seluruh isi folder ini ke web server / hosting
2. Arahkan domain ke file index.html (entry point)
3. Pastikan SUPABASE_URL & SUPABASE_ANON_KEY sudah benar di js/config.js
4. Aktifkan RLS di semua tabel Supabase

HOSTING YANG DIREKOMENDASIKAN:
- Netlify   : drag-and-drop folder ke netlify.com/drop
- Vercel    : vercel deploy --prod (di folder dist/admin)
- cPanel    : upload ZIP ke File Manager, extract di public_html/admin
- Nginx     : copy folder ke /var/www/html/admin

CATATAN KEAMANAN:
- anon key aman diekspos di browser (dilindungi RLS Supabase)
- Jangan pernah masukkan service_role key di frontend
- Pastikan RLS aktif di tabel: profiles, bookings, fields, payments
EOF

# ── 6. Buat ZIP ──────────────────────────────────────────────
echo "📦 Membuat file ZIP..."
(cd "$DIST" && zip -r "$ZIP_PATH" . -x "*.DS_Store" -x "__MACOSX/*" > /dev/null)
ZIP_SIZE=$(du -sh "$ZIP_PATH" | cut -f1)
echo "  ZIP dibuat: dist/$ZIP_NAME ($ZIP_SIZE)"

# ── 7. Ringkasan ─────────────────────────────────────────────
echo ""
echo "============================================"
echo "  ✅ BUILD SELESAI!"
echo "============================================"
echo ""
echo "Output:"
echo "  Folder : dist/admin/"
echo "  ZIP    : dist/$ZIP_NAME"
echo ""
echo "Langkah Deploy:"
echo "  [Netlify]   Drag-drop folder dist/admin ke netlify.com/drop"
echo "  [Vercel]    cd dist/admin && vercel --prod"
echo "  [cPanel]    Upload ZIP ke File Manager, extract di public_html/admin"
echo "  [Lokal]     Buka dist/admin/login.html di browser"
echo ""
echo "Login Admin:"
echo "  URL   : [hosting-url]/login.html"
echo "  Role  : admin, superadmin, manager, operator"
echo ""
