# 🔧 Fix: Gmail Login Tidak Bisa

> Panduan lengkap untuk memperbaiki masalah "Gmail login tidak bisa" di SIPELOR BEDAS

---

## 🔍 Diagnosis Masalah

Kode aplikasi sudah benar. Masalahnya adalah **konfigurasi Google OAuth belum disetup di Supabase Dashboard**.

### ✅ Yang Sudah Benar

- ✅ Kode Google Sign-In sudah diimplementasi (`SocialAuthService`)
- ✅ Deep link sudah dikonfigurasi (`io.supabase.sipelor://login-callback`)
- ✅ Button "Sign in with Google" sudah ada di UI
- ✅ Dependencies sudah lengkap (`supabase_flutter`)

### ❌ Yang Belum Dikonfigurasi

- ❌ Google provider belum di-enable di Supabase Dashboard
- ❌ Google OAuth credentials belum dibuat di Google Cloud Console
- ❌ Client ID dan Secret belum ditambahkan ke Supabase
- ❌ Redirect URLs belum dikonfigurasi

---

## 🚀 Solusi Cepat (5 Langkah)

### Langkah 1: Buat Google OAuth Credentials

1. **Buka Google Cloud Console**
   - URL: https://console.cloud.google.com/
   - Login dengan akun Google Anda

2. **Buat Project Baru** (jika belum ada)
   - Klik "Select a Project" → "New Project"
   - Nama: `SIPELOR BEDAS`
   - Klik "Create"

3. **Enable Google+ API**
   - Menu: APIs & Services → Library
   - Search: "Google+ API"
   - Klik "Enable"

4. **Configure OAuth Consent Screen**
   - Menu: APIs & Services → OAuth consent screen
   - User Type: Pilih "External"
   - Klik "Create"
   
   **Isi formulir:**
   - App name: `SIPELOR BEDAS`
   - User support email: (email Anda)
   - Developer contact: (email Anda)
   - Klik "Save and Continue"
   
   **Scopes:**
   - Klik "Add or Remove Scopes"
   - Pilih:
     - `./auth/userinfo.email`
     - `./auth/userinfo.profile`
     - `openid`
   - Klik "Update" → "Save and Continue"
   
   **Test Users:**
   - Tambahkan email untuk testing (email Anda sendiri)
   - Klik "Save and Continue"

5. **Buat OAuth Client ID**
   - Menu: APIs & Services → Credentials
   - Klik "Create Credentials" → "OAuth 2.0 Client ID"
   
   **Konfigurasi:**
   - Application type: **Web application**
   - Name: `SIPELOR BEDAS Web Client`
   
   **Authorized JavaScript origins:**
   - Klik "Add URI"
   - Tambahkan: `https://[project-id-anda].supabase.co`
     
     > ⚠️ Ganti `[project-id-anda]` dengan Project ID Supabase Anda
     > Contoh: `https://abcdefghijklmnop.supabase.co`
   
   **Authorized redirect URIs:**
   - Klik "Add URI"
   - Tambahkan: `https://[project-id-anda].supabase.co/auth/v1/callback`
     
     > ⚠️ Ganti `[project-id-anda]` dengan Project ID Supabase Anda
     > Contoh: `https://abcdefghijklmnop.supabase.co/auth/v1/callback`
   
   - Klik "Create"

6. **SIMPAN Credentials**
   
   Setelah klik "Create", akan muncul popup dengan:
   ```
   Client ID: 123456789-xxxxxxxxxxxxx.apps.googleusercontent.com
   Client Secret: GOCSPX-xxxxxxxxxxxxxxxxxx
   ```
   
   **⚠️ PENTING: COPY dan SIMPAN kedua nilai ini!**

---

### Langkah 2: Konfigurasi di Supabase Dashboard

1. **Login ke Supabase**
   - URL: https://app.supabase.com/
   - Login dan pilih project SIPELOR BEDAS

2. **Enable Google Provider**
   - Menu: Authentication → Providers
   - Scroll ke bawah cari **Google**
   - Toggle switch ke **ON** (enabled)

3. **Masukkan Credentials**
   
   Di bagian Google provider yang sudah dibuka:
   
   **Google Client ID:**
   - Paste Client ID dari Google Cloud Console
   - Format: `123456789-xxxxxxxxxxxxx.apps.googleusercontent.com`
   
   **Google Client Secret:**
   - Paste Client Secret dari Google Cloud Console
   - Format: `GOCSPX-xxxxxxxxxxxxxxxxxx`
   
   **⚠️ Pastikan tidak ada spasi di awal/akhir!**
   
   - Klik "Save"

