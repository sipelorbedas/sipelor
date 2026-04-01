# ============================================================
# Build Script - SIPELOR BEDAS Admin Panel (Windows PowerShell)
# ============================================================
# Mengemas website/admin/ menjadi paket siap deploy di dist/admin/
# Jalankan dari root project:
#   .\scripts\build_admin.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$ROOT      = Split-Path -Parent $PSScriptRoot
$SRC       = Join-Path $ROOT "website\admin"
$DIST      = Join-Path $ROOT "dist\admin"
$ZIP_DIR   = Join-Path $ROOT "dist"
$CONFIG    = Join-Path $SRC "js\config.js"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$ZIP_NAME  = "sipelor-admin-$TIMESTAMP.zip"
$ZIP_PATH  = Join-Path $ZIP_DIR $ZIP_NAME

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SIPELOR BEDAS - Admin Panel Build"        -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verifikasi source folder
if (-not (Test-Path $SRC)) {
    Write-Host "ERROR: Folder website/admin/ tidak ditemukan!" -ForegroundColor Red
    exit 1
}

# 2. Baca konfigurasi
Write-Host "Memeriksa konfigurasi Supabase..." -ForegroundColor Yellow

$configLines = Get-Content $CONFIG

# Cek DEMO_MODE
$demoLine = $configLines | Where-Object { $_ -match "DEMO_MODE" }
$IS_DEMO = $false
if ($demoLine -match "true") {
    $IS_DEMO = $true
    Write-Host "  PERINGATAN: DEMO_MODE aktif - build ini menggunakan data palsu." -ForegroundColor Yellow
    Write-Host "  Ubah ke false di website/admin/js/config.js untuk produksi." -ForegroundColor Yellow
}

# Ekstrak Supabase URL
$SUPABASE_URL = "(tidak ditemukan)"
foreach ($line in $configLines) {
    if ($line -match "SUPABASE_URL") {
        $parts = $line -split "'"
        if ($parts.Count -ge 2) {
            $SUPABASE_URL = $parts[1]
        }
        break
    }
}

if ($SUPABASE_URL -eq "YOUR_SUPABASE_URL" -or $SUPABASE_URL -eq "(tidak ditemukan)" -or $SUPABASE_URL -eq "") {
    Write-Host "  ERROR: SUPABASE_URL belum diisi di js/config.js!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  Supabase URL : $SUPABASE_URL" -ForegroundColor Green
Write-Host "  Anon Key     : ******* (tersembunyi)" -ForegroundColor Green
$demoColor = if ($IS_DEMO) { "Yellow" } else { "Green" }
Write-Host "  Demo Mode    : $IS_DEMO" -ForegroundColor $demoColor
Write-Host ""

# 3. Matikan proses yang memakai dist\admin (e.g. python http.server)
Write-Host "Memeriksa proses yang menggunakan dist\admin..." -ForegroundColor Yellow
$killed = $false
Get-Process -Name "python","python3","node","http-server" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Menghentikan proses: $($_.Name) (PID $($_.Id))" -ForegroundColor DarkYellow
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    $killed = $true
}
if ($killed) {
    Start-Sleep -Seconds 1
    Write-Host "  Proses dihentikan." -ForegroundColor Gray
} else {
    Write-Host "  Tidak ada proses aktif." -ForegroundColor Gray
}

# 4. Bersihkan output lama
Write-Host "Membersihkan output lama..." -ForegroundColor Yellow
if (Test-Path $DIST) {
    Remove-Item -Recurse -Force $DIST
}
New-Item -ItemType Directory -Force -Path $DIST | Out-Null
New-Item -ItemType Directory -Force -Path $ZIP_DIR | Out-Null
Write-Host "  dist/admin/ siap." -ForegroundColor Gray

# 5. Copy semua file admin
Write-Host "Menyalin file admin..." -ForegroundColor Yellow
Copy-Item -Path "$SRC\*" -Destination $DIST -Recurse -Force

# Copy launcher script jika ada
$LAUNCHER_SRC = Join-Path $ROOT "dist\admin\Buka Admin.bat"
if (Test-Path $LAUNCHER_SRC) {
    # Already in dist/admin — no extra copy needed
}
$fileCount = (Get-ChildItem -Recurse -File $DIST).Count
Write-Host "  Total file disalin: $fileCount" -ForegroundColor Gray

# 6. Buat BUILD_INFO.txt
$buildDate = Get-Date -Format "dd MMMM yyyy HH:mm:ss"
$buildInfoPath = Join-Path $DIST "BUILD_INFO.txt"
$buildInfoContent = @(
    "SIPELOR BEDAS - Admin Panel",
    "============================",
    "Build Time  : $buildDate",
    "Source      : website/admin/",
    "Supabase URL: $SUPABASE_URL",
    "Demo Mode   : $IS_DEMO",
    "",
    "CARA DEPLOY:",
    "1. Upload seluruh isi folder ini ke web server / hosting",
    "2. Arahkan domain ke file index.html (entry point)",
    "3. Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY sudah benar di js/config.js",
    "4. Aktifkan RLS di semua tabel Supabase",
    "",
    "HOSTING YANG DIREKOMENDASIKAN:",
    "- Netlify  : drag-and-drop folder ke netlify.com/drop",
    "- Vercel   : vercel deploy --prod (di folder dist/admin)",
    "- cPanel   : upload ZIP ke File Manager, extract di public_html/admin",
    "- Nginx    : copy folder ke /var/www/html/admin",
    "",
    "CATATAN KEAMANAN:",
    "- anon key aman diekspos di browser (dilindungi RLS Supabase)",
    "- Jangan pernah masukkan service_role key di frontend",
    "- Pastikan RLS aktif di tabel: profiles, bookings, fields, payments"
)
$buildInfoContent | Out-File -FilePath $buildInfoPath -Encoding UTF8
Write-Host "  BUILD_INFO.txt dibuat." -ForegroundColor Gray

# 7. Buat ZIP
Write-Host "Membuat file ZIP..." -ForegroundColor Yellow
Compress-Archive -Path "$DIST\*" -DestinationPath $ZIP_PATH -Force
$zipSizeKB = [math]::Round((Get-Item $ZIP_PATH).Length / 1KB, 1)
Write-Host "  ZIP: dist\$ZIP_NAME ($zipSizeKB KB)" -ForegroundColor Gray

# 8. Ringkasan
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  BUILD SELESAI!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output:" -ForegroundColor White
Write-Host "  Folder : dist\admin\" -ForegroundColor Cyan
Write-Host "  ZIP    : dist\$ZIP_NAME" -ForegroundColor Cyan
Write-Host ""
Write-Host "Langkah Deploy:" -ForegroundColor White
Write-Host "  [Netlify]  Drag-drop folder dist\admin ke netlify.com/drop"
Write-Host "  [Vercel]   cd dist\admin && vercel --prod"
Write-Host "  [cPanel]   Upload ZIP ke File Manager, extract di public_html/admin"
Write-Host "  [Lokal]    Buka dist\admin\login.html di browser"
Write-Host ""
Write-Host "Login Admin:"
Write-Host "  URL  : [hosting-url]/login.html"
Write-Host "  Role : admin, superadmin, manager, operator"
Write-Host ""
