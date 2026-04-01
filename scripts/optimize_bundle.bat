@echo off
REM =========================================
REM  Bundle Size Optimization Script
REM  For Windows
REM =========================================

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║        📦 SIPELOR BEDAS - BUNDLE OPTIMIZATION             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Clean build
echo [1/5] Cleaning previous builds...
call flutter clean
if errorlevel 1 (
    echo ❌ Clean failed
    exit /b 1
)
echo ✅ Clean completed
echo.

REM Get dependencies
echo [2/5] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ❌ Dependencies failed
    exit /b 1
)
echo ✅ Dependencies installed
echo.

REM Analyze code
echo [3/5] Analyzing code...
call flutter analyze --no-pub
echo ✅ Analysis completed
echo.

REM Build optimized APK with size analysis
echo [4/5] Building optimized APK...
call flutter build apk --release --obfuscate --split-debug-info=build/debug/ --analyze-size --target-platform android-arm64
if errorlevel 1 (
    echo ❌ Build failed
    exit /b 1
)
echo ✅ Build completed
echo.

REM Show build size
echo [5/5] Build Summary:
echo.
dir build\app\outputs\flutter-apk\app-release.apk
echo.

echo ╔════════════════════════════════════════════════════════════╗
echo ║                    ✅ OPTIMIZATION COMPLETE                ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║ APK Location:                                              ║
echo ║   build\app\outputs\flutter-apk\app-release.apk           ║
echo ║                                                            ║
echo ║ Debug Info:                                                ║
echo ║   build\debug\                                             ║
echo ║                                                            ║
echo ║ Optimizations Applied:                                     ║
echo ║   ✓ Code obfuscation                                      ║
echo ║   ✓ Split debug info                                      ║
echo ║   ✓ Tree shaking                                          ║
echo ║   ✓ Minification                                          ║
echo ║   ✓ ARM64 optimization                                    ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

pause
