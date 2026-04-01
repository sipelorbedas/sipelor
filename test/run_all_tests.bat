@echo off
REM Run all tests for SIPELOR BEDAS with coverage
REM Windows batch script

echo ========================================
echo    SIPELOR BEDAS - Test Suite Runner
echo ========================================
echo.

echo [1/5] Generating mock classes...
call flutter pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate mocks
    exit /b 1
)

echo.
echo [2/5] Running unit tests...
call flutter test test/services/ test/utils/
if %errorlevel% neq 0 (
    echo ERROR: Unit tests failed
    exit /b 1
)

echo.
echo [3/5] Running widget tests...
call flutter test test/widgets/
if %errorlevel% neq 0 (
    echo ERROR: Widget tests failed
    exit /b 1
)

echo.
echo [4/5] Running integration tests...
call flutter test test/integration/
if %errorlevel% neq 0 (
    echo ERROR: Integration tests failed
    exit /b 1
)

echo.
echo [5/5] Generating coverage report...
call flutter test --coverage
if %errorlevel% neq 0 (
    echo ERROR: Coverage generation failed
    exit /b 1
)

echo.
echo ========================================
echo    All tests passed! ✅
echo    Coverage report: coverage/lcov.info
echo ========================================
echo.
echo To view coverage in browser:
echo   1. Install genhtml: choco install lcov
echo   2. Run: perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml -o coverage\html coverage\lcov.info
echo   3. Open: coverage\html\index.html
echo.

exit /b 0
