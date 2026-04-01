@echo off
REM =========================================
REM  Dependency Health Check Script
REM  For Windows
REM =========================================

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║        📦 DEPENDENCY HEALTH CHECK                         ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo [1/3] Checking for outdated packages...
call flutter pub outdated
echo.

echo [2/3] Analyzing dependency tree...
call flutter pub deps
echo.

echo [3/3] Recommendations:
echo.
echo ✅ Regular Maintenance:
echo    - Check for updates: Weekly
echo    - Update dependencies: Monthly
echo    - Security audit: Monthly
echo.
echo 📚 Resources:
echo    - pub.dev/packages - Package repository
echo    - pub.dev/security-advisories - Security alerts
echo    - snyk.io - Vulnerability scanner
echo.
echo 🔧 Useful Commands:
echo    - flutter pub upgrade --major-versions
echo    - flutter pub upgrade --dry-run
echo    - dart pub global activate pana
echo.

pause
