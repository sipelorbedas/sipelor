# Development Build Script for SIPELOR BEDAS
# Builds debug APK with SSL pinning disabled for easier debugging

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        SIPELOR BEDAS - Development Build Script          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verify Flutter is installed
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter detected" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: Flutter pub get failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build debug APK
Write-Host "🏗️  Building development APK..." -ForegroundColor Yellow
Write-Host "   Environment: development" -ForegroundColor Cyan
Write-Host "   SSL Pinning: DISABLED (for debugging)" -ForegroundColor Cyan
Write-Host ""

flutter build apk --debug `
    --dart-define=ENVIRONMENT=development `
    --dart-define=ENABLE_SSL_PINNING=false

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ ERROR: Development build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║             ✅ Development Build Successful              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📦 APK Location:" -ForegroundColor Cyan
Write-Host "   build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Development Features:" -ForegroundColor Cyan
Write-Host "   ✅ SSL Pinning: DISABLED (proxy debugging works)" -ForegroundColor Yellow
Write-Host "   ✅ Verbose Logging: ENABLED" -ForegroundColor Yellow
Write-Host "   ✅ Debug Tools: ENABLED" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 For Testing:" -ForegroundColor Cyan
Write-Host "   - Charles Proxy / Fiddler will work" -ForegroundColor Yellow
Write-Host "   - Network traffic can be inspected" -ForegroundColor Yellow
Write-Host "   - Hot reload available with 'flutter run'" -ForegroundColor Yellow
Write-Host ""
