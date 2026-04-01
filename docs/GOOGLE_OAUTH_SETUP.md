# Google OAuth Setup Guide

> Step-by-step guide untuk mengkonfigurasi Google OAuth di SIPELOR BEDAS

---

## 📋 Prerequisites

- Akses ke Google Cloud Console
- Akses ke Supabase Dashboard
- Project SIPELOR BEDAS sudah ter-deploy

---

## 🔧 Step 1: Google Cloud Console Setup

### 1.1 Create Project (jika belum ada)

1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Klik **Select a Project** → **New Project**
3. Nama project: `SIPELOR BEDAS`
4. Klik **Create**

### 1.2 Enable Google+ API

1. Di Google Cloud Console, pilih project Anda
2. Buka **APIs & Services** → **Library**
3. Cari "Google+ API"
4. Klik **Enable**

### 1.3 Configure OAuth Consent Screen

1. Buka **APIs & Services** → **OAuth consent screen**
2. Pilih **External** (untuk testing) atau **Internal** (untuk organisasi)
3. Klik **Create**

**App Information**:
- App name: `SIPELOR BEDAS`
- User support email: `support@sipelor.app`
- App logo: Upload logo aplikasi (opsional)

**App Domain**:
- Application home page: `https://sipelor.app`
- Privacy policy: `https://sipelor.app/privacy`
- Terms of service: `https://sipelor.app/terms`

**Developer Contact**:
- Email: `dev@sipelor.app`

4. Klik **Save and Continue**

**Scopes**:
- Tambahkan scopes:
  - `./auth/userinfo.email`
  - `./auth/userinfo.profile`
  - `openid`
5. Klik **Save and Continue**

**Test Users** (jika External):
- Tambahkan email untuk testing
6. Klik **Save and Continue**

### 1.4 Create OAuth Credentials

1. Buka **APIs & Services** → **Credentials**
2. Klik **Create Credentials** → **OAuth 2.0 Client ID**

**Application Type**:
- Pilih: **Web application**

**Name**:
- Nama: `SIPELOR BEDAS Web Client`

**Authorized JavaScript origins**:
- Tambahkan:
  - `https://[your-project-ref].supabase.co`
  - `http://localhost:3000` (untuk testing)

**Authorized redirect URIs**:
- Tambahkan:
  - `https://[your-project-ref].supabase.co/auth/v1/callback`
  - `http://localhost:54321/auth/v1/callback` (untuk local development)

3. Klik **Create**

4. **SIMPAN** Client ID dan Client Secret yang ditampilkan
   ```
   Client ID: 123456789-abc.apps.googleusercontent.com
   Client Secret: GOCSPX-xxxxxxxxxxxx
   ```

### 1.5 Create Android OAuth Credentials (untuk mobile app)

1. Di **Credentials**, klik **Create Credentials** → **OAuth 2.0 Client ID**
2. **Application Type**: **Android**
3. **Name**: `SIPELOR BEDAS Android`
4. **Package name**: `com.dispora.sipelor` (sesuaikan)
5. **SHA-1 Certificate fingerprint**:

**Debug Certificate**:
```bash
# Windows (PowerShell)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Linux/Mac
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release Certificate**:
```bash
# Dari keystore Anda
keytool -list -v -keystore path/to/your/keystore.jks -alias your_alias
```

6. Copy SHA-1 fingerprint dan paste ke form
7. Klik **Create**

### 1.6 Create iOS OAuth Credentials (jika ada iOS app)

1. Di **Credentials**, klik **Create Credentials** → **OAuth 2.0 Client ID**
2. **Application Type**: **iOS**
3. **Name**: `SIPELOR BEDAS iOS`
4. **Bundle ID**: `com.dispora.sipelor` (sesuaikan)
5. Klik **Create**

---

## 🔐 Step 2: Supabase Configuration

### 2.1 Enable Google Provider

1. Buka [Supabase Dashboard](https://app.supabase.com/)
2. Pilih project SIPELOR BEDAS
3. Buka **Authentication** → **Providers**
4. Scroll ke **Google**
5. Toggle **Enable Google provider** ke ON

### 2.2 Configure Google OAuth

**Google Client ID**:
- Paste Client ID dari Google Cloud Console (Web Client)
- Format: `123456789-abc.apps.googleusercontent.com`

**Google Client Secret**:
- Paste Client Secret dari Google Cloud Console
- Format: `GOCSPX-xxxxxxxxxxxx`

**Authorized Client IDs** (untuk mobile):
- Paste Android Client ID
- Format: `123456789-def.apps.googleusercontent.com`
- Jika ada iOS, tambahkan juga iOS Client ID

6. Klik **Save**

### 2.3 Configure Redirect URLs

1. Di Supabase, buka **Authentication** → **URL Configuration**
2. **Site URL**: `https://sipelor.app` (production URL)
3. **Redirect URLs**:
   - Tambahkan: `io.supabase.sipelor://login-callback/`
   - Tambahkan: `https://sipelor.app/auth/callback` (untuk web)

