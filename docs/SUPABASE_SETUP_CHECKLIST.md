# ✅ SUPABASE Setup Checklist untuk SIPELOR

Checklist lengkap untuk setup Supabase project agar aplikasi SIPELOR berjalan dengan baik.

## 📋 Pre-requisites

- [ ] Akun Supabase sudah dibuat (https://app.supabase.com/)
- [ ] Project SIPELOR sudah dibuat di Supabase
- [ ] Database schema sudah di-setup (tables, RLS policies, etc.)

## 🔐 Authentication Configuration

### 1. URL Configuration (⚠️ CRITICAL)

**Path:** Authentication → URL Configuration

- [ ] **Site URL** diubah dari `http://localhost:3000` ke `sipelor://callback`
  
- [ ] **Redirect URLs** ditambahkan semua yang berikut:
  ```
  sipelor://callback
  sipelor://reset-password
  sipelor://auth/callback
  io.supabase.sipelor://login-callback
  ```

- [ ] Configuration di-**SAVE**

**Why:** Tanpa ini, email verification dan password reset akan stuck di localhost.

### 2. Email Provider

**Path:** Authentication → Email

- [ ] **Enable email provider** diaktifkan
- [ ] **Confirm email** diaktifkan (users harus verify email)
- [ ] **Secure email change** diaktifkan (optional, tapi recommended)

### 3. Email Templates (Optional)

**Path:** Authentication → Email Templates

- [ ] Review **Confirm signup** template
- [ ] Review **Reset password** template
- [ ] Customize subject line jika perlu
- [ ] Test email dengan real email address

### 4. Email Rate Limiting

**Path:** Authentication → Rate Limits

- [ ] **Email OTP rate limit**: 3 requests per hour (default OK)
- [ ] **Password reset rate limit**: 3 requests per hour (default OK)

Adjust sesuai kebutuhan untuk prevent spam.

### 5. Password Policy

**Path:** Authentication → Password Policy

- [ ] **Minimum password length**: 8 characters (recommended)
- [ ] **Require uppercase**: Optional
- [ ] **Require numbers**: Optional  
- [ ] **Require special characters**: Optional

Current setting: Minimum 6 characters (sesuai kode)

### 6. Auth Providers (Optional)

Jika ingin tambahkan OAuth:

**Path:** Authentication → Providers

- [ ] Google Sign-in (optional)
- [ ] Apple Sign-in (optional, required for App Store)
- [ ] Facebook Sign-in (optional)

## 🗄️ Database Configuration

### 1. Row Level Security (RLS)

**Path:** Database → Tables

Verify RLS policies untuk semua tables:

- [ ] **staff** table: RLS enabled
  - Users hanya bisa read/update profile sendiri
  - Admin bisa full access

- [ ] **venue** table: RLS enabled
  - Public read
  - Staff bisa manage venue mereka

- [ ] **field** table: RLS enabled
  - Public read
  - Staff bisa manage field di venue mereka

- [ ] **booking** table: RLS enabled
  - Users bisa read/create booking sendiri
  - Staff bisa manage booking di venue mereka

- [ ] **review** table: RLS enabled
  - Public read
  - Users bisa create/update/delete review sendiri

### 2. Database Extensions

**Path:** Database → Extensions

- [ ] **uuid-ossp** enabled (for UUID generation)
- [ ] **pgcrypto** enabled (for encryption functions)

### 3. Functions & Triggers

Verify custom functions:

- [ ] Auto-generate booking code function
- [ ] Update timestamp triggers
- [ ] Notification triggers (if any)

## 🔒 Security Settings

### 1. JWT Settings

**Path:** Project Settings → API

- [ ] JWT expiry time: Default 3600 seconds (1 hour)
- [ ] Refresh token expiry: Default 2592000 seconds (30 days)

Adjust sesuai security requirements.

### 2. API Keys

**Path:** Project Settings → API

- [ ] **anon/public key** - Untuk client app
- [ ] **service_role key** - NEVER expose to client! Server only

⚠️ **IMPORTANT:** 
- Anon key bisa di-embed di app
- Service role key HANYA untuk backend/admin scripts

## 🌐 API Settings

### 1. API URL

**Path:** Project Settings → API

- [ ] Copy **Project URL** untuk `.env` file:
  ```
  SUPABASE_URL=https://xxxxx.supabase.co
  ```

- [ ] Copy **anon public key** untuk `.env` file:
  ```
  SUPABASE_ANON_KEY=eyJxxx...
  ```

### 2. CORS Configuration

**Path:** Project Settings → API → CORS

Default: `*` (allow all origins)

Untuk production, consider restrict ke:
- [ ] Specific domains jika ada web version
- [ ] Deep link schemes: `sipelor://`

## 📧 Email Configuration (Advanced)

### Custom SMTP (Optional)

**Path:** Project Settings → Email

Default: Supabase's email service (limited to 3 emails/hour in free tier)

Untuk production:
- [ ] Setup custom SMTP (SendGrid, AWS SES, etc.)
- [ ] Verify sender email
- [ ] Test email delivery

## 🔔 Webhooks (Optional)

**Path:** Database → Webhooks

Setup webhooks untuk:
- [ ] New booking notifications
- [ ] Payment confirmations
- [ ] Review notifications

## 🧪 Testing

### Test Authentication Flow

- [ ] Test signup dengan email verification
  ```
  1. Signup dengan email baru
  2. Check inbox
  3. Klik verify email
  4. App terbuka (TIDAK stuck di browser)
  5. Login berhasil
  ```

- [ ] Test forgot password
  ```
  1. Klik "Lupa Password"
  2. Masukkan email
  3. Check inbox
  4. Klik reset password
  5. App terbuka (TIDAK stuck di browser)
  6. Form reset password muncul
  7. Input password baru
  8. Login dengan password baru berhasil
  ```

### Test Database Operations

- [ ] Create booking
- [ ] Read booking list
- [ ] Update booking
- [ ] Cancel booking
- [ ] Add review
- [ ] Upload photo

### Test RLS Policies

- [ ] User A tidak bisa akses data User B
- [ ] Staff hanya bisa manage venue sendiri
- [ ] Admin punya full access

## 📊 Monitoring

### Setup Monitoring

**Path:** Project Settings → Monitoring

- [ ] Enable **Error tracking**
- [ ] Enable **Performance monitoring**
- [ ] Setup **Alert notifications** untuk:
  - High error rate
  - Database usage threshold
  - API rate limit exceeded

### Check Logs Regularly

**Path:** Logs

- [ ] Check **API Logs** untuk errors
- [ ] Check **Database Logs** untuk slow queries
- [ ] Check **Auth Logs** untuk suspicious activity

## 💰 Billing (Production)

### Upgrade Plan (when ready)

- [ ] Review usage limits di free tier
- [ ] Upgrade ke Pro plan jika perlu:
  - More email sends
  - More database storage
  - More API requests
  - Better performance

### Set Budget Alerts

- [ ] Setup budget alerts di billing settings
- [ ] Monitor usage dashboard

## 🚀 Production Deployment

### Final Checks

- [ ] All security policies tested
- [ ] All email flows working
- [ ] Custom SMTP configured (if needed)
- [ ] Monitoring enabled
- [ ] Backup strategy in place
- [ ] Incident response plan ready

### Go Live!

- [ ] Update `.env` dengan production credentials
- [ ] Build production APK dengan credentials di-`--dart-define`
- [ ] Test di real devices
- [ ] Deploy to Google Play Store
- [ ] Monitor first user signups closely

## 📚 Documentation

- [ ] [SUPABASE_EMAIL_CONFIGURATION.md](SUPABASE_EMAIL_CONFIGURATION.md) - Email setup details
- [ ] [QUICK_FIX_EMAIL_LOCALHOST.md](QUICK_FIX_EMAIL_LOCALHOST.md) - Quick fix for localhost issue
- [ ] [README.md](../README.md) - General project documentation

## ❓ Troubleshooting

Jika ada masalah, check:

1. **Supabase Dashboard → Logs** - Check error logs
2. **Flutter Console** - Check client-side errors
3. **adb logcat** (Android) - Check deep link handling
4. **Xcode Console** (iOS) - Check iOS-specific issues

## 📞 Support

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com/
- Stack Overflow: Tag `supabase`

---

**Last Updated:** 2026-01-28
**Version:** 1.0.0

**Status:** 
- [ ] Development
- [ ] Staging
- [ ] Production
