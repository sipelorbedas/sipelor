# ============================================================================
# Google OAuth Diagnostic Script
# ============================================================================
# Script ini memeriksa konfigurasi Google OAuth untuk SIPELOR BEDAS
# Gunakan untuk troubleshooting masalah "Gmail login tidak bisa"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       Google OAuth Configuration Diagnostic Tool          ║" -ForegroundColor Cyan
Write-Host "║                  SIPELOR BEDAS                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()
$success = @()

# ============================================================================
# 1. Check Deep Link Configuration
# ============================================================================
Write-Host "📱 Checking Deep Link Configuration..." -ForegroundColor Yellow
Write-Host ""

$manifestPath = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    if ($manifestContent -match 'io\.supabase\.sipelor') {
        Write-Host "  ✅ Deep link scheme 'io.supabase.sipelor' found in AndroidManifest.xml" -ForegroundColor Green
        $success += "Deep link configured in Android"
    } else {
        Write-Host "  ❌ Deep link scheme 'io.supabase.sipelor' NOT found" -ForegroundColor Red
        $issues += "Missing deep link configuration in AndroidManifest.xml"
    }
    
    if ($manifestContent -match 'android:host="login-callback"') {
        Write-Host "  ✅ OAuth callback host 'login-callback' configured" -ForegroundColor Green
        $success += "OAuth callback host configured"
    } else {
        Write-Host "  ❌ OAuth callback host 'login-callback' NOT configured" -ForegroundColor Red
        $issues += "Missing login-callback host in deep link configuration"
    }
} else {
    Write-Host "  ❌ AndroidManifest.xml not found at expected path" -ForegroundColor Red
    $issues += "AndroidManifest.xml not found"
}

Write-Host ""

# ============================================================================
# 2. Check Social Auth Service
# ============================================================================
Write-Host "🔧 Checking Social Auth Service..." -ForegroundColor Yellow
Write-Host ""

$socialAuthPath = "lib\services\social_auth_service.dart"
if (Test-Path $socialAuthPath) {
    Write-Host "  ✅ social_auth_service.dart exists" -ForegroundColor Green
    $success += "Social auth service file exists"
    
    $socialAuthContent = Get-Content $socialAuthPath -Raw
    
    if ($socialAuthContent -match 'signInWithGoogle') {
        Write-Host "  ✅ signInWithGoogle method implemented" -ForegroundColor Green
        $success += "Google sign-in method exists"
    } else {
        Write-Host "  ❌ signInWithGoogle method NOT found" -ForegroundColor Red
        $issues += "signInWithGoogle method not implemented"
    }
    
    if ($socialAuthContent -match 'OAuthProvider\.google') {
        Write-Host "  ✅ Google OAuth provider configured" -ForegroundColor Green
        $success += "OAuth provider configured"
    } else {
        Write-Host "  ❌ Google OAuth provider NOT configured" -ForegroundColor Red
        $issues += "OAuth provider not configured"
    }
} else {
    Write-Host "  ❌ social_auth_service.dart not found" -ForegroundColor Red
    $issues += "Social auth service file missing"
}

Write-Host ""

# ============================================================================
# 3. Check Supabase Configuration
# ============================================================================
Write-Host "🔐 Checking Supabase Configuration..." -ForegroundColor Yellow
Write-Host ""

$envPath = ".env"
if (Test-Path $envPath) {
    Write-Host "  ✅ .env file exists" -ForegroundColor Green
    $success += ".env file found"
    
    $envContent = Get-Content $envPath -Raw
    
    if ($envContent -match 'SUPABASE_URL=') {
        Write-Host "  ✅ SUPABASE_URL configured" -ForegroundColor Green
        $success += "Supabase URL configured"
    } else {
        Write-Host "  ❌ SUPABASE_URL NOT configured" -ForegroundColor Red
        $issues += "Missing SUPABASE_URL in .env"
    }
    
    if ($envContent -match 'SUPABASE_ANON_KEY=') {
        Write-Host "  ✅ SUPABASE_ANON_KEY configured" -ForegroundColor Green
        $success += "Supabase anon key configured"
    } else {
        Write-Host "  ❌ SUPABASE_ANON_KEY NOT configured" -ForegroundColor Red
        $issues += "Missing SUPABASE_ANON_KEY in .env"
    }
} else {
    Write-Host "  ⚠️  .env file not found (might use --dart-define)" -ForegroundColor Yellow
    $warnings += ".env file not found - make sure credentials are provided via --dart-define"
}

Write-Host ""

# ============================================================================
# 4. Check Dependencies
# ============================================================================
Write-Host "📦 Checking Flutter Dependencies..." -ForegroundColor Yellow
Write-Host ""

