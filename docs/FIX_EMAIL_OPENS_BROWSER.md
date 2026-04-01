# 🚨 FIX: Email Membuka Browser Blank (Bukan Aplikasi)

## 📸 Screenshot Masalah Anda

Anda mengalami masalah ini:
- ✉️ Klik button "Reset Password" di email
- 🌐 Browser terbuka (bukan aplikasi)
- ⬛ Layar hitam/blank di browser (google.com atau localhost)
- ❌ Aplikasi tidak terbuka

## 🎯 Root Cause

**Masalah:** Link di email menggunakan HTTPS URL (seperti `https://localhost:3000/...` atau `https://xxx.supabase.co/...`) bukan deep link scheme (`sipelor://...`)

**Penyebab:** Site URL di Supabase Dashboard masih default (localhost atau supabase domain)

## ✅ Solusi Lengkap

### Step 1: Login ke Supabase Dashboard

1. Buka browser
2. Ke: **https://app.supabase.com/**
3. Login dengan akun Anda
4. Pilih project **SIPELOR**

### Step 2: Masuk ke Authentication Settings

1. Di sidebar kiri, klik **Authentication** (icon 🔐)
2. Klik tab **URL Configuration**

### Step 3: Update Site URL (PENTING!)

Anda akan melihat form seperti ini:

```
┌─────────────────────────────────────────┐
│ Site URL                                 │
│ ┌─────────────────────────────────────┐ │
│ │ http://localhost:3000               │ │ ← INI YANG SALAH!
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**UBAH MENJADI:**

```
┌─────────────────────────────────────────┐
│ Site URL                                 │
│ ┌─────────────────────────────────────┐ │
│ │ sipelor://callback                  │ │ ← UBAH KE INI!
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Copy paste ini ke field Site URL:**
```
sipelor://callback
```

### Step 4: Update Redirect URLs

Scroll ke bawah, Anda akan melihat:

```
┌─────────────────────────────────────────┐
│ Redirect URLs                            │
│ (One per line)                           │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**PASTE SEMUA URL INI** (satu per baris):

```
sipelor://callback
sipelor://reset-password
sipelor://auth/callback
io.supabase.sipelor://login-callback
```

Hasilnya harus seperti ini:

```
┌─────────────────────────────────────────┐
│ Redirect URLs                            │
│ ┌─────────────────────────────────────┐ │
│ │ sipelor://callback                  │ │
│ │ sipelor://reset-password            │ │
│ │ sipelor://auth/callback             │ │
│ │ io.supabase.sipelor://login-callb...│ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Step 5: SAVE Configuration

⚠️ **PENTING:** Jangan lupa klik tombol **Save** di bagian bawah halaman!

```
                    [  Save  ]
```

Tunggu notifikasi "Configuration saved successfully".

### Step 6: Test dengan Email Baru

**PENTING:** Email lama masih menggunakan konfigurasi lama!

1. **Hapus email lama** dari inbox
2. **Minta kirim ulang** forgot password dari aplikasi
3. **Buka email baru** yang baru dikirim
4. **Klik button** "Reset Password"
5. ✅ **Aplikasi akan terbuka langsung** (BUKAN browser!)

## 🧪 Verifikasi Konfigurasi

Setelah save, verifikasi dengan cara ini:

### Verifikasi 1: Check Supabase Dashboard

1. Masuk lagi ke **Authentication** → **URL Configuration**
2. Pastikan Site URL = `sipelor://callback` (BUKAN localhost)
3. Pastikan 4 redirect URLs sudah ada

### Verifikasi 2: Test Deep Link Langsung

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
```

Aplikasi harus terbuka!

**Windows (PowerShell):**
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
```

### Verifikasi 3: Test Email Flow

1. Di aplikasi, pilih "Lupa Password"
2. Input email
3. Submit
4. Buka email
5. Klik button "Reset Password"
6. ✅ Aplikasi terbuka (BUKAN browser!)

## ❌ Kesalahan Umum

### Kesalahan #1: Typo di URL

