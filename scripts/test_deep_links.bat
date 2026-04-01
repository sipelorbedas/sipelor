@echo off
REM ============================================
REM Deep Link Testing Script for SIPELOR (Windows)
REM ============================================

echo ============================================
echo Testing Deep Links for SIPELOR
echo ============================================
echo.

REM Check if ADB is available
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: ADB not found in PATH!
    echo Please install Android SDK Platform Tools
    echo Download: https://developer.android.com/tools/releases/platform-tools
    exit /b 1
)

REM Check if device is connected
adb devices | findstr "device$" >nul
if %errorlevel% neq 0 (
    echo ERROR: No Android device connected!
    echo Please connect your device and enable USB debugging
    exit /b 1
)

echo Device connected. Starting tests...
echo.

REM Test 1: Basic callback
echo 1. Testing basic callback deep link...
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://callback"
timeout /t 3 /nobreak >nul
echo    Done. Check if app opened.
echo.

REM Test 2: Reset password
echo 2. Testing reset password deep link...
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
timeout /t 3 /nobreak >nul
echo    Done. Check if reset password screen opened.
echo.

REM Test 3: Auth callback
echo 3. Testing auth callback deep link...
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://auth/callback"
timeout /t 3 /nobreak >nul
echo    Done. Check if app handled auth callback.
echo.

REM Test 4: Legacy Supabase callback
echo 4. Testing legacy Supabase callback...
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.sipelor://login-callback"
timeout /t 3 /nobreak >nul
echo    Done. Check if app handled legacy callback.
echo.

echo ============================================
echo All tests completed!
echo ============================================
echo.
echo Check the app and Flutter console for:
echo   - App opened successfully
echo   - Correct screens displayed
echo   - No errors in console
echo.
echo To monitor logs in real-time, run:
echo   adb logcat ^| findstr "Deep sipelor Flutter"
echo.

pause
