@echo off
REM ============================================
REM Test Sentry Integration - SIPELOR
REM ============================================
REM This script tests if Sentry error tracking is working

echo.
echo ============================================
echo   SENTRY ERROR TRACKING TEST
echo ============================================
echo.

REM Sentry DSN Configuration
set SENTRY_DSN=https://62e4b6de7057c52e2b68937146034489@o4510788305289216.ingest.us.sentry.io/4510788306468864

echo Sentry Configuration:
echo   DSN: %SENTRY_DSN%
echo   Mode: Development Test
echo.

echo Starting Flutter app with Sentry enabled...
echo.
echo INSTRUCTIONS:
echo   1. Wait for app to load
echo   2. Open Debug Menu (from drawer)
echo   3. Tap "Test Sentry Error"
echo   4. Check Sentry dashboard for the error
echo.
echo Sentry Dashboard: https://sentry.io
echo.

REM Run Flutter with Sentry enabled
flutter run --dart-define=SENTRY_DSN="%SENTRY_DSN%"

echo.
echo Test complete!
echo.
echo Next Steps:
echo   1. Login to https://sentry.io
echo   2. Navigate to your SIPELOR project
echo   3. Check Issues tab for test error
echo   4. If error appears, Sentry is working! ✓
echo.

pause
