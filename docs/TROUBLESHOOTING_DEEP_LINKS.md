# 🔧 Troubleshooting Deep Links

Panduan troubleshooting untuk masalah deep link di aplikasi SIPELOR.

## 🐛 Masalah Umum

### 1. Layar Blank Hitam Setelah Klik Link di Email

**Gejala:**
- Klik button "Reset Password" atau "Verify Email" di email
- Aplikasi terbuka
- Layar hitam atau blank muncul
- Tidak ada UI yang ditampilkan

**Penyebab:**
1. Session dari deep link belum ter-set sebelum navigate ke screen
2. Navigation terjadi terlalu cepat sebelum MaterialApp siap
3. Context yang digunakan untuk navigation tidak valid
4. Route tidak terdaftar atau ada error di screen target

**Solusi:**
✅ Sudah diperbaiki di versi terbaru dengan:
- Menambahkan `navigatorKey` di MaterialApp
- Menambahkan delay kecil sebelum navigation (300ms)
- Menambahkan session validation di ResetPasswordScreen
- Menambahkan loading state dan error handling

**Testing:**
```bash
# Test di Android (command line)
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password?access_token=xxx&refresh_token=xxx&type=recovery"
```

---

### 2. App Tidak Terbuka Saat Klik Link

**Gejala:**
- Klik link di email
- Browser terbuka (atau tidak terjadi apa-apa)
- App tidak terbuka

**Penyebab:**
- Deep link scheme tidak terkonfigurasi dengan benar
- App belum ter-install
- Deep link scheme tidak match dengan yang di Supabase

**Solusi:**

#### Android
1. **Verify AndroidManifest.xml:**
   ```xml
   <intent-filter android:autoVerify="true">
       <action android:name="android.intent.action.VIEW"/>
       <category android:name="android.intent.category.DEFAULT"/>
       <category android:name="android.intent.category.BROWSABLE"/>
       
       <data android:scheme="sipelor" android:host="callback" />
       <data android:scheme="sipelor" android:host="reset-password" />
   </intent-filter>
   ```

2. **Test deep link:**
   ```bash
   # Test apakah deep link ter-register
   adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
   ```

3. **Check logcat:**
   ```bash
   adb logcat | grep -i "deep\|sipelor\|intent"
   ```

#### iOS
1. **Verify Info.plist:**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>sipelor</string>
           </array>
       </dict>
   </array>
   ```

2. **Test dengan Safari:**
   - Buka Safari
   - Ketik di address bar: `sipelor://reset-password`
   - App harus terbuka

---

### 3. "Invalid Redirect URL" Error

**Gejala:**
- Email diterima
- Klik link di email
- Error: "Invalid redirect URL"

**Penyebab:**
- URL redirect tidak terdaftar di Supabase

**Solusi:**
1. Buka Supabase Dashboard
2. Masuk ke: **Authentication** → **URL Configuration**
3. Pastikan URL berikut ada di **Redirect URLs**:
   ```
   sipelor://callback
   sipelor://reset-password
   sipelor://auth/callback
   io.supabase.sipelor://login-callback
   ```
4. Klik **Save**

---

### 4. Link Expired

**Gejala:**
- Klik link di email (setelah beberapa waktu)
- Error: "Link expired" atau "Link tidak valid"

**Penyebab:**
- Email verification: Valid 24 jam
- Password reset: Valid 1 jam (default)
- Link sudah pernah digunakan (one-time use)

**Solusi:**
1. Minta kirim ulang email
2. Gunakan link baru yang dikirim
3. Jangan delay, langsung klik setelah email diterima

**Untuk Development:**
Jika perlu extend expiry time, ubah di Supabase Dashboard:
- **Authentication** → **Email Templates**
- Ubah `{{ .ExpirationTime }}` variable

---

### 5. Deep Link Tidak Ke-detect di App

**Gejala:**
- App terbuka
- Tapi tidak navigate ke screen yang seharusnya
- Stuck di splash screen atau home screen

**Penyebab:**
- Deep link handler tidak ter-initialize
- Link diterima sebelum app siap
- Error di deep link parsing

**Solusi:**

1. **Check Flutter console untuk errors:**
   ```bash
   flutter run
   # Atau
   flutter logs
   ```

2. **Enable debug print di deep_link_handler.dart:**
   Sudah ada debug logs, check console untuk:
   ```
   🔗 Deep link received: ...
   🔐 Auth callback - Type: ...
   🔑 Password reset callback
   ✅ Session set successfully
   ```

