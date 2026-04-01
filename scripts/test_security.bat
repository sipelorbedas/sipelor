@echo off
REM ============================================
REM Security Testing Script for SIPELOR (Windows)
REM ============================================

setlocal enabledelayedexpansion

set PASSED=0
set FAILED=0

echo ============================================
echo SIPELOR Security Test Suite
echo ============================================
echo.

REM Get dependencies
echo Getting dependencies...
call flutter pub get
echo.

REM Run tests
echo Running Security Tests...
echo ----------------------------
echo.

call :run_test "test/utils/password_validator_test.dart"
call :run_test "test/utils/input_sanitizer_test.dart"
call :run_test "test/services/rate_limiter_test.dart"

REM Check for sensitive files
echo.
echo Checking for sensitive files...
echo -------------------------------

call :check_file ".env" "no"
call :check_file "android\key.properties" "no"
call :check_file ".gitignore" "yes"
call :check_file ".env.example" "yes"
call :check_file "android\key.properties.example" "yes"

echo.

REM Static analysis
echo Running static analysis...
echo -------------------------
call flutter analyze --no-pub > nul 2>&1
if errorlevel 1 (
    echo [FAIL] Static analysis failed
    set /a FAILED+=1
) else (
    echo [PASS] Static analysis passed
    set /a PASSED+=1
)

echo.

REM Summary
echo ==============================
echo Security Test Summary
echo ==============================
echo Tests Passed: %PASSED%
echo Tests Failed: %FAILED%
echo.

if %FAILED%==0 (
    echo All security tests passed!
    echo Ready for production deployment
    exit /b 0
) else (
    echo %FAILED% security issues found!
    echo Fix issues before deployment
    exit /b 1
)

:run_test
echo Testing: %~1
call flutter test %~1 --no-pub > nul 2>&1
if errorlevel 1 (
    echo [FAIL] %~1
    set /a FAILED+=1
) else (
    echo [PASS] %~1
    set /a PASSED+=1
)
goto :eof

:check_file
if exist %~1 (
    if "%~2"=="no" (
        echo [FAIL] %~1 exists ^(should be gitignored^)
        set /a FAILED+=1
    ) else (
        echo [PASS] %~1 exists
        set /a PASSED+=1
    )
) else (
    if "%~2"=="yes" (
        echo [WARN] %~1 not found
    ) else (
        echo [PASS] %~1 not in repository
        set /a PASSED+=1
    )
)
goto :eof

endlocal
