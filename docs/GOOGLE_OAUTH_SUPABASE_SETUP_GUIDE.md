# 🔐 Google OAuth Setup Guide untuk SIPELOR BEDAS

> **Panduan lengkap mengonfigurasi Google Sign-In dengan Supabase**
> 
> **Tanggal**: 2 Februari 2026  
> **Estimasi Waktu**: 30-45 menit  
> **Tingkat Kesulitan**: Mudah-Sedang

---

## 📋 Prerequisites

Sebelum memulai, pastikan Anda memiliki:

- ✅ Akun Google (Gmail)
- ✅ Akses ke Supabase Dashboard (project SIPELOR BEDAS)
- ✅ Hak akses untuk create project di Google Cloud Console
- ✅ Project Flutter sudah running di local

---

## 🎯 Overview Proses

Setup Google OAuth memerlukan 3 tahap utama:

```
1. Google Cloud Console Setup (15 menit)
   → Create OAuth Client IDs
   
2. Supabase Dashboard Configuration (5 menit)
   → Enable Google Provider & add Client IDs
   
3. Testing & Verification (10 menit)
   → Test login flow
```

**Total Time**: ~30-45 menit

---

## 📝 TAHAP 1: Google Cloud Console Setup

### Step 1.1: Buat Google Cloud Project

1. **Buka Google Cloud Console**
   - URL: https://console.cloud.google.com/
   - Login dengan akun Google Anda

2. **Create New Project**
   - Click **"Select a project"** di top bar
   - Click **"NEW PROJECT"**
   - Isi form:
     ```
     Project Name: SIPELOR BEDAS
     Organization: (leave default atau pilih org Anda)
     Location: (leave default)
     ```
   - Click **"CREATE"**
   - Tunggu project dibuat (~30 detik)

3. **Select Project**
   - Pastikan project "SIPELOR BEDAS" sudah selected di top bar

---

### Step 1.2: Enable Google+ API (Optional tapi Recommended)

1. **Buka API Library**
   - Left menu → **"APIs & Services"** → **"Library"**
   - Atau buka: https://console.cloud.google.com/apis/library

2. **Search & Enable Google+ API**
   - Search box: ketik **"Google+ API"**
   - Click **"Google+ API"**
   - Click **"ENABLE"**
   - Tunggu enabled (~10 detik)

> **Note**: Google+ API diperlukan untuk mendapatkan profile info user (nama, foto, email)

---

### Step 1.3: Configure OAuth Consent Screen

1. **Buka OAuth Consent Screen**
   - Left menu → **"APIs & Services"** → **"OAuth consent screen"**
   - Atau buka: https://console.cloud.google.com/apis/credentials/consent

2. **Pilih User Type**
   - **Pilih "External"** (untuk public app)
   - Click **"CREATE"**

3. **Fill OAuth Consent Screen - Page 1 (App Information)**
   ```
   App name: SIPELOR BEDAS
   User support email: [pilih email Anda dari dropdown]
   App logo: [optional - upload logo jika ada]
   Application home page: [leave blank untuk sekarang]
   Application privacy policy: [leave blank untuk sekarang]
   Application terms of service: [leave blank untuk sekarang]
   Authorized domains: [leave blank untuk sekarang]
   Developer contact information: [masukkan email Anda]
   ```
   - Click **"SAVE AND CONTINUE"**

4. **Page 2 (Scopes)**
   - Click **"ADD OR REMOVE SCOPES"**
   - Pilih scopes berikut:
     - ✅ `../auth/userinfo.email`
     - ✅ `../auth/userinfo.profile`
     - ✅ `openid`
   - Click **"UPDATE"**
   - Click **"SAVE AND CONTINUE"**

5. **Page 3 (Test Users)** - Optional
   - Jika masih development, tambahkan test users:
   - Click **"ADD USERS"**
   - Masukkan email untuk testing
   - Click **"ADD"**
   - Click **"SAVE AND CONTINUE"**

6. **Page 4 (Summary)**
   - Review semua info
   - Click **"BACK TO DASHBOARD"**

---

### Step 1.4: Create OAuth 2.0 Client IDs

#### A. Web Client ID (untuk Supabase)