---

## 📱 Step 3: Flutter App Configuration

### 3.1 Android Configuration

**File**: `android/app/src/main/AndroidManifest.xml`

Tambahkan di dalam `<activity>` tag:

```xml
<activity
    android:name=".MainActivity"
    ...>
    
    <!-- Existing intent filters -->
    ...
    
    <!-- OAuth Deep Link -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="io.supabase.sipelor"
            android:host="login-callback" />
    </intent-filter>
</activity>
```

### 3.2 iOS Configuration

**File**: `ios/Runner/Info.plist`

Tambahkan sebelum tag `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>io.supabase.sipelor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.sipelor</string>
        </array>
    </dict>
</array>
```

### 3.3 Rebuild App

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

---

## ✅ Step 4: Testing

### 4.1 Test di Emulator/Device

1. Jalankan aplikasi
2. Di sign-in screen, klik tombol "Sign in with Google"
3. Browser akan terbuka dengan Google OAuth consent screen
4. Pilih akun Google
5. Klik **Allow** untuk memberikan permission
6. Aplikasi akan otomatis kembali dan user ter-login

### 4.2 Verify di Supabase

1. Buka Supabase Dashboard → **Authentication** → **Users**
2. User baru harus muncul dengan provider: `google`
3. Check user metadata untuk Google profile info

### 4.3 Troubleshooting

**Problem**: "redirect_uri_mismatch"
- **Solution**: 
  - Pastikan redirect URI di Google Console match dengan Supabase
  - Format harus: `https://[project-ref].supabase.co/auth/v1/callback`

**Problem**: "invalid_client"
- **Solution**:
  - Verify Client ID dan Secret benar
  - Pastikan tidak ada trailing spaces

**Problem**: App tidak kembali setelah OAuth
- **Solution**:
  - Check deep link configuration
  - Verify scheme: `io.supabase.sipelor`
  - Test deep link: `adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.sipelor://login-callback/"`

**Problem**: "access_denied"
- **Solution**:
  - User membatalkan OAuth flow
  - Atau akun tidak di-whitelist (jika OAuth consent screen = Testing)

---

## 🔒 Security Best Practices

1. **Never commit credentials to git**:
   - Client ID aman untuk commit
   - Client Secret JANGAN di-commit
   - Gunakan environment variables

2. **Rotate secrets regularly**:
   - Update Client Secret setiap 6 bulan
   - Update di Google Console dan Supabase

3. **Monitor OAuth usage**:
   - Check Google Cloud Console → **APIs & Services** → **Credentials**
   - Monitor quota dan rate limits

4. **Restrict authorized domains**:
   - Hanya tambahkan domain production
   - Hapus localhost setelah development

---

## 📊 Monitoring

### Google Cloud Console

- **APIs & Services** → **Dashboard**
  - Monitor API calls
  - Check quota usage
  - View error rates

### Supabase Dashboard

- **Authentication** → **Logs**
  - Monitor sign-in attempts
  - Check for errors
  - View OAuth flow details

---

## 🆘 Support

Jika mengalami masalah:

1. **Check Logs**:
   - Flutter: `flutter logs`
   - Supabase: Authentication Logs
   - Google: Cloud Console Logs

2. **Documentation**:
   - [Google OAuth Docs](https://developers.google.com/identity/protocols/oauth2)
   - [Supabase Auth Docs](https://supabase.com/docs/guides/auth)

3. **Contact**:
   - Technical: dev@sipelor.app
   - Security: security@sipelor.app

---

## ✅ Checklist

Setup selesai jika:

- [ ] Google Cloud project created
- [ ] Google+ API enabled
- [ ] OAuth consent screen configured
- [ ] Web OAuth credentials created (Client ID + Secret)
- [ ] Android OAuth credentials created (optional)
- [ ] Supabase Google provider enabled
- [ ] Client ID & Secret configured di Supabase
- [ ] Redirect URLs configured
- [ ] Deep link configured di AndroidManifest.xml
- [ ] Deep link configured di Info.plist (iOS)
- [ ] App tested dan user bisa login with Google
- [ ] User data verified di Supabase

---

**Last Updated**: 26 January 2026  
**Status**: Production Ready
