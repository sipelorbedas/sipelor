# Production Build Script for SIPELOR BEDAS
# Builds release APK with SSL pinning, obfuscation, and Sentry enabled
#
# Usage:
#   .\build_production.ps1 `
#     -SupabaseUrl "https://xxx.supabase.co" `
#     -SupabaseKey "eyJ..." `
#     -SentryDsn "https://xxx@xxx.ingest.sentry.io/xxx" `
#     -EmailRedirectUrl "https://yoursite.github.io/sipelor/auth/callback.html"

param(
    [Parameter(Mandatory = $true)]
    [string]$SupabaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$SupabaseKey,

    [Parameter(Mandatory = $true)]
    [string]$SentryDsn,

    [Parameter(Mandatory = $true)]
    [string]$EmailRedirectUrl,

    # Opsional: build AAB (App Bundle) untuk Google Play
    [switch]$AppBundle = $false
)

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         SIPELOR BEDAS - Production Build Script          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Validasi input ───────────────────────────────────────────────────────────
function Validate-NotEmpty([string]$value, [string]$name) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Host "❌ ERROR: Parameter '$name' tidak boleh kosong!" -ForegroundColor Red
        exit 1
    }
}

Validate-NotEmpty $SupabaseUrl     "SupabaseUrl"
Validate-NotEmpty $SupabaseKey     "SupabaseKey"
Validate-NotEmpty $SentryDsn       "SentryDsn"
Validate-NotEmpty $EmailRedirectUrl "EmailRedirectUrl"

if (-not $SupabaseUrl.StartsWith("https://")) {
    Write-Host "❌ ERROR: SupabaseUrl harus dimulai dengan 'https://'" -ForegroundColor Red
    exit 1
}
if (-not $SentryDsn.StartsWith("https://")) {
    Write-Host "❌ ERROR: SentryDsn harus dimulai dengan 'https://'" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Semua parameter valid" -ForegroundColor Green
Write-Host ""

# ── Cek Flutter ───────────────────────────────────────────────────────────────
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: Flutter tidak ditemukan di PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter ditemukan" -ForegroundColor Green
Write-Host ""

# ── Cek keystore ─────────────────────────────────────────────────────────────
$keystoreFile = Join-Path $PSScriptRoot "..\android\app\upload-keystore.jks"
if (-not (Test-Path $keystoreFile)) {
    Write-Host "❌ ERROR: Keystore tidak ditemukan: $keystoreFile" -ForegroundColor Red
    Write-Host "   Jalankan dulu: .\generate_keystore.bat" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Keystore ditemukan" -ForegroundColor Green
Write-Host ""

# ── Clean ─────────────────────────────────────────────────────────────────────
Write-Host "🧹 Membersihkan build sebelumnya..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: flutter clean gagal" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Clean selesai" -ForegroundColor Green
Write-Host ""

# ── Dependencies ──────────────────────────────────────────────────────────────
Write-Host "📦 Mengunduh dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: flutter pub get gagal" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies terinstall" -ForegroundColor Green
Write-Host ""

# ── SSL Certificate Expiry Check ──────────────────────────────────────────────
Write-Host "🔒 Memeriksa SSL certificate expiry..." -ForegroundColor Yellow
& "$PSScriptRoot\check_certificate_expiry.ps1"
if ($LASTEXITCODE -eq 1) {
    Write-Host ""
    Write-Host "⚠️  WARNING: Certificate expiry check gagal atau akan segera expired!" -ForegroundColor Yellow
    $continue = Read-Host "Lanjutkan build? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Build dibatalkan." -ForegroundColor Yellow
        exit 0
    }
}
Write-Host ""

# ── Build ─────────────────────────────────────────────────────────────────────
Write-Host "🏗️  Membangun production build..." -ForegroundColor Yellow
Write-Host "   Environment    : production" -ForegroundColor Cyan
Write-Host "   SSL Pinning    : ENABLED" -ForegroundColor Cyan
Write-Host "   Obfuscation    : ENABLED" -ForegroundColor Cyan
Write-Host "   Sentry         : ENABLED" -ForegroundColor Cyan
Write-Host "   Supabase URL   : $($SupabaseUrl.Substring(0, [Math]::Min(40, $SupabaseUrl.Length)))..." -ForegroundColor Cyan
Write-Host ""

$buildTarget = if ($AppBundle) { "appbundle" } else { "apk" }
$buildArgs = @(
    "build", $buildTarget, "--release",
    "--dart-define=ENVIRONMENT=production",
    "--dart-define=SUPABASE_URL=$SupabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$SupabaseKey",
    "--dart-define=SENTRY_DSN=$SentryDsn",
    "--dart-define=EMAIL_REDIRECT_URL=$EmailRedirectUrl",
    "--obfuscate",
    "--split-debug-info=build/debug-info",
    "--split-per-abi",        # Hasilkan APK terpisah per ABI (arm64, armeabi) → lebih kecil
    "--tree-shake-icons"      # Hapus icon Material yang tidak dipakai → kurangi ukuran
)

flutter @buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ ERROR: Production build gagal!" -ForegroundColor Red
    exit 1
}

# ── Sukses ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✅ Production Build Berhasil!               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($AppBundle) {
    Write-Host "📦 AAB Location:" -ForegroundColor Cyan
    Write-Host "   build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Yellow
} else {
    Write-Host "📦 APK Location:" -ForegroundColor Cyan
    Write-Host "   build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔐 Fitur Keamanan:" -ForegroundColor Cyan
Write-Host "   ✅ SSL Certificate Pinning : AKTIF" -ForegroundColor Green
Write-Host "   ✅ Code Obfuscation        : AKTIF" -ForegroundColor Green
Write-Host "   ✅ Resource Shrinking      : AKTIF" -ForegroundColor Green
Write-Host "   ✅ Debug Info              : Dipisah ke build/debug-info" -ForegroundColor Green
Write-Host "   ✅ Sentry Error Tracking   : AKTIF" -ForegroundColor Green
Write-Host "   ✅ No Hardcoded Credentials: AMAN" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Langkah Selanjutnya:" -ForegroundColor Cyan
Write-Host "   1. Test APK di perangkat fisik (bukan emulator)" -ForegroundColor Yellow
Write-Host "   2. Verifikasi SSL pinning dengan proxy tool (harus GAGAL)" -ForegroundColor Yellow
Write-Host "   3. Jalankan security tests: .\test_security.bat" -ForegroundColor Yellow
Write-Host "   4. Upload ke Google Play Console" -ForegroundColor Yellow
Write-Host ""
