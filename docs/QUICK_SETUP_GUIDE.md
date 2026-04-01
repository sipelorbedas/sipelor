# 🚀 Quick Setup Guide - Email Templates & Deep Links

> **Panduan cepat untuk fix button email yang tidak bisa diklik**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026

---

## ⚡ Quick Fix (5 Menit)

### Step 1: Configure Redirect URLs di Supabase

1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Go to **Authentication** → **URL Configuration**
3. Di **Redirect URLs**, tambahkan:
   ```
   sipelor://callback
   sipelor://reset-password
   http://localhost:3000
   ```
4. Di **Site URL**, set:
   ```
   sipelor://
   ```
5. Click **Save**

---

### Step 2: Update Email Templates

1. Go to **Authentication** → **Email Templates**

2. **Update "Confirm signup" template:**
   
   Ganti button link dari:
   ```html
   <a href="{{ .ConfirmationURL }}" class="button">
   ```
   
   Menjadi:
   ```html
   <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=sipelor://callback" class="button">
   ```

3. **Update "Reset Password" template:**
   
   Ganti button link dari:
   ```html
   <a href="{{ .ConfirmationURL }}" class="button">
   ```
   
   Menjadi:
   ```html
   <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=sipelor://reset-password" class="button">
   ```

4. Click **Save** untuk masing-masing template

---

### Step 3: Install Deep Link Package

1. Buka terminal di folder project
2. Run:
   ```bash
   flutter pub get
   ```
   
   Package `app_links` sudah ditambahkan di `pubspec.yaml`

---

### Step 4: Reinstall App

**Penting:** Android perlu reinstall untuk apply AndroidManifest changes

```bash
# Stop running app
flutter clean

# Build and install
flutter run
```

---

## ✅ Testing

### Test Email Verification:

1. Signup user baru via app
2. Check email inbox
3. Click "Verifikasi Email" button
4. **Expected:** App opens automatically dan user ter-verify

### Test Password Reset:

1. Request password reset via app:
   ```dart
   await supabase.auth.resetPasswordForEmail('your@email.com');
   ```
2. Check email inbox
3. Click "Reset Password" button
4. **Expected:** App opens ke reset password screen

### Test Manual Deep Link (via Terminal):

```bash
# Test verification callback
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://callback?type=signup&access_token=test123"

# Test password reset
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password?access_token=test123"
```

---

## 🐛 Troubleshooting

### Button masih tidak bisa diklik

1. ✅ Clear email cache di email client
2. ✅ Send email baru (setelah update template)
3. ✅ Test di different email client (Gmail, Outlook)
4. ✅ Check Redirect URLs sudah Save di Supabase

### Deep link tidak buka app

1. ✅ Reinstall app (`flutter clean` → `flutter run`)
2. ✅ Check AndroidManifest.xml sudah di-update
3. ✅ Test manual deep link via adb (command di atas)
4. ✅ Check app installed correctly

### Error "Invalid redirect URL"

1. ✅ Verify URL ada di Redirect URLs list di Supabase
2. ✅ Check Site URL match salah satu redirect URL
3. ✅ Ensure URL tidak ada typo

---

## 📋 Checklist

- [ ] Redirect URLs configured di Supabase
- [ ] Site URL configured di Supabase  
- [ ] Email templates updated dengan redirect URLs
- [ ] `flutter pub get` executed
- [ ] App reinstalled (`flutter clean` + `flutter run`)
- [ ] Email verification tested
- [ ] Password reset tested

---

## 📚 Complete Documentation

Untuk dokumentasi lengkap:
- [Email Templates](./EMAIL_TEMPLATES.md)
- [Redirect URL Setup](./SUPABASE_REDIRECT_URL_SETUP.md)
- [Email Testing Guide](./EMAIL_TESTING_GUIDE.md)

---

## 💡 Summary

**Masalah:** Button email tidak bisa diklik karena:
1. Redirect URL belum dikonfigurasi di Supabase ❌
2. Email template menggunakan variable yang salah ❌
3. Deep link handling belum lengkap di Flutter ❌

**Solusi:**
1. Configure Redirect URLs di Supabase ✅
2. Update email templates dengan proper URL ✅
3. Deep link handler sudah di-implement ✅
4. AndroidManifest sudah di-update ✅

**Next:** Follow Step 1-4 di atas dan test!

---

**Last Updated**: 28 Januari 2026  
**Maintained By**: Development Team
