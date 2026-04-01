@echo off
REM SIPELOR BEDAS - Test Runner Script (Windows)
REM Run all tests with coverage and generate reports

echo ================================================================
echo            SIPELOR BEDAS TEST SUITE                    
echo ================================================================
echo.

REM Step 1: Clean previous coverage
echo [STEP 1] Cleaning previous coverage...
if exist coverage\ rmdir /s /q coverage
flutter clean

REM Step 2: Get dependencies
echo.
echo [STEP 2] Getting dependencies...
flutter pub get

REM Step 3: Run code analysis
echo.
echo [STEP 3] Running code analysis...
flutter analyze
if errorlevel 1 (
    echo ERROR: Code analysis failed!
    exit /b 1
)
echo SUCCESS: Code analysis passed
echo.

REM Step 4: Run tests with coverage
echo [STEP 4] Running tests with coverage...
flutter test --coverage
if errorlevel 1 (
    echo ERROR: Tests failed!
    exit /b 1
)
echo SUCCESS: All tests passed
echo.

REM Step 5: Generate coverage report
echo [STEP 5] Generating coverage report...
if exist coverage\lcov.info (
    echo Coverage file generated: coverage\lcov.info
) else (
    echo WARNING: No coverage file generated
)
echo.

REM Step 6: Summary
echo ================================================================
echo            TEST SUITE COMPLETED                         
echo ================================================================
echo.
echo Next steps:
echo   - Review coverage report: coverage\lcov.info
echo   - Fix any issues found
echo   - Commit changes
echo.

pause