3. **Test dengan deep link manual:**
   ```bash
   # Android
   adb shell am start -W -a android.intent.action.VIEW \
     -d "sipelor://reset-password?access_token=test&type=recovery"
   ```

---

### 6. Session Tidak Valid Setelah Deep Link

**Gejala:**
- App terbuka dari deep link
- User diminta login lagi
- Session tidak tersimpan

**Penyebab:**
- `getSessionFromUrl()` gagal
- Token di URL tidak valid
- Network error saat verify token

**Solusi:**

1. **Check debug logs:**
   ```
   ✅ Password reset session set
      User ID: xxx-xxx-xxx
   ```

2. **Verify Supabase connection:**
   - Pastikan ada internet
   - Pastikan Supabase URL dan Key valid
   - Check Supabase dashboard logs

3. **Test dengan token baru:**
   - Jangan gunakan link lama
   - Kirim ulang email
   - Gunakan link fresh

---

## 🧪 Testing Deep Links

### Manual Testing

#### Test Email Verification
1. Signup dengan email baru
2. Check email inbox
3. Klik "Verify Email"
4. ✅ App terbuka → Show success → Navigate to home

#### Test Password Reset
1. Klik "Lupa Password"
2. Input email → Submit
3. Check email inbox
4. Klik "Reset Password"
5. ✅ App terbuka → Show reset form
6. Input password baru → Submit
7. ✅ Success → Navigate to home
8. ✅ Login dengan password baru berhasil

### Automated Testing (Android)

Gunakan script test:

```bash
# File: scripts/test_deep_links.sh

#!/bin/bash

echo "🧪 Testing Deep Links for SIPELOR"
echo ""

# Test 1: Basic deep link
echo "1️⃣  Testing basic deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://callback"
sleep 2

# Test 2: Reset password
echo "2️⃣  Testing reset password deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
sleep 2

# Test 3: Auth callback
echo "3️⃣  Testing auth callback deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://auth/callback"
sleep 2

echo ""
echo "✅ All tests completed!"
echo "Check app and console for results"
```

Run:
```bash
chmod +x scripts/test_deep_links.sh
./scripts/test_deep_links.sh
```

### Debug Logs Checklist

When testing, check for these logs:

```
✅ Expected logs:
[✓] 🔗 Deep link received: sipelor://...
[✓] 🔐 Auth callback - Type: recovery
[✓] ✅ Password reset session set
[✓] 🔍 Checking session for password reset...
[✓] ✅ Valid session found for user: xxx

❌ Error logs to watch:
[X] ❌ No session returned from URL
[X] ❌ Error handling deep link: ...
[X] ❌ No valid session found
[X] ❌ Error in password reset: ...
```

---

## 🔍 Diagnostic Commands

### Android

```bash
# Check if deep link is registered
adb shell dumpsys package | grep -A 5 sipelor

# Test deep link
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"

# Monitor logs
adb logcat | grep -E "Deep|sipelor|Flutter"

# Check app package
adb shell pm list packages | grep sipelor

# Clear app data (reset state)
adb shell pm clear com.sipelor.app
```

### iOS

```bash
# Use Xcode console to monitor deep links
# Logs will show in Xcode console when running on simulator/device

# Or use Terminal (if device connected)
idevicesyslog | grep -i sipelor
```

---

## 📋 Pre-flight Checklist

Before testing deep links:

- [ ] App installed on device
- [ ] Internet connection available
- [ ] Supabase credentials configured
- [ ] Site URL configured in Supabase (not localhost)
- [ ] Redirect URLs added in Supabase
- [ ] AndroidManifest.xml has intent filters (Android)
- [ ] Info.plist has URL schemes (iOS)
- [ ] Email sent and received
- [ ] Debug mode enabled (for logs)

---

## 📞 Still Having Issues?

1. **Check Supabase logs:**
   - Dashboard → Authentication → Logs
   - Look for failed auth attempts

2. **Check Flutter console:**
   ```bash
   flutter logs
   ```

3. **Clear app data and retry:**
   ```bash
   # Android
   adb shell pm clear com.sipelor.app
   ```

4. **Reinstall app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Verify configuration:**
   - [SUPABASE_EMAIL_CONFIGURATION.md](SUPABASE_EMAIL_CONFIGURATION.md)
   - [QUICK_FIX_EMAIL_LOCALHOST.md](QUICK_FIX_EMAIL_LOCALHOST.md)

---

**Last Updated:** 2026-01-28
**Version:** 1.0.0
