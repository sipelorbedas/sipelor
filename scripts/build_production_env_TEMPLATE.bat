@echo off
REM ============================================================
REM SIPELOR BEDAS - Production Build Script
REM ============================================================
REM 
REM IMPORTANT: 
REM 1. Copy this file to: build_production_env.bat
REM 2. Fill in your actual credentials below
REM 3. Add build_production_env.bat to .gitignore
REM 4. NEVER commit this file with real credentials!
REM
REM ============================================================

echo.
echo ============================================================
echo    BUILDING SIPELOR BEDAS PRODUCTION APK
echo ============================================================
echo.

REM ============================
REM CONFIGURATION
REM ============================
REM Replace these with your actual values:

set SUPABASE_URL=https://your-project-id.supabase.co
set SUPABASE_ANON_KEY=your-anon-key-here
set SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
set ENVIRONMENT=production

REM ============================
REM VALIDATION
REM ============================

echo Validating configuration...
if "%SUPABASE_URL%"=="https://your-project-id.supabase.co" (
    echo ERROR: SUPABASE_URL not configured!
    echo Please edit this file and set your actual Supabase URL
    pause
    exit /b 1
)

if "%SUPABASE_ANON_KEY%"=="your-anon-key-here" (
    echo ERROR: SUPABASE_ANON_KEY not configured!
    echo Please edit this file and set your actual Supabase anon key
    pause
    exit /b 1
)

echo Configuration validated successfully!
echo.

REM ============================
REM PRE-BUILD CHECKS
REM ============================

echo Running pre-build checks...
echo.

REM Check Flutter installation
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found in PATH
    echo Please install Flutter or add it to your PATH
    pause
    exit /b 1
)

echo Flutter: OK
echo.

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
if errorlevel 1 (
    echo ERROR: Failed to clean project
    pause
    exit /b 1
)
echo Clean: OK
echo.

REM Get dependencies
echo Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo Dependencies: OK
echo.

REM ============================
REM BUILD APK
REM ============================

echo.
echo ============================================================
echo    BUILDING RELEASE APK
echo ============================================================
echo.
echo Configuration:
echo - Environment: %ENVIRONMENT%
echo - Supabase URL: %SUPABASE_URL%
echo - Sentry: Enabled
echo.
echo Building... This may take a few minutes...
echo.

flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=SENTRY_DSN=%SENTRY_DSN% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --dart-define=ENABLE_SSL_PINNING=true

if errorlevel 1 (
    echo.
    echo ============================================================
    echo    BUILD FAILED!
    echo ============================================================
    echo.
    echo Please check the error messages above
    pause
    exit /b 1
)

REM ============================
REM POST-BUILD
REM ============================

echo.
echo ============================================================
echo    BUILD SUCCESSFUL!
echo ============================================================
echo.

REM Get APK info
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
set APK_SIZE=
for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA

REM Convert bytes to MB
set /a APK_SIZE_MB=%APK_SIZE% / 1048576

echo APK Location: %APK_PATH%
echo APK Size: %APK_SIZE_MB% MB
echo.

REM Optional: Copy to desktop for easy access
echo Copying APK to desktop...
copy "%APK_PATH%" "%USERPROFILE%\Desktop\sipelor-v1.0.0.apk" >nul 2>&1
if not errorlevel 1 (
    echo APK copied to: Desktop\sipelor-v1.0.0.apk
)
echo.

echo ============================================================
echo    NEXT STEPS
echo ============================================================
echo.
echo 1. Test the APK on a physical device
echo 2. Verify all features work correctly
echo 3. Check Sentry integration (trigger test error)
echo 4. Upload to Play Console for testing
echo.
echo ============================================================

REM Optional: Open output folder
echo.
set /p OPEN_FOLDER="Open output folder? (y/n): "
if /i "%OPEN_FOLDER%"=="y" (
    explorer "build\app\outputs\flutter-apk"
)

pause
