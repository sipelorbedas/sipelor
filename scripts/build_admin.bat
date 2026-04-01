@echo off
:: ============================================================
:: Build Admin Panel — SIPELOR BEDAS (Windows Shortcut)
:: ============================================================
:: Jalankan file ini dari mana saja — otomatis pakai PowerShell
:: ============================================================

echo.
echo  SIPELOR BEDAS — Admin Panel Build
echo  (Menjalankan build_admin.ps1...)
echo.

cd /d "%~dp0.."

powershell -ExecutionPolicy Bypass -File "%~dp0build_admin.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo  BUILD GAGAL! Cek pesan error di atas.
    pause
    exit /b 1
)

echo.
pause