1. **Buka Credentials Page**
   - Left menu → **"APIs & Services"** → **"Credentials"**
   - Atau buka: https://console.cloud.google.com/apis/credentials

2. **Create Web Client Credentials**
   - Click **"+ CREATE CREDENTIALS"** (top)
   - Select **"OAuth client ID"**

3. **Fill Web Application Form**
   ```
   Application type: Web application
   Name: SIPELOR BEDAS - Web Client
   
   Authorized JavaScript origins: [leave empty]
   
   Authorized redirect URIs:
   → Click "ADD URI"
   → Paste: https://[YOUR-SUPABASE-PROJECT-REF].supabase.co/auth/v1/callback
   ```

   **⚠️ PENTING: Cara mendapatkan Supabase Project URL:**
   - Buka Supabase Dashboard: https://supabase.com/dashboard
   - Pilih project SIPELOR BEDAS
   - Di sidebar, click **"Project Settings"** (gear icon)
   - Click **"API"** tab
   - Copy **"Project URL"** (misal: `https://abcdefghijklmnop.supabase.co`)
   - Tambahkan `/auth/v1/callback` di akhir
   - Contoh: `https://abcdefghijklmnop.supabase.co/auth/v1/callback`

4. **Create Credentials**
   - Click **"CREATE"**
   - **SIMPAN** credentials yang muncul:
     ```
     Client ID: [copy ini - seperti: 123456789-abcdefg.apps.googleusercontent.com]
     Client Secret: [copy ini - seperti: GOCSPX-abcdefg123456]
     ```
   - Click **"OK"**

5. **Save Credentials**
   - ⚠️ **SANGAT PENTING**: Simpan Client ID & Client Secret ini
   - Paste ke notepad/text file sementara
   - Anda akan memerlukannya untuk Supabase

---

#### B. Android Client ID (untuk Flutter App - Android)

1. **Create Android Credentials**
   - Di Credentials page, click **"+ CREATE CREDENTIALS"** lagi
   - Select **"OAuth client ID"**

2. **Fill Android Application Form**
   ```
   Application type: Android
   Name: SIPELOR BEDAS - Android
   ```

3. **Get Package Name & SHA-1**
   
   **Package Name**:
   - Buka file: `android/app/build.gradle`
   - Cari `applicationId` (biasanya line ~50)
   - Copy value-nya (misal: `com.dispora.sipelor`)

   **SHA-1 Certificate Fingerprint**:
   
   **Untuk Debug (Development)**:
   - Buka Terminal/PowerShell
   - Jalankan command:
   
   **Windows (PowerShell)**:
   ```powershell
   cd android
   .\gradlew signingReport
   ```
   
   **Mac/Linux**:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
   - Tunggu selesai (~30-60 detik)
   - Scroll up, cari **"Variant: debug"**
   - Copy **SHA1** fingerprint (40 karakter hex, misal: `AB:CD:EF:12:34:56:...`)

   **Untuk Release (Production)** - Optional untuk sekarang:
   - Gunakan SHA-1 dari keystore production Anda
   - File: `android/key.properties`
   - Command:
   ```powershell
   keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
   ```

4. **Fill Android Form**
   ```
   Package name: com.dispora.sipelor [atau sesuai applicationId Anda]
   SHA-1 certificate fingerprint: [paste SHA-1 dari gradlew signingReport]
   ```
   - Click **"CREATE"**
   - Client ID akan muncul (tidak ada secret untuk Android)
   - Click **"OK"**

---

#### C. iOS Client ID (Optional - jika target iOS)

**Skip untuk sekarang jika hanya fokus Android dulu**

Jika butuh iOS:

1. **Create iOS Credentials**
   - Click **"+ CREATE CREDENTIALS"**
   - Select **"OAuth client ID"**
   - Application type: **iOS**

2. **Fill iOS Form**
   ```
   Name: SIPELOR BEDAS - iOS
   Bundle ID: [dari ios/Runner/Info.plist, cari CFBundleIdentifier]
   App Store ID: [leave empty jika belum di App Store]
   ```
   - Click **"CREATE"**

---

### Step 1.5: Download Configuration (Optional)

