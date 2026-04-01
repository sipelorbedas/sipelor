@echo off
title SIPELOR BEDAS — Admin Panel
echo.
echo  ==========================================
echo   SIPELOR BEDAS — Admin Panel
echo  ==========================================
echo.

:: Cek Python tersedia
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python tidak ditemukan!
    echo  Silakan install Python di: https://python.org/downloads
    echo  Centang "Add Python to PATH" saat install.
    pause
    exit /b 1
)

:: Cari port yang tersedia (default 3000, fallback 8080)
set PORT=3000
netstat -an | find ":%PORT% " >nul 2>&1
if not errorlevel 1 (
    set PORT=8080
)

echo  Menjalankan server di port %PORT%...
echo  Akses dari komputer lain: http://<IP-PC-ini>:%PORT%/login.html
echo.

:: Buka browser otomatis setelah 2 detik
start /b cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:%PORT%/login.html"

:: Tampilkan IP jaringan agar bisa diakses komputer lain
echo  ==========================================
echo   IP Address di jaringan ini:
ipconfig | findstr /i "IPv4"
echo  ==========================================
echo.
echo  [Tekan Ctrl+C untuk menghentikan server]
echo.

:: Jalankan server
python -m http.server %PORT%
