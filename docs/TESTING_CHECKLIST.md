# ✅ Testing Checklist: Email Deep Link

## 📋 Pre-Test Checklist

Sebelum test, pastikan:

- [x] Supabase Site URL = `sipelor://callback` ✅
- [x] Redirect URLs sudah include semua deep link ✅
- [ ] **Klik "Save changes" di Supabase Dashboard**
- [ ] Tunggu 1-2 menit untuk propagasi
- [ ] Hapus semua email lama dari inbox
- [ ] Aplikasi sudah ter-install di device

## 🧪 Test 1: Deep Link Manual (Device Test)

**Purpose:** Verify deep link berfungsi di device

**Steps:**
```powershell
# Connect device via USB
adb devices

# Test deep link
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
```

**Expected Result:**
- ✅ Aplikasi SIPELOR terbuka
- ✅ Screen muncul (mungkin error "link invalid" - ini OK, karena tidak ada token)
- ✅ Tidak stuck di browser

**Actual Result:**
- [ ] Pass
- [ ] Fail (describe: _________________)

---

## 🧪 Test 2: Forgot Password Email Flow

**Purpose:** Test full flow dari request sampai reset

### Step 1: Request Password Reset

1. [ ] Buka aplikasi SIPELOR
2. [ ] Klik "Lupa Password" / "Forgot Password"
3. [ ] Input email: `__________________`
4. [ ] Klik Submit
5. [ ] Lihat success message

**Expected:** "Email reset password telah dikirim"

### Step 2: Check Email

1. [ ] Buka email inbox
2. [ ] Email dari Supabase diterima
3. [ ] Subject: "Reset Your Password" atau similar
4. [ ] Email berisi button "Reset Password"

**Expected:** Email diterima dalam 1-2 menit

### Step 3: Click Reset Password Button

1. [ ] Klik button "Reset Password" di email
2. [ ] Observe apa yang terjadi

**Expected Result:**
- ✅ Aplikasi SIPELOR terbuka (BUKAN browser!)
- ✅ Loading indicator: "Memverifikasi link..."
- ✅ Form reset password muncul

**Actual Result:**
- [ ] Aplikasi terbuka ✅
- [ ] Browser terbuka ❌ (If this happens, go to Troubleshooting)
- [ ] Nothing happens ❌ (If this happens, go to Troubleshooting)

### Step 4: Reset Password

1. [ ] Form reset password terlihat
2. [ ] Input password baru: `__________________`
3. [ ] Confirm password: `__________________`
4. [ ] Klik "Reset Password" button
5. [ ] Lihat success message

**Expected:** "Password berhasil diubah!"

### Step 5: Login dengan Password Baru

1. [ ] Navigate to login screen
2. [ ] Input email: `__________________`
3. [ ] Input password baru: `__________________`
4. [ ] Klik Login
5. [ ] Berhasil login

**Expected:** Redirect ke home screen

---

## 🧪 Test 3: Email Verification Flow (Bonus)

**Purpose:** Test email verification juga menggunakan deep link

### Step 1: Signup New Account

1. [ ] Buka aplikasi
2. [ ] Klik "Sign Up" / "Daftar"
3. [ ] Fill form:
   - Email: `test_________________________@example.com`
   - Password: `__________________`
   - Nama: `__________________`
4. [ ] Submit
5. [ ] Lihat message "Check your email"

### Step 2: Verify Email

1. [ ] Buka email inbox
2. [ ] Email "Confirm your email" diterima
3. [ ] Klik button "Verify Email"

**Expected Result:**
- ✅ Aplikasi terbuka (BUKAN browser!)
- ✅ Success message: "Email berhasil diverifikasi"
- ✅ Redirect ke home/dashboard

**Actual Result:**
- [ ] Pass
- [ ] Fail (describe: _________________)

---

## ❌ Troubleshooting

### Issue: Browser Opens Instead of App

**Diagnose:**

1. Check Supabase config:
   ```
   Site URL = sipelor://callback ✅ or ❌?
   Redirect URLs include sipelor:// URLs ✅ or ❌?
   Clicked "Save changes" ✅ or ❌?
   ```

2. Check if using OLD email:
   ```
   Email sent BEFORE config update? If YES, delete and request new email
   ```

3. Test deep link manually:
   ```powershell
   adb shell am start -W -a android.intent.action.VIEW -d "sipelor://callback"
   ```
   
   App opens? 
   - YES → Issue is with email configuration
   - NO → Issue is with app/device configuration

**Solutions:**

- [ ] Double-check Site URL = `sipelor://callback`
- [ ] Click "Save changes" in Supabase
- [ ] Wait 2 minutes
- [ ] Delete OLD emails
- [ ] Request NEW password reset
- [ ] Use NEW email

### Issue: "Link Invalid" or "Link Expired"

**Diagnose:**

Link expires:
- Password reset: 1 hour
- Email verification: 24 hours

**Solutions:**

- [ ] Request new email
- [ ] Click link immediately (don't wait)
- [ ] Don't reuse old links

### Issue: App Opens but Shows Blank/Black Screen

**Diagnose:**

Check Flutter console logs:
```powershell
flutter logs
```

Look for:
- `🔗 Deep link received`
- `✅ Session set`
- Any error messages

**Solutions:**

- [ ] Restart app
- [ ] Reinstall app
- [ ] Check console logs
- [ ] See: docs/TROUBLESHOOTING_DEEP_LINKS.md

### Issue: "No Internet Connection" Error

**Solutions:**

- [ ] Check device has internet
- [ ] Check Supabase is reachable
- [ ] Try again

---

## 📊 Test Results Summary

### Environment
- **Date:** _______________
- **Device:** _______________
- **Android Version:** _______________
- **App Version:** _______________

### Results

| Test | Status | Notes |
|------|--------|-------|
| Deep Link Manual | ⬜ Pass ⬜ Fail | |
| Forgot Password Flow | ⬜ Pass ⬜ Fail | |
| Email Verification | ⬜ Pass ⬜ Fail | |

### Issues Found

1. _________________________________
2. _________________________________
3. _________________________________

### Overall Status

- ⬜ All tests passed ✅
- ⬜ Some tests failed ⚠️
- ⬜ All tests failed ❌

---

## 📞 Need Help?

If tests fail, check:

1. **Supabase Configuration**
   - Site URL correct?
   - Redirect URLs added?
   - Changes saved?

2. **Documentation**
   - [FIX_EMAIL_OPENS_BROWSER.md](FIX_EMAIL_OPENS_BROWSER.md)
   - [TROUBLESHOOTING_DEEP_LINKS.md](TROUBLESHOOTING_DEEP_LINKS.md)
   - [SUPABASE_EMAIL_CONFIGURATION.md](SUPABASE_EMAIL_CONFIGURATION.md)

3. **Verify Local Config**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\verify_supabase_config.ps1
   ```

4. **Test Scripts**
   ```powershell
   scripts\test_deep_links.bat
   ```

---

**Last Updated:** 2026-01-28
**Version:** 1.0.0
