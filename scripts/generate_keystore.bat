@echo off
REM ============================================
REM Android Keystore Generation Script (Windows)
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo Android Keystore Generation for SIPELOR
echo ============================================
echo.
echo IMPORTANT SECURITY NOTES:
echo   1. This will create a NEW keystore file
echo   2. Keep the keystore file VERY SECURE
echo   3. NEVER commit keystore to version control
echo   4. Store backup in encrypted password manager
echo   5. If you lose this keystore, you can't update your app!
echo.
set /p confirm="Do you want to continue? (yes/no): "

if /i not "%confirm%"=="yes" (
    echo Cancelled by user
    exit /b 1
)

REM Configuration
set KEYSTORE_DIR=android\app
set KEYSTORE_NAME=sipelor-keystore.jks
set KEYSTORE_PATH=%KEYSTORE_DIR%\%KEYSTORE_NAME%
set KEY_ALIAS=sipelor
set KEY_PROPERTIES=android\key.properties

REM Check if keystore already exists
if exist "%KEYSTORE_PATH%" (
    echo.
    echo WARNING: Keystore file already exists at: %KEYSTORE_PATH%
    set /p overwrite="Do you want to OVERWRITE it? (yes/no): "
    
    if /i not "!overwrite!"=="yes" (
        echo Keeping existing keystore. Exiting...
        exit /b 0
    )
    
    echo Backing up old keystore...
    move "%KEYSTORE_PATH%" "%KEYSTORE_PATH%.backup.%date:~-4,4%%date:~-10,2%%date:~-7,2%"
)

REM Create directory if it doesn't exist
if not exist "%KEYSTORE_DIR%" mkdir "%KEYSTORE_DIR%"

echo.
echo Generating new keystore...
echo    Location: %KEYSTORE_PATH%
echo    Alias: %KEY_ALIAS%
echo.
echo You will be asked to provide:
echo   - Keystore password (remember this!)
echo   - Key password (can be same as keystore password)
echo   - Your name, organization, city, country
echo.

REM Generate keystore
keytool -genkey -v -keystore "%KEYSTORE_PATH%" -keyalg RSA -keysize 2048 -validity 10000 -alias "%KEY_ALIAS%"

if errorlevel 1 (
    echo Error generating keystore
    exit /b 1
)

echo.
echo Keystore generated successfully!
echo.

REM Prompt for passwords
echo Creating key.properties file...
echo.
set /p STORE_PASSWORD="Enter the keystore password: "
set /p KEY_PASSWORD="Enter the key password (press Enter if same as keystore): "

if "%KEY_PASSWORD%"=="" set KEY_PASSWORD=%STORE_PASSWORD%

REM Create key.properties file
(
echo # Android Keystore Configuration
echo # Generated on: %date% %time%
echo # 
echo # SECURITY WARNING:
echo # This file contains sensitive credentials!
echo # - NEVER commit to version control
echo # - Keep backup in secure password manager
echo # - File is already in .gitignore
echo.
echo storePassword=%STORE_PASSWORD%
echo keyPassword=%KEY_PASSWORD%
echo keyAlias=%KEY_ALIAS%
echo storeFile=app/%KEYSTORE_NAME%
) > "%KEY_PROPERTIES%"

echo.
echo key.properties file created at: %KEY_PROPERTIES%
echo.

echo ============================================
echo SECURITY CHECKLIST:
echo ============================================
echo [X] Keystore created: %KEYSTORE_PATH%
echo [X] key.properties created: %KEY_PROPERTIES%
echo.
echo NEXT STEPS (CRITICAL!):
echo   1. Backup keystore file to secure location
echo   2. Save passwords in password manager
echo   3. Verify .gitignore includes key.properties and *.jks
echo   4. Test signing: flutter build apk --release
echo   5. Document keystore details
echo.
echo REMEMBER:
echo   - If you lose this keystore, you CANNOT update your app
echo   - Google Play App Signing is recommended
echo   - Rotate keystore every 1-2 years
echo.
echo Setup complete! You can now build release APKs.
echo.

endlocal