❌ SALAH:
```
sipelore://callback          (typo: sipelore)
sipelor://calback            (typo: calback)
sipelor: //callback          (ada spasi)
Sipelor://callback           (huruf besar S)
```

✅ BENAR:
```
sipelor://callback           (lowercase, no space)
```

### Kesalahan #2: Lupa Save

Setelah ubah Site URL dan Redirect URLs, **HARUS klik Save!**

Tanpa save, perubahan tidak akan tersimpan.

### Kesalahan #3: Menggunakan Email Lama

Email yang dikirim SEBELUM update config masih pakai URL lama.

**Solusi:** Hapus email lama, kirim ulang forgot password, gunakan email baru.

### Kesalahan #4: Tidak Reload/Restart

Setelah update config, kadang perlu:
1. Close dan reopen aplikasi
2. Atau tunggu 1-2 menit untuk propagasi

## 🔍 Troubleshooting

### Masalah: Masih Buka Browser

**Kemungkinan:**
1. Site URL belum diubah
2. Lupa klik Save
3. Masih menggunakan email lama (sebelum config diubah)

**Solusi:**
1. Double check Site URL di Supabase = `sipelor://callback`
2. Pastikan sudah Save
3. Kirim ulang email baru
4. Test dengan email yang BARU dikirim

### Masalah: "Invalid Redirect URL" Error

**Kemungkinan:**
- Redirect URLs belum ditambahkan

**Solusi:**
1. Pastikan 4 redirect URLs sudah ada
2. Tidak ada typo
3. Sudah Save

### Masalah: App Tidak Terbuka

**Kemungkinan:**
- Deep link tidak ter-register di Android

**Solusi:**
```bash
# Reinstall aplikasi
adb uninstall com.sipelor.app
adb install build/app/outputs/flutter-apk/app-release.apk

# Test deep link
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
```

## 📋 Checklist Final

Sebelum test, pastikan:

- [ ] Supabase Dashboard opened
- [ ] Authentication → URL Configuration opened
- [ ] Site URL = `sipelor://callback` (NOT localhost)
- [ ] 4 Redirect URLs added:
  - [ ] `sipelor://callback`
  - [ ] `sipelor://reset-password`
  - [ ] `sipelor://auth/callback`
  - [ ] `io.supabase.sipelor://login-callback`
- [ ] Clicked **Save** button
- [ ] Waited 1-2 minutes
- [ ] Deleted old emails
- [ ] Sent new forgot password request
- [ ] Using NEW email (not old one)

## 📞 Masih Bermasalah?

### Check 1: Screenshot Supabase Config

Ambil screenshot dari:
- Authentication → URL Configuration
- Pastikan Site URL dan Redirect URLs sudah benar

### Check 2: Check Logs

```bash
# Android
adb logcat | findstr "Deep sipelor"

# Look for:
# 🔗 Deep link received: sipelor://...
```

### Check 3: Verify App Installation

```bash
# Check if app installed
adb shell pm list packages | findstr sipelor

# Check deep link registration
adb shell dumpsys package | findstr -A 5 sipelor
```

## 🎯 Expected Result

Setelah fix:

1. ✉️ Buka email
2. 👆 Klik button "Reset Password"
3. 📱 Aplikasi SIPELOR terbuka langsung
4. ⏳ Loading "Memverifikasi link..."
5. 📝 Form reset password muncul
6. ✅ Input password baru → Submit → Success!

**NO MORE BROWSER!** 🎉

---

## 📚 Related Documentation

- [QUICK_FIX_EMAIL_LOCALHOST.md](QUICK_FIX_EMAIL_LOCALHOST.md) - Quick 5-minute fix
- [SUPABASE_EMAIL_CONFIGURATION.md](SUPABASE_EMAIL_CONFIGURATION.md) - Detailed configuration
- [TROUBLESHOOTING_DEEP_LINKS.md](TROUBLESHOOTING_DEEP_LINKS.md) - Troubleshooting guide

---

**Last Updated:** 2026-01-28
**Version:** 1.0.0
**Issue:** Email opens browser instead of app
**Solution:** Update Supabase Site URL to deep link scheme
