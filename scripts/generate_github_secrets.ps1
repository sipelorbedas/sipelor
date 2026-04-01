# ========================================
# GitHub Secrets Generator for SIPELOR
# ========================================
# Script ini akan extract semua nilai yang dibutuhkan untuk GitHub Secrets
# 
# Usage: 
#   cd D:\RAMA\PROJECT DISPORA\sipelorbedas\sipelor
#   .\scripts\generate_github_secrets.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Secrets Generator - SIPELOR  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running from correct directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "[ERROR] Please run this script from the project root directory!" -ForegroundColor Red
    Write-Host "Usage: cd D:\RAMA\PROJECT DISPORA\sipelorbedas\sipelor" -ForegroundColor Yellow
    Write-Host "       .\scripts\generate_github_secrets.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/4] Reading .env file..." -ForegroundColor Yellow

# Read .env file
$envFile = ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "[ERROR] File .env not found!" -ForegroundColor Red
    Write-Host "Please create .env file with SUPABASE_URL and SUPABASE_ANON_KEY" -ForegroundColor Yellow
    exit 1
}

$envContent = Get-Content $envFile -Raw
$supabaseUrl = ""
$supabaseKey = ""

# Parse .env
$envContent -split "`n" | ForEach-Object {
    $line = $_.Trim()
    if ($line -match "^SUPABASE_URL=(.+)$") {
        $supabaseUrl = $matches[1].Trim()
    }
    elseif ($line -match "^SUPABASE_ANON_KEY=(.+)$") {
        $supabaseKey = $matches[1].Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseKey)) {
    Write-Host "[ERROR] Could not find SUPABASE_URL or SUPABASE_ANON_KEY in .env file!" -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Found Supabase credentials" -ForegroundColor Green
Write-Host ""

Write-Host "[2/4] Reading Android key.properties..." -ForegroundColor Yellow

# Read key.properties
$keyPropertiesFile = "android\key.properties"
if (-not (Test-Path $keyPropertiesFile)) {
    Write-Host "[WARNING] File android\key.properties not found!" -ForegroundColor Yellow
    Write-Host "Android signing secrets will be skipped." -ForegroundColor Yellow
    $keystorePassword = "NOT_FOUND"
    $keyPassword = "NOT_FOUND"
    $keyAlias = "NOT_FOUND"
} else {
    $keyPropsContent = Get-Content $keyPropertiesFile -Raw
    $keystorePassword = ""
    $keyPassword = ""
    $keyAlias = ""
    
    $keyPropsContent -split "`n" | ForEach-Object {
        $line = $_.Trim()
        if ($line -match "^storePassword=(.+)$") {
            $keystorePassword = $matches[1].Trim()
        }
        elseif ($line -match "^keyPassword=(.+)$") {
            $keyPassword = $matches[1].Trim()
        }
        elseif ($line -match "^keyAlias=(.+)$") {
            $keyAlias = $matches[1].Trim()
        }
    }
    
    Write-Host "[SUCCESS] Found Android key properties" -ForegroundColor Green
}
Write-Host ""

Write-Host "[3/4] Converting keystore to Base64..." -ForegroundColor Yellow

# Convert keystore to base64
$keystoreFile = "android\app\keystore.jks"
if (-not (Test-Path $keystoreFile)) {
    Write-Host "[WARNING] Keystore file not found at: $keystoreFile" -ForegroundColor Yellow
    Write-Host "ANDROID_KEYSTORE_BASE64 will be skipped." -ForegroundColor Yellow
    $keystoreBase64 = "NOT_FOUND"
} else {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($keystoreFile)
        $keystoreBase64 = [Convert]::ToBase64String($bytes)
        
        # Save to file for easy access
        $keystoreBase64 | Out-File "keystore_base64.txt" -NoNewline
        
        Write-Host "[SUCCESS] Keystore converted to Base64" -ForegroundColor Green
        Write-Host "[INFO] Base64 keystore saved to: keystore_base64.txt" -ForegroundColor Cyan
    } catch {
        Write-Host "[ERROR] Failed to convert keystore: $_" -ForegroundColor Red
        $keystoreBase64 = "ERROR"
    }
}
Write-Host ""