$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    
    if ($pubspecContent -match 'supabase_flutter:') {
        Write-Host "  ✅ supabase_flutter dependency found" -ForegroundColor Green
        $success += "Supabase Flutter package installed"
    } else {
        Write-Host "  ❌ supabase_flutter dependency NOT found" -ForegroundColor Red
        $issues += "Missing supabase_flutter in pubspec.yaml"
    }
    
    if ($pubspecContent -match 'app_links:') {
        Write-Host "  ✅ app_links dependency found (for deep links)" -ForegroundColor Green
        $success += "App links package installed"
    } else {
        Write-Host "  ⚠️  app_links dependency NOT found" -ForegroundColor Yellow
        $warnings += "Consider adding app_links for better deep link handling"
    }
} else {
    Write-Host "  ❌ pubspec.yaml not found" -ForegroundColor Red
    $issues += "pubspec.yaml not found"
}

Write-Host ""

# ============================================================================
# Summary Report
# ============================================================================
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    DIAGNOSTIC SUMMARY                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Successful Checks: $($success.Count)" -ForegroundColor Green
if ($success.Count -gt 0) {
    foreach ($item in $success) {
        Write-Host "   • $item" -ForegroundColor Gray
    }
}
Write-Host ""

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($item in $warnings) {
        Write-Host "   • $item" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "❌ Issues Found: $($issues.Count)" -ForegroundColor Red
    foreach ($item in $issues) {
        Write-Host "   • $item" -ForegroundColor Gray
    }
    Write-Host ""
}

# ============================================================================
# Root Cause Analysis
# ============================================================================
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  ROOT CAUSE ANALYSIS                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "📋 Code configuration looks correct!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The issue is likely in SUPABASE DASHBOARD configuration:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Most common causes:" -ForegroundColor Cyan
    Write-Host "  1. ❌ Google provider NOT enabled in Supabase Dashboard" -ForegroundColor White
    Write-Host "  2. ❌ Google Client ID/Secret NOT configured in Supabase" -ForegroundColor White
    Write-Host "  3. ❌ OAuth credentials NOT created in Google Cloud Console" -ForegroundColor White
    Write-Host "  4. ❌ Redirect URLs mismatch between Google Console and Supabase" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "🔧 Please fix the code issues listed above first" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# Next Steps
# ============================================================================
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      NEXT STEPS                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 To fix Gmail login issue, follow these steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "STEP 1: Check Supabase Dashboard" -ForegroundColor Cyan
Write-Host "  • Go to: https://app.supabase.com/" -ForegroundColor Gray
Write-Host "  • Navigate to: Authentication > Providers > Google" -ForegroundColor Gray
Write-Host "  • Verify: Google provider is ENABLED (toggle ON)" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 2: Configure Google OAuth Credentials" -ForegroundColor Cyan
Write-Host "  • If not configured, you need to:" -ForegroundColor Gray
Write-Host "    1. Create OAuth credentials in Google Cloud Console" -ForegroundColor Gray
Write-Host "    2. Get Client ID and Client Secret" -ForegroundColor Gray
Write-Host "    3. Add them to Supabase Dashboard" -ForegroundColor Gray
Write-Host ""
Write-Host "  📖 Read: docs\GOOGLE_OAUTH_SETUP.md for detailed guide" -ForegroundColor Yellow
Write-Host ""

Write-Host "STEP 3: Configure Redirect URLs" -ForegroundColor Cyan
Write-Host "  • In Supabase Dashboard:" -ForegroundColor Gray
Write-Host "    - Go to: Authentication > URL Configuration" -ForegroundColor Gray
Write-Host "    - Add redirect URL: io.supabase.sipelor://login-callback/" -ForegroundColor Gray
Write-Host ""
Write-Host "  • In Google Cloud Console:" -ForegroundColor Gray
Write-Host "    - Add: https://[your-project].supabase.co/auth/v1/callback" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 4: Test the Configuration" -ForegroundColor Cyan
Write-Host "  • Run the app: flutter run" -ForegroundColor Gray
Write-Host "  • Click 'Sign in with Google'" -ForegroundColor Gray
Write-Host "  • Browser should open for Google OAuth" -ForegroundColor Gray
Write-Host "  • After allowing, app should return and login" -ForegroundColor Gray
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    QUICK FIX GUIDE                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "📖 For step-by-step configuration guide, read:" -ForegroundColor Yellow
Write-Host "   docs\GOOGLE_OAUTH_SETUP.md" -ForegroundColor White
Write-Host ""
Write-Host "🆘 Need help? Check troubleshooting section in the guide" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Test Deep Link (Optional)
# ============================================================================
Write-Host "🔍 Want to test deep link manually?" -ForegroundColor Yellow
Write-Host "   Run this command with connected Android device:" -ForegroundColor Gray
Write-Host '   adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.sipelor://login-callback/"' -ForegroundColor White
Write-Host ""

Write-Host "✨ Diagnostic complete!" -ForegroundColor Green
Write-Host ""
