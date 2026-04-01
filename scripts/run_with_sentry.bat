@echo off
REM ============================================
REM Run SIPELOR with Sentry Enabled (Development)
REM ============================================

echo.
echo ============================================
echo   SIPELOR - Development Mode with Sentry
echo ============================================
echo.

REM Sentry DSN Configuration
set SENTRY_DSN=https://62e4b6de7057c52e2b68937146034489@o4510788305289216.ingest.us.sentry.io/4510788306468864

echo Configuration:
echo   - Mode: Development
echo   - Sentry: Enabled
echo   - Error Tracking: Active
echo.

echo Starting app...
echo.

flutter run --dart-define=SENTRY_DSN="%SENTRY_DSN%"
