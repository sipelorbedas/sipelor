# ============================================
# Supabase Configuration Verification Script
# ============================================
# Helps verify if Supabase is configured correctly for deep links

param(
    [string]$supabaseUrl = "",
    [string]$supabaseKey = ""
)

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Supabase Configuration Verification" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running in correct directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml not found!" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "Checking Supabase configuration..." -ForegroundColor Yellow
Write-Host ""

# Check 1: .env file
Write-Host "[1] Checking .env file..." -ForegroundColor Cyan
if (Test-Path ".env") {
    Write-Host "   Found .env file" -ForegroundColor Green
    
    $envContent = Get-Content ".env" -Raw
    
    if ($envContent -match "SUPABASE_URL=(.+)") {
        $url = $matches[1].Trim()
        Write-Host "   SUPABASE_URL: $url" -ForegroundColor White
    } else {
        Write-Host "   WARNING: SUPABASE_URL not found in .env" -ForegroundColor Red
    }
    
    if ($envContent -match "SUPABASE_ANON_KEY=(.+)") {
        $keyPreview = $matches[1].Trim().Substring(0, 20) + "..."
        Write-Host "   SUPABASE_ANON_KEY: $keyPreview" -ForegroundColor White
    } else {
        Write-Host "   WARNING: SUPABASE_ANON_KEY not found in .env" -ForegroundColor Red
    }
} else {
    Write-Host "   WARNING: .env file not found" -ForegroundColor Yellow
    Write-Host "   For development, create .env file with Supabase credentials" -ForegroundColor Gray
}
Write-Host ""

# Check 2: AndroidManifest.xml
Write-Host "[2] Checking AndroidManifest.xml..." -ForegroundColor Cyan
$manifestPath = "android/app/src/main/AndroidManifest.xml"
if (Test-Path $manifestPath) {
    Write-Host "   Found AndroidManifest.xml" -ForegroundColor Green
    
    $manifest = Get-Content $manifestPath -Raw
    
    $deepLinks = @(
        "sipelor://callback",
        "sipelor://reset-password",
        "sipelor://auth/callback"
    )
    
    foreach ($link in $deepLinks) {
        if ($manifest -match [regex]::Escape($link)) {
            Write-Host "   OK: $link configured" -ForegroundColor Green
        } else {
            Write-Host "   MISSING: $link not found!" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ERROR: AndroidManifest.xml not found!" -ForegroundColor Red
}
Write-Host ""

# Check 3: iOS Info.plist
Write-Host "[3] Checking iOS Info.plist..." -ForegroundColor Cyan
$infoPlistPath = "ios/Runner/Info.plist"
if (Test-Path $infoPlistPath) {
    Write-Host "   Found Info.plist" -ForegroundColor Green
    
    $plist = Get-Content $infoPlistPath -Raw
    
    if ($plist -match "<string>sipelor</string>") {
        Write-Host "   OK: sipelor scheme configured" -ForegroundColor Green
    } else {
        Write-Host "   MISSING: sipelor scheme not found!" -ForegroundColor Red
    }
} else {
    Write-Host "   WARNING: Info.plist not found (iOS not configured)" -ForegroundColor Yellow
}
Write-Host ""

# Check 4: Deep link handler
Write-Host "[4] Checking deep link handler..." -ForegroundColor Cyan
$handlerPath = "lib/services/deep_link_handler.dart"
if (Test-Path $handlerPath) {
    Write-Host "   Found deep_link_handler.dart" -ForegroundColor Green
    
    $handler = Get-Content $handlerPath -Raw
    
    if ($handler -match "getSessionFromUrl") {
        Write-Host "   OK: Using getSessionFromUrl (correct)" -ForegroundColor Green
    } else {
        Write-Host "   WARNING: getSessionFromUrl not found" -ForegroundColor Yellow
    }
    
    if ($handler -match "sipelor://reset-password") {
        Write-Host "   OK: Password reset deep link configured" -ForegroundColor Green
    } else {
        Write-Host "   MISSING: Password reset deep link not found!" -ForegroundColor Red
    }
} else {
    Write-Host "   ERROR: deep_link_handler.dart not found!" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Summary & Next Steps" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Local Configuration:" -ForegroundColor Yellow
Write-Host "  - AndroidManifest.xml: Configure deep link schemes" -ForegroundColor White
Write-Host "  - iOS Info.plist: Configure URL schemes" -ForegroundColor White
Write-Host "  - Deep link handler: Handle incoming links" -ForegroundColor White
Write-Host ""

Write-Host "Supabase Dashboard Configuration (IMPORTANT!):" -ForegroundColor Yellow
Write-Host "  1. Go to: https://app.supabase.com/" -ForegroundColor White
Write-Host "  2. Select your project" -ForegroundColor White
Write-Host "  3. Authentication -> URL Configuration" -ForegroundColor White
Write-Host "  4. Update Site URL to: sipelor://callback" -ForegroundColor Green
Write-Host "  5. Add Redirect URLs:" -ForegroundColor White
Write-Host "     - sipelor://callback" -ForegroundColor Gray
Write-Host "     - sipelor://reset-password" -ForegroundColor Gray
Write-Host "     - sipelor://auth/callback" -ForegroundColor Gray
Write-Host "     - io.supabase.sipelor://login-callback" -ForegroundColor Gray
Write-Host "  6. Click SAVE!" -ForegroundColor Red
Write-Host ""

Write-Host "Testing:" -ForegroundColor Yellow
Write-Host "  Run: scripts\test_deep_links.bat" -ForegroundColor White
Write-Host ""

Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  - docs\FIX_EMAIL_OPENS_BROWSER.md" -ForegroundColor White
Write-Host "  - docs\QUICK_FIX_EMAIL_LOCALHOST.md" -ForegroundColor White
Write-Host "  - docs\TROUBLESHOOTING_DEEP_LINKS.md" -ForegroundColor White
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
