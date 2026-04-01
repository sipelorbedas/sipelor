@echo off
REM ============================================
REM Production Build Script for SIPELOR (Windows)
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo SIPELOR Production Build
echo ============================================
echo.

REM Auto-increment version
echo Incrementing build version...
powershell -ExecutionPolicy Bypass -File scripts\increment_version.ps1
if errorlevel 1 (
    echo ERROR: Failed to increment version!
    exit /b 1
)
echo.

REM Check if .env file exists
if exist ".env" (
    echo WARNING: .env file detected!
    echo    .env files should not be used in production builds.
    echo    Using --dart-define instead for better security.
    echo.
)

REM Check if key.properties exists
if not exist "android\key.properties" (
    echo ERROR: android\key.properties not found!
    echo    Run: scripts\generate_keystore.bat
    exit /b 1
)

REM Sentry Configuration (Error Tracking)
REM ⚠️ IMPORTANT: Keep this DSN confidential!
set SENTRY_DSN=https://62e4b6de7057c52e2b68937146034489@o4510788305289216.ingest.us.sentry.io/4510788306468864

REM Prompt for credentials
echo Enter Supabase credentials:
echo (These will be compiled into the app, not stored in files)
echo.
set /p SUPABASE_URL="Supabase URL: "
set /p SUPABASE_ANON_KEY="Supabase Anon Key: "

if "%SUPABASE_URL%"=="" (
    echo ERROR: Supabase URL cannot be empty!
    exit /b 1
)

if "%SUPABASE_ANON_KEY%"=="" (
    echo ERROR: Supabase Anon Key cannot be empty!
    exit /b 1
)

echo.
echo Build Configuration:
echo    - Credentials: Using --dart-define
echo    - Sentry DSN: Configured (Error Tracking Enabled)
echo    - Obfuscation: Enabled
echo    - Debug info: Split to build\symbols
echo.

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean
call flutter pub get

echo.
echo Building Android APK (Release)...
call flutter build apk --release ^
    --dart-define=SUPABASE_URL="%SUPABASE_URL%" ^
    --dart-define=SUPABASE_ANON_KEY="%SUPABASE_ANON_KEY%" ^
    --dart-define=SENTRY_DSN="%SENTRY_DSN%" ^
    --obfuscate ^
    --split-debug-info=build\app\outputs\symbols ^
    --target-platform android-arm,android-arm64

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo Build successful!
echo.
echo Output files:
dir /B build\app\outputs\flutter-apk\*.apk
echo.

REM Show version info
if exist ".kombai\version_info.txt" (
    echo Version Info:
    type .kombai\version_info.txt
    echo.
)

echo Security Checklist:
echo   [X] Credentials passed via --dart-define
echo   [X] Code obfuscation enabled
echo   [X] Debug symbols split
echo   [X] Version auto-incremented
echo   [ ] Verify keystore is correct
echo   [ ] Test APK on device
echo   [ ] Run security scan
echo.

echo Next Steps:
echo   1. Test the APK: adb install build\app\outputs\flutter-apk\app-release.apk
echo   2. Verify functionality on real device
echo   3. Run security audit before publishing
echo   4. Upload to Google Play Console
echo.
echo REMEMBER:
echo   - Keep build\app\outputs\symbols for crash reports
echo   - Never share APK publicly before Play Store review
echo   - Test payment flow thoroughly
echo.

endlocal