1. **Download JSON**
   - Di Credentials page
   - Di section **"OAuth 2.0 Client IDs"**
   - Find "SIPELOR BEDAS - Web Client"
   - Click ⋮ (three dots) → **"Download JSON"**
   - Simpan file sebagai `google-oauth-credentials.json`
   - **JANGAN commit ke Git!** (add ke .gitignore)

---

## 🔧 TAHAP 2: Supabase Dashboard Configuration

### Step 2.1: Enable Google Provider

1. **Buka Supabase Dashboard**
   - URL: https://supabase.com/dashboard
   - Login ke account Anda
   - Pilih project **SIPELOR BEDAS**

2. **Navigate ke Authentication Settings**
   - Left sidebar → Click **"Authentication"** (🔐 icon)
   - Click **"Providers"** tab
   - Atau direct URL: `https://supabase.com/dashboard/project/[PROJECT-ID]/auth/providers`

3. **Find Google Provider**
   - Scroll ke **"Auth Providers"** section
   - Find **"Google"** dalam list
   - Click **"Google"** card

---

### Step 2.2: Configure Google OAuth

1. **Enable Provider**
   - Toggle **"Enable Sign in with Google"** → **ON** (hijau)

2. **Fill Configuration**
   ```
   Client ID (for OAuth): 
   → Paste Client ID dari Google Cloud Console Web Client
   → Misal: 123456789-abcdefghijk.apps.googleusercontent.com
   
   Client Secret (for OAuth):
   → Paste Client Secret dari Google Cloud Console
   → Misal: GOCSPX-abc123def456
   ```

3. **Authorized Client IDs (Optional tapi Recommended)**
   
   Tambahkan Android Client ID jika sudah create:
   - Click **"Add a new authorized client id"**
   - Paste Android Client ID
   - Click **"Add"**

4. **Save Configuration**
   - Scroll ke bottom
   - Click **"Save"** button (hijau)
   - Tunggu saved (~2 detik)

---

### Step 2.3: Verify Callback URL

1. **Check Callback URL**
   - Di Google Provider settings page
   - Akan ada info box dengan text:
     ```
     Callback URL (for OAuth):
     https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback
     ```
   - **Copy URL ini**

2. **Verify di Google Cloud Console**
   - Kembali ke Google Cloud Console
   - APIs & Services → Credentials
   - Click "SIPELOR BEDAS - Web Client"
   - Check **"Authorized redirect URIs"**
   - Pastikan URL match dengan Supabase callback URL
   - Jika tidak match, edit dan tambahkan yang benar
   - Click **"SAVE"**

---

## 💻 TAHAP 3: Flutter App Configuration

### Step 3.1: Update Android Configuration

1. **Download google-services.json (Recommended)**

   Meskipun bukan wajib, ini recommended untuk Android:

   a. **Di Google Cloud Console**
      - Buka: https://console.firebase.google.com/
      - Jika belum ada Firebase project:
        - Click **"Add project"**
        - Select existing Google Cloud project "SIPELOR BEDAS"
        - Follow wizard
      - Di Firebase Console:
        - Click ⚙️ → **"Project settings"**
        - Scroll ke **"Your apps"**
        - Click **Android icon** atau **"Add app"**
        - Package name: `com.dispora.sipelor`
        - Download `google-services.json`

   b. **Copy ke Project**
      ```
      android/app/google-services.json
      ```

2. **Update AndroidManifest.xml**

   File: `android/app/src/main/AndroidManifest.xml`

   Tambahkan di dalam `<application>` tag:

   ```xml
   <!-- Deep Link untuk Google OAuth -->
   <activity
       android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
       android:exported="true">
       <intent-filter android:label="flutter_web_auth_2">
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="https" android:host="[YOUR-PROJECT-REF].supabase.co" />
       </intent-filter>
   </activity>
   ```

   **Replace `[YOUR-PROJECT-REF]`** dengan project ref Supabase Anda

---

### Step 3.2: Verify Service Code

1. **Check Social Auth Service**
   
   File: `lib/services/social_auth_service.dart`
   
   Service ini sudah ada di project Anda. Verify contains:
   ```dart
   // Sign in with Google
   Future<AuthResponse> signInWithGoogle() async {
     return await _supabase.auth.signInWithOAuth(
       OAuthProvider.google,
       redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
     );
   }
   ```