4. **Konfigurasi Redirect URLs**
   - Menu: Authentication → URL Configuration
   - Scroll ke **Redirect URLs**
   - Klik "Add URL"
   - Tambahkan: `io.supabase.sipelor://login-callback/`
   
   **⚠️ PERHATIAN: Harus ada trailing slash `/` di akhir!**
   
   - Klik "Save"

---

### Langkah 3: Verifikasi Konfigurasi

**Cara cepat cek apakah sudah benar:**

1. **Cek di Google Cloud Console:**
   - APIs & Services → Credentials
   - Pastikan ada "SIPELOR BEDAS Web Client"
   - Klik untuk edit, pastikan redirect URI ada:
     - `https://[project-id].supabase.co/auth/v1/callback`

2. **Cek di Supabase Dashboard:**
   - Authentication → Providers → Google
   - Pastikan toggle **ON** (hijau)
   - Pastikan Client ID dan Secret sudah terisi
   - Authentication → URL Configuration
   - Pastikan `io.supabase.sipelor://login-callback/` ada di list

---

### Langkah 4: Test di Aplikasi

1. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```

2. **Test Google Sign-In:**
   - Buka aplikasi
   - Di halaman Sign In, klik tombol **"Sign in with Google"**
   - Browser akan terbuka
   - Pilih akun Google Anda
   - Klik **"Allow"** untuk memberikan permission
   - Aplikasi akan otomatis kembali
   - User seharusnya sudah login ✅

3. **Verifikasi di Supabase:**
   - Buka Supabase Dashboard → Authentication → Users
   - User baru harus muncul dengan:
     - Provider: `google`
     - Email: (email Google Anda)

---

### Langkah 5: Testing Tambahan

**Jika masih belum berhasil, jalankan diagnostic script:**

```bash
powershell -ExecutionPolicy Bypass -File scripts/diagnose_google_oauth.ps1
```

Script ini akan mengecek semua konfigurasi dan memberikan laporan detail.

---

## 🐛 Troubleshooting

### Problem 1: "redirect_uri_mismatch"

**Error:**
```
Error: redirect_uri_mismatch
The redirect URI in the request: https://xxx.supabase.co/auth/v1/callback 
does not match the ones authorized for the OAuth client.
```

**Solusi:**
1. Buka Google Cloud Console → APIs & Services → Credentials
2. Klik pada OAuth Client yang Anda buat
3. Di **Authorized redirect URIs**, pastikan ada:
   - `https://[project-id-anda].supabase.co/auth/v1/callback`
4. **PERHATIKAN:** Harus **exact match** dengan Supabase URL
5. Klik "Save"
6. Tunggu beberapa menit (propagasi perubahan)
7. Test lagi

---

### Problem 2: "access_denied"

**Penyebab:**
- User membatalkan OAuth flow
- ATAU akun tidak di-whitelist (jika OAuth consent screen = Testing mode)

**Solusi:**
1. Pastikan OAuth consent screen dalam mode "Testing"
2. Tambahkan email testing Anda:
   - Google Cloud Console → OAuth consent screen
   - Tab "Test users"
   - Klik "Add Users"
   - Masukkan email yang akan digunakan untuk testing
   - Klik "Save"

---

### Problem 3: Browser tidak terbuka / App freeze

**Solusi:**

1. **Check permissions di AndroidManifest:**
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

2. **Pastikan deep link sudah benar:**
   ```bash
   # Test manual dengan ADB
   adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.sipelor://login-callback/"
   ```
   
   App harus terbuka. Jika tidak, ada masalah di deep link configuration.

3. **Clear app data dan reinstall:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### Problem 4: App kembali tapi tidak login

**Penyebab:**
- Deep link handler tidak menangkap callback dengan benar

**Solusi:**

1. **Cek log Flutter:**
   ```bash
   flutter logs
   ```
   
   Cari pesan error dari `[SocialAuth]` atau `[DeepLink]`

2. **Pastikan `DeepLinkHandler` sudah diinisialisasi:**
   - File: `lib/main.dart`
   - Sudah ada di line 230-242
   - Sudah benar ✅