Write-Host "[4/4] Getting Sentry DSN..." -ForegroundColor Yellow
Write-Host "[INFO] You should have already added SENTRY_DSN manually from Sentry dashboard" -ForegroundColor Cyan
Write-Host ""

# ========================================
# Print Results
# ========================================

Write-Host "========================================" -ForegroundColor Green
Write-Host "  GitHub Secrets - Ready to Copy!  " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Copy-paste these to GitHub Repository Secrets:" -ForegroundColor Cyan
Write-Host "(Go to: https://github.com/r27code/sipelorbedas/settings/secrets/actions)" -ForegroundColor Cyan
Write-Host ""

# Supabase DEV
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 1: SUPABASE_URL_DEV" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   SUPABASE_URL_DEV" -ForegroundColor White
Write-Host "Value:  $supabaseUrl" -ForegroundColor Green
Write-Host ""

# Supabase DEV Key
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 2: SUPABASE_ANON_KEY_DEV" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   SUPABASE_ANON_KEY_DEV" -ForegroundColor White
Write-Host "Value:  $supabaseKey" -ForegroundColor Green
Write-Host ""

# Supabase PROD
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 3: SUPABASE_URL_PROD" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   SUPABASE_URL_PROD" -ForegroundColor White
Write-Host "Value:  $supabaseUrl" -ForegroundColor Green
Write-Host "[NOTE] Using same as DEV for now. Update later with production URL." -ForegroundColor Cyan
Write-Host ""

# Supabase PROD Key
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 4: SUPABASE_ANON_KEY_PROD" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   SUPABASE_ANON_KEY_PROD" -ForegroundColor White
Write-Host "Value:  $supabaseKey" -ForegroundColor Green
Write-Host "[NOTE] Using same as DEV for now. Update later with production key." -ForegroundColor Cyan
Write-Host ""

# Keystore Base64
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 5: ANDROID_KEYSTORE_BASE64" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   ANDROID_KEYSTORE_BASE64" -ForegroundColor White
if ($keystoreBase64 -eq "NOT_FOUND") {
    Write-Host "Value:  [KEYSTORE NOT FOUND]" -ForegroundColor Red
    Write-Host "[ACTION] Create keystore first or check path: android\app\keystore.jks" -ForegroundColor Yellow
} elseif ($keystoreBase64 -eq "ERROR") {
    Write-Host "Value:  [ERROR CONVERTING]" -ForegroundColor Red
} else {
    Write-Host "Value:  [TOO LONG - See keystore_base64.txt]" -ForegroundColor Green
    Write-Host "[INFO] Open keystore_base64.txt and copy entire content" -ForegroundColor Cyan
}
Write-Host ""

# Keystore Password
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 6: KEYSTORE_PASSWORD" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   KEYSTORE_PASSWORD" -ForegroundColor White
Write-Host "Value:  $keystorePassword" -ForegroundColor Green
Write-Host ""

# Key Password
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 7: KEY_PASSWORD" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   KEY_PASSWORD" -ForegroundColor White
Write-Host "Value:  $keyPassword" -ForegroundColor Green
Write-Host ""

# Key Alias
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 8: KEY_ALIAS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   KEY_ALIAS" -ForegroundColor White
Write-Host "Value:  $keyAlias" -ForegroundColor Green
Write-Host ""

# Sentry DSN
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SECRET 9: SENTRY_DSN (Already Added)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Name:   SENTRY_DSN" -ForegroundColor White
Write-Host "Value:  [Already added from Sentry dashboard]" -ForegroundColor Green
Write-Host "[INFO] https://62e4b6de7057c52e2b689371460344890@o4510788305289216.ingest.us.sentry.io/4510788306468864" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Total Secrets: 9" -ForegroundColor White
Write-Host "  ✅ SENTRY_DSN (already added)" -ForegroundColor Green
Write-Host "  📋 8 secrets ready to copy above" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Go to: https://github.com/r27code/sipelorbedas/settings/secrets/actions" -ForegroundColor White
Write-Host "  2. Click 'New repository secret' for each secret above" -ForegroundColor White
Write-Host "  3. Copy Name and Value from above output" -ForegroundColor White
Write-Host "  4. For ANDROID_KEYSTORE_BASE64, open keystore_base64.txt and copy all content" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Done! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