2. **Check jika sudah terintegrasi di Sign In Screen**
   
   File: `lib/screens/auth/sign_in_screen.dart`
   
   Cari apakah sudah ada Google Sign-In button. Jika belum, perlu ditambahkan.

---

### Step 3.3: Add Google Sign-In Button (jika belum ada)

Jika button belum ada, update `sign_in_screen.dart`:

1. **Import Service**
   ```dart
   import '../services/social_auth_service.dart';
   ```

2. **Add Button di UI**
   
   Tambahkan setelah sign-in button biasa:
   
   ```dart
   const SizedBox(height: 16),
   
   // Divider
   Row(
     children: [
       Expanded(child: Divider()),
       Padding(
         padding: EdgeInsets.symmetric(horizontal: 16),
         child: Text('atau', style: TextStyle(color: Colors.grey)),
       ),
       Expanded(child: Divider()),
     ],
   ),
   
   const SizedBox(height: 16),
   
   // Google Sign-In Button
   ElevatedButton.icon(
     onPressed: _isLoading ? null : _signInWithGoogle,
     icon: Image.asset(
       'assets/images/google_logo.png', // atau gunakan Icon
       height: 24,
       width: 24,
     ),
     label: Text('Continue with Google'),
     style: ElevatedButton.styleFrom(
       backgroundColor: Colors.white,
       foregroundColor: Colors.black87,
       minimumSize: Size(double.infinity, 50),
       side: BorderSide(color: Colors.grey.shade300),
     ),
   ),
   ```

3. **Add Sign-In Method**
   
   ```dart
   final _socialAuth = SocialAuthService();
   
   Future<void> _signInWithGoogle() async {
     setState(() => _isLoading = true);
     
     try {
       final response = await _socialAuth.signInWithGoogle();
       
       if (response.session != null) {
         // Login success
         if (mounted) {
           Navigator.of(context).pushReplacementNamed('/home');
         }
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Google Sign-In failed: $e')),
         );
       }
     } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
     }
   }
   ```

---

### Step 3.4: Add Google Logo Asset (Optional)

Jika ingin logo Google di button:

1. **Download Google Logo**
   - Gunakan official Google logo: https://developers.google.com/identity/branding-guidelines
   - Atau cari "google logo png transparent" di Google Images

2. **Add to Assets**
   ```
   assets/images/google_logo.png
   ```

3. **Update pubspec.yaml** (sudah ada, tinggal verify)
   ```yaml
   assets:
     - assets/images/
   ```

---

## 🧪 TAHAP 4: Testing

### Step 4.1: Test di Development

1. **Run App**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Google Sign-In**
   - Buka app
   - Navigate ke Sign-In screen
   - Click **"Continue with Google"** button
   - Browser akan terbuka
   - Select Google account
   - Click **"Continue"** atau **"Allow"**
   - App akan redirect kembali
   - User harus login dan redirect ke home screen

3. **Verify di Supabase**
   - Buka Supabase Dashboard
   - Authentication → Users
   - User baru harus muncul dengan provider **"google"**
   - Email dan nama dari Google account

---

### Step 4.2: Common Issues & Solutions

#### ❌ Issue 1: "Error 400: redirect_uri_mismatch"

**Penyebab**: Redirect URI di Google Cloud Console tidak match dengan Supabase

**Solusi**:
1. Check error message untuk redirect URI yang diminta
2. Copy exact URL dari error
3. Buka Google Cloud Console → Credentials
4. Edit Web Client
5. Add exact URL ke "Authorized redirect URIs"
6. Save dan retry

---

#### ❌ Issue 2: "The OAuth client was not found"

**Penyebab**: Client ID atau Client Secret salah

**Solusi**:
1. Verify Client ID di Supabase Dashboard
2. Copy ulang dari Google Cloud Console
3. Pastikan tidak ada extra spaces
4. Save dan retry

---

#### ❌ Issue 3: Browser tidak buka atau stuck

**Penyebab**: Deep link configuration salah