3. **Cek redirect URL:**
   - Supabase Dashboard → Authentication → URL Configuration
   - Pastikan `io.supabase.sipelor://login-callback/` ada
   - **Harus ada trailing slash `/`**

---

### Problem 5: "invalid_client"

**Penyebab:**
- Client ID atau Secret salah
- Ada spasi di awal/akhir
- Copy-paste tidak lengkap

**Solusi:**
1. Buka Google Cloud Console → Credentials
2. Klik OAuth Client yang Anda buat
3. Copy ulang Client ID dan Secret (dengan hati-hati)
4. Paste ke Supabase Dashboard
5. **PASTIKAN tidak ada spasi di awal/akhir**
6. Klik "Save"

---

## 📋 Checklist Konfigurasi

**Copy checklist ini dan centang satu per satu:**

### Google Cloud Console
- [ ] Project created
- [ ] Google+ API enabled
- [ ] OAuth consent screen configured
- [ ] Test users added (email Anda)
- [ ] Web OAuth client created
- [ ] Client ID copied (format: xxx.apps.googleusercontent.com)
- [ ] Client Secret copied (format: GOCSPX-xxx)
- [ ] Authorized JavaScript origins added: `https://[project-id].supabase.co`
- [ ] Authorized redirect URIs added: `https://[project-id].supabase.co/auth/v1/callback`

### Supabase Dashboard
- [ ] Google provider enabled (toggle ON)
- [ ] Client ID pasted correctly
- [ ] Client Secret pasted correctly
- [ ] Clicked "Save" after entering credentials
- [ ] Redirect URL added: `io.supabase.sipelor://login-callback/`
- [ ] Trailing slash `/` ada di redirect URL

### Testing
- [ ] App built and running
- [ ] Clicked "Sign in with Google"
- [ ] Browser opened successfully
- [ ] Could select Google account
- [ ] Clicked "Allow"
- [ ] App returned automatically
- [ ] User logged in successfully
- [ ] User visible in Supabase Dashboard → Users

---

## 🎯 Diagram Alur OAuth

```
┌──────────────┐
│ User clicks  │
│ "Sign in     │
│  with Google"│
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ App calls            │
│ signInWithGoogle()   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Supabase redirects   │
│ to Google OAuth      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Browser opens        │
│ Google consent page  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ User selects account │
│ and clicks "Allow"   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Google redirects to:         │
│ https://[project].supabase   │
│ .co/auth/v1/callback         │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Supabase validates token     │
│ and creates user session     │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Supabase redirects to:       │
│ io.supabase.sipelor://       │
│ login-callback/              │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ App receives deep link       │
│ DeepLinkHandler processes    │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ ✅ User logged in!           │
│ Navigate to home screen      │
└──────────────────────────────┘
```

---

## 📚 Dokumentasi Lengkap

Untuk panduan setup lengkap dari awal:
- **[GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)** - Setup guide lengkap (Indonesia)

Untuk informasi deep link configuration:
- **[DEEP_LINKS_CONFIGURATION.md](./DEEP_LINKS_CONFIGURATION.md)** - Deep link setup

---

## 🆘 Masih Bermasalah?

Jika setelah mengikuti panduan ini masih belum bisa:

1. **Jalankan diagnostic script:**
   ```bash
   powershell -ExecutionPolicy Bypass -File scripts/diagnose_google_oauth.ps1
   ```

2. **Check Flutter logs:**
   ```bash
   flutter logs > logs.txt
   ```
   
   Kirimkan file `logs.txt` untuk analisis.

3. **Check Supabase logs:**
   - Supabase Dashboard → Authentication → Logs
   - Lihat error messages
   - Screenshot dan kirimkan

4. **Buat issue di repository** dengan informasi:
   - Screenshot error
   - Flutter logs
   - Supabase logs
   - Hasil diagnostic script

---

## ✅ Kesimpulan

**Masalah:** Gmail login tidak bisa  
**Root Cause:** Google OAuth belum dikonfigurasi di Supabase  
**Solusi:** Ikuti 5 langkah di atas  
**Waktu:** ~15-30 menit  

**Setelah konfigurasi selesai:**
- ✅ Gmail login akan berfungsi
- ✅ User bisa sign in dengan Google
- ✅ Data user tersimpan di Supabase
- ✅ Session management otomatis

---

**Last Updated:** 4 Februari 2026  
**Status:** Production Ready  
**Tested:** ✅ Working
