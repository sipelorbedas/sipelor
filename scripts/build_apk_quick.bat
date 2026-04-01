@echo off
REM ============================================
REM Quick APK Build Script for SIPELOR
REM ============================================
REM Builds APK without requiring credentials input
REM Using debug signing for quick builds

echo.
echo ============================================
echo    BUILDING SIPELOR BEDAS APK
echo ============================================
echo.

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found in PATH
    exit /b 1
)

echo [1/5] Cleaning previous builds...
flutter clean
if errorlevel 1 (
    echo ERROR: Failed to clean project
    exit /b 1
)

echo.
echo [2/5] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    exit /b 1
)

echo.
echo [3/5] Building APK (Release with debug signing)...
echo NOTE: For production with proper signing, use build_production.bat
echo.

flutter build apk --release --target-platform android-arm,android-arm64
if errorlevel 1 (
    echo.
    echo BUILD FAILED!
    exit /b 1
)

echo.
echo ============================================
echo    BUILD SUCCESSFUL!
echo ============================================
echo.

REM Get APK info
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if exist "%APK_PATH%" (
    echo APK Location: %APK_PATH%
    
    REM Get file size
    for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA
    set /a APK_SIZE_MB=%APK_SIZE% / 1048576
    echo APK Size: %APK_SIZE_MB% MB
    
    echo.
    echo Copying APK to desktop...
    copy "%APK_PATH%" "%USERPROFILE%\Desktop\sipelor-bedas.apk" >nul 2>&1
    if not errorlevel 1 (
        echo ✓ APK copied to: Desktop\sipelor-bedas.apk
    )
) else (
    echo WARNING: APK file not found at expected location
)

echo.
echo ============================================
echo    NEXT STEPS
echo ============================================
echo.
echo 1. Install on device: adb install -r "%APK_PATH%"
echo 2. Test all features
echo 3. For production build with proper signing:
echo    - Run: scripts\build_production.bat
echo.

REM Optional: Open output folder
explorer "build\app\outputs\flutter-apk"

pause
