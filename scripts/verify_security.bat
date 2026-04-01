@echo off
REM ============================================
REM Security Verification Script for SIPELOR (Windows)
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo SIPELOR Security Verification
echo ============================================
echo.

set ISSUES=0

REM Check 1: Verify .env not in git history
echo [1/5] Checking .env in git history...
git log --all --full-history -- .env > nul 2>&1
if errorlevel 1 (
    echo [PASS] .env never committed to git
) else (
    echo [FAIL] .env found in git history - ROTATE SUPABASE KEYS!
    set /a ISSUES+=1
)
echo.

REM Check 2: Verify keystore files not in git history
echo [2/5] Checking keystore files in git history...
git log --all --full-history -- "*.jks" > nul 2>&1
if errorlevel 1 (
    echo [PASS] No keystore files in git history
) else (
    echo [FAIL] Keystore files found in git history - GENERATE NEW KEYSTORE!
    set /a ISSUES+=1
)
echo.

REM Check 3: Verify key.properties not in git history
echo [3/5] Checking key.properties in git history...
git log --all --full-history -- android\key.properties > nul 2>&1
if errorlevel 1 (
    echo [PASS] key.properties never committed
) else (
    echo [FAIL] key.properties found in git history - GENERATE NEW KEYSTORE!
    set /a ISSUES+=1
)
echo.

REM Check 4: Verify .gitignore exists and is correct
echo [4/5] Checking .gitignore configuration...
findstr /C:".env" .gitignore > nul 2>&1
if errorlevel 1 (
    echo [FAIL] .env not in .gitignore
    set /a ISSUES+=1
) else (
    echo [PASS] .env is gitignored
)

findstr /C:"key.properties" .gitignore > nul 2>&1
if errorlevel 1 (
    echo [FAIL] key.properties not in .gitignore
    set /a ISSUES+=1
) else (
    echo [PASS] key.properties is gitignored
)

findstr /C:".jks" .gitignore > nul 2>&1
if errorlevel 1 (
    echo [FAIL] .jks not in .gitignore
    set /a ISSUES+=1
) else (
    echo [PASS] .jks files are gitignored
)
echo.

REM Check 5: Run Flutter analysis
echo [5/5] Running static analysis...
call flutter analyze --no-pub > nul 2>&1
if errorlevel 1 (
    echo [WARN] Static analysis found issues
) else (
    echo [PASS] Static analysis passed
)
echo.

REM Summary
echo ============================================
echo Security Verification Complete
echo ============================================

if %ISSUES% == 0 (
    echo.
    echo [SUCCESS] No security issues found! ^(づ｡◕‿‿◕｡^)づ
    echo.
    echo Your project is SECURE and ready for production!
    echo.
    exit /b 0
) else (
    echo.
    echo [WARNING] %ISSUES% security issue(s) found!
    echo.
    echo Please review and fix the issues above.
    echo See QUICK_SECURITY_FIXES.md for detailed instructions.
    echo.
    exit /b 1
)

endlocal