**Solusi**:
1. Check AndroidManifest.xml
2. Pastikan scheme dan host benar
3. Rebuild app:
   ```powershell
   flutter clean
   flutter run
   ```

---

#### ❌ Issue 4: "Access blocked: This app's request is invalid"

**Penyebab**: OAuth Consent Screen tidak configured properly

**Solusi**:
1. Kembali ke Google Cloud Console
2. OAuth Consent Screen → Edit App
3. Pastikan semua required fields filled
4. Add test users jika masih development
5. Publish app jika sudah production ready

---

### Step 4.3: Testing Checklist

- [ ] Google Sign-In button visible di sign-in screen
- [ ] Clicking button membuka browser/web view
- [ ] Google account selection screen muncul
- [ ] Setelah select account, redirect ke app
- [ ] User data (email, nama) tersimpan di Supabase
- [ ] User redirect ke home screen setelah login
- [ ] Sign out dan sign in ulang dengan Google works
- [ ] Profile picture dari Google muncul (jika implemented)

---

## 📋 Summary Checklist

### Google Cloud Console ✅
- [ ] Project created
- [ ] OAuth Consent Screen configured
- [ ] Web Client ID created
- [ ] Client ID & Secret saved
- [ ] Redirect URI configured
- [ ] Android Client ID created (optional)
- [ ] iOS Client ID created (optional)

### Supabase Dashboard ✅
- [ ] Google Provider enabled
- [ ] Client ID configured
- [ ] Client Secret configured
- [ ] Callback URL verified

### Flutter App ✅
- [ ] AndroidManifest.xml updated
- [ ] Social Auth Service verified
- [ ] Google Sign-In button added
- [ ] Sign-in method implemented
- [ ] Google logo added (optional)

### Testing ✅
- [ ] Development testing passed
- [ ] User created in Supabase
- [ ] Login flow smooth
- [ ] No errors in console

---

## 🎯 Next Steps

Setelah Google OAuth working:

1. **Add Apple Sign-In** (WAJIB untuk iOS App Store)
   - Similar process di Apple Developer Console
   - Configure di Supabase
   - Update iOS configuration

2. **Implement Account Linking**
   - Handle case: user sign-up dengan email, lalu login dengan Google (email sama)
   - Merge accounts atau show error

3. **Add Social Sign-Up Screen**
   - Separate screen untuk first-time Google users
   - Collect additional info jika perlu (phone number, dll)

4. **Update Privacy Policy**
   - Mention Google OAuth dalam privacy policy
   - Update consent screen URLs

---

## 📞 Troubleshooting Resources

**Jika masih ada masalah:**

1. **Supabase Docs**
   - https://supabase.com/docs/guides/auth/social-login/auth-google

2. **Google OAuth Docs**
   - https://developers.google.com/identity/protocols/oauth2

3. **Flutter Supabase Docs**
   - https://supabase.com/docs/reference/dart/auth-signinwithoauth

4. **Check Logs**
   - Flutter console untuk errors
   - Supabase Dashboard → Logs → Auth Logs
   - Google Cloud Console → Logs

---

## ✅ Configuration Complete!

Setelah semua steps selesai:

**Estimasi Total Waktu**: 30-45 menit  
**Tingkat Kesulitan**: ⭐⭐⭐☆☆ (3/5 - Sedang)  
**Status**: ✅ Production Ready setelah testing

---

**Prepared By**: Development Team  
**Date**: 2 Februari 2026  
**Version**: 1.0  
**Status**: Complete Guide

**Good luck dengan Google OAuth setup! 🚀**

---

## 📎 Appendix: Quick Commands Reference

### PowerShell Commands (Windows)

```powershell
# Get Android SHA-1 fingerprint
cd android
.\gradlew signingReport

# Clean & rebuild
flutter clean
flutter pub get
flutter run

# Check package name
type android\app\build.gradle | findstr applicationId
```

### Bash Commands (Mac/Linux)

```bash
# Get Android SHA-1 fingerprint
cd android
./gradlew signingReport

# Clean & rebuild
flutter clean
flutter pub get
flutter run

# Check package name
grep applicationId android/app/build.gradle
```

---

**Happy Coding! 🎉**
