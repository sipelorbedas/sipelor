# 🔧 Fix Supabase Redirect URLs - Kembalikan ke Deep Link

## ❌ Masalah

Redirect OAuth (dan forgot password, email verification) **tidak full width** karena:
- Supabase Dashboard masih ada URL Netlify/Vercel/custom domain
- Deep link tidak langsung triggered
- Ada intermediate page yang tidak responsive

## ✅ Solusi: Gunakan HANYA Deep Link

### Step 1: Bersihkan Supabase Redirect URLs

1. **Login ke Supabase Dashboard**
   - https://app.supabase.com
   - Pilih project SIPELOR BEDAS

2. **Buka URL Configuration**
   - Authentication → URL Configuration
   - Scroll ke **Redirect URLs**

3. **HAPUS semua URL kecuali deep link**
   
   **HAPUS URL seperti ini:**
   - ❌ `https://xxx.netlify.app/...`
   - ❌ `https://xxx.vercel.app/...`
   - ❌ `https://xxx.github.io/...`
   - ❌ Semua HTTPS URLs lainnya

4. **PASTIKAN HANYA ada URL ini:**
   ```
   io.supabase.sipelor://login-callback/
   ```

5. **Save Changes**

### Step 2: Verify Site URL

1. Masih di **URL Configuration**
2. Check **Site URL** (bagian atas):
   ```
   io.supabase.sipelor://
   ```
   atau
   ```
   sipelor://
   ```

3. Jika masih ada Netlify/custom domain, **ganti ke deep link**

### Step 3: Check Email Templates

Pastikan email templates (verification, reset password) juga pakai deep link:

1. **Email Templates**
   - Authentication → Email Templates

2. **Confirm signup template:**
   ```
   Silakan verifikasi email Anda:
   {{ .ConfirmationURL }}
   ```
   
   **Default sudah benar**, tapi pastikan tidak ada hardcoded URL

3. **Reset password template:**
   ```
   Reset password Anda:
   {{ .ConfirmationURL }}
   ```

   **Default sudah benar**

### Step 4: Rebuild & Test

```powershell
flutter clean
flutter pub get
flutter run
```

**Test semua flow:**

1. **OAuth (Google Sign In)**
   - Klik "Sign In With Gmail"
   - Pilih email → Lanjutkan
   - **Expected:** Langsung ke app, NO web page

2. **Forgot Password**
   - Klik "Forgot Password"
   - Masukkan email → Send Link
   - Buka email → Klik link
   - **Expected:** Langsung buka app, NO web page

3. **Email Verification**
   - Sign up dengan email baru
   - Buka email → Klik verify link
   - **Expected:** Langsung buka app, NO web page

---

## 🎯 Yang HARUS Terjadi

### Redirect URLs di Supabase:
```
✅ io.supabase.sipelor://login-callback/
❌ (tidak ada yang lain)
```

### Site URL di Supabase:
```
✅ io.supabase.sipelor://
atau
✅ sipelor://
```

### Code di Flutter:
```dart
// lib/services/social_auth_service.dart
static String _getOAuthRedirectUrl() {
  return 'io.supabase.sipelor://login-callback/';
}
```

**Sudah benar ✅** (tidak perlu diubah)

---

## 📱 Cara Kerja Deep Link

```
[Google OAuth / Email Link]
        ↓
[Supabase processes]
        ↓
[Redirect to: io.supabase.sipelor://login-callback/]
        ↓
[Android/iOS detects deep link]
        ↓
[Opens SIPELOR BEDAS app directly]
        ↓
[App handles the deep link]
        ↓
[User logged in / email verified]
```

**NO intermediate web page** = **NO viewport issues** ✅

---

## 🔍 Troubleshooting

### Issue: Masih muncul Netlify page

**Penyebab:** Supabase masih redirect ke Netlify URL

**Fix:**
1. Cek lagi Redirect URLs di Supabase Dashboard
2. HAPUS semua HTTPS URLs
3. Pastikan HANYA ada `io.supabase.sipelor://login-callback/`
4. Save dan tunggu 1-2 menit (propagasi)
5. Test lagi

### Issue: "Invalid redirect URL" error

**Penyebab:** Deep link belum ditambahkan di Supabase

**Fix:**
1. Supabase Dashboard → Authentication → URL Configuration
2. Tambahkan: `io.supabase.sipelor://login-callback/`
3. Save

### Issue: Deep link tidak buka app

**Penyebab:** AndroidManifest.xml tidak ada intent filter

**Fix:** Check `android/app/src/main/AndroidManifest.xml`

Pastikan ada:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="io.supabase.sipelor"
          android:host="login-callback"/>
</intent-filter>
```

**Sudah ada ✅** (line 63-70)

### Issue: Email verification tidak buka app

**Penyebab:** Email template pakai URL salah

**Fix:**
1. Supabase Dashboard → Authentication → Email Templates
2. Pastikan pakai variable: `{{ .ConfirmationURL }}`
3. Jangan hardcode URL

---

## ✅ Checklist Verification

Setelah cleanup, verify:

- [ ] Supabase Redirect URLs HANYA ada `io.supabase.sipelor://login-callback/`
- [ ] Supabase Site URL pakai deep link (bukan HTTPS)
- [ ] Code di Flutter pakai `io.supabase.sipelor://login-callback/`
- [ ] AndroidManifest.xml ada intent filter untuk deep link
- [ ] OAuth Google login langsung buka app (no web page)
- [ ] Forgot password link langsung buka app (no web page)
- [ ] Email verification link langsung buka app (no web page)
- [ ] Semua full width (karena no web page intermediate)

---

## 📝 Summary

**Problem:** Netlify/custom URL di Supabase → intermediate web page → not full width

**Solution:** HANYA pakai deep link → langsung buka app → no web page → no viewport issue

**Action Required:**
1. ✅ Bersihkan Supabase Redirect URLs (HAPUS semua kecuali deep link)
2. ✅ Test OAuth, forgot password, email verification
3. ✅ Verify semua langsung buka app tanpa web page

**Expected Result:**
- ✅ No intermediate web page
- ✅ No viewport issues
- ✅ Seamless app opening
- ✅ Fast & smooth user experience

---

**Status:** Ready to Fix 🚀  
**Time Required:** 2-3 menit  
**Created:** 5 Februari 2026
