@echo off
:: ============================================================
:: Build SIPELOR Admin — Windows Portable .EXE
:: ============================================================
:: Jalankan file ini dari dalam folder project.
:: Butuh: Node.js (https://nodejs.org) — versi 18 ke atas
:: ============================================================

title SIPELOR Admin — Build .EXE

echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║    SIPELOR BEDAS — Build Admin .EXE          ║
echo  ║    Output: website\admin\dist\               ║
echo  ╚══════════════════════════════════════════════╝
echo.

:: Masuk ke folder admin
cd /d "%~dp0..\website\admin"
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] Folder website\admin tidak ditemukan!
    pause
    exit /b 1
)

:: Cek Node.js
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] Node.js tidak ditemukan!
    echo.
    echo  Install Node.js dari: https://nodejs.org
    echo  Pilih versi LTS ^(18 atau 20^)
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('node -v 2^>^&1') do set NODE_VER=%%v
echo  Node.js terdeteksi: %NODE_VER%

:: Install dependencies (Electron + electron-builder)
echo.
echo  [1/3] Menginstall dependencies...
echo  (Proses ini bisa memakan beberapa menit pertama kali)
echo.
call npm install --prefer-offline 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] npm install gagal!
    pause
    exit /b 1
)

echo.
echo  [2/3] Mem-build .exe portable...
echo.
call npm run build
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] Build gagal! Cek pesan error di atas.
    pause
    exit /b 1
)

echo.
echo  [3/3] Build selesai!
echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║  ✓ File .EXE tersimpan di:                  ║
echo  ║    website\admin\dist\SIPELOR-Admin-v1.0.0.exe ║
echo  ║                                              ║
echo  ║  File ini bisa dicopy ke PC manapun!         ║
echo  ╚══════════════════════════════════════════════╝
echo.

:: Buka folder output
start "" "%~dp0..\website\admin\dist"

pause
