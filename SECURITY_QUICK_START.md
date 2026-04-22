# 🚀 Security Quick Start Guide

## 🔒 Environment Setup for Developers

### Option 1: Development (Using .env file)

```bash
# 1. Copy the example file
cp .env.example .env

# 2. Add your Supabase credentials
# Edit .env and fill in:
# - SUPABASE_URL=https://your-project.supabase.co
# - SUPABASE_ANON_KEY=your_anon_key

# 3. Run the app
flutter run
```

**Safety**: `.env` is in `.gitignore` — it won't be committed to git

---

### Option 2: Production Build (Most Secure)

```bash
# Build APK with credentials via --dart-define (no .env needed)
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://gbhprmibbcqfwjgrkfzq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key

# Build iOS
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://gbhprmibbcqfwjgrkfzq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

**Safety**: Credentials are not embedded in source code

---

### Option 3: CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
- name: Build Release APK
  run: |
    flutter build apk --release \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

---

## 🔑 Managing Secrets

### GitHub Secrets Setup

1. Go to: **Settings → Secrets and variables → Actions**
2. Add these secrets:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
   - `SENTRY_DSN`: Your Sentry DSN (optional)

### Rotating Credentials

```bash
# If credentials are compromised:
# 1. Regenerate at https://app.supabase.com
# 2. Update GitHub Secrets
# 3. Rebuild and redeploy
# 4. Run credential rotation script:
./scripts/remove_env_from_git.sh
```

---

## 🛡️ Security Features

### ✅ Enabled by Default

- **SSL Certificate Pinning**: Prevents man-in-the-middle attacks
- **RASP Security**: Runtime protection against jailbreak/root
- **Request Signing**: HMAC-SHA256 signature verification
- **Secure Storage**: Platform-specific encryption
- **Input Sanitization**: XSS, SQL injection protection
- **Rate Limiting**: Protection against brute force attacks
- **Auto Logout**: 10-minute inactivity timeout

### 📋 Debug Features (Debug Build Only)

- **Debug Menu**: Admin-only access to debug tools
- **Email Testing**: Verify email setup without real users
- **RASP Monitoring**: See security check results
- **Performance Monitoring**: Memory and performance metrics

**Access**:
```dart
// Only accessible in debug builds with admin role
if (DebugFeatureGuard.shouldShowDebugMenu()) {
  // Navigate to debug menu
}
```

---

## ⏰ Certificate Expiry Tracking

The SSL certificate for Supabase expires **2026-05-31**.

### Warning Timeline

| Date | Status | Action |
|------|--------|--------|
| 2026-04-22 | ℹ️ 40 days | App prints expiry info |
| 2026-05-01 | 🟠 HIGH | Update request in code |
| 2026-05-15 | 🔴 URGENT | Hard deadline - MUST update |
| 2026-05-31 | ⏰ EXPIRED | Certificate fails - app crashes |

### Updating Certificate Pin

1. Extract new certificate:
```bash
openssl s_client -servername gbhprmibbcqfwjgrkfzq.supabase.co \
  -connect gbhprmibbcqfwjgrkfzq.supabase.co:443 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

2. Update `lib/config/ssl_config.dart`:
```dart
static const String primaryCertificatePin = 'sha256/NEW_PIN_HERE=';
```

3. Test and deploy before 2026-05-31

---

## 🚨 Emergency Actions

### If Credentials Are Compromised

```bash
# 1. Immediately regenerate at Supabase console
# 2. Update GitHub Secrets
# 3. Remove old credentials from git history
./scripts/remove_env_from_git.sh

# 4. Force push to main
git push origin main --force-with-lease

# 5. Rebuild and redeploy
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### If SSL Certificate Expires

The app will refuse connections to Supabase if:
1. Certificate pin doesn't match
2. Or certificate is expired

**Recovery**:
1. Update `lib/config/ssl_config.dart` with new pin
2. Rebuild and deploy ASAP
3. Users must update app to continue using it

---

## ✨ Best Practices

✅ **DO**:
- Use `.env.example` as a template
- Regenerate credentials quarterly
- Rotate credentials if any compromise suspected
- Test security features in staging first
- Monitor certificate expiry dates
- Keep dependencies updated

❌ **DON'T**:
- Commit `.env` file to git
- Share credentials via chat/email
- Use same credentials across environments
- Disable SSL pinning in production
- Ignore security warnings
- Skip certificate updates

---

## 📞 Security Contact

For security issues or questions:
1. Check `SECURITY_FIXES_APPLIED.md` for implementation details
2. Review `SECURITY_AUDIT_REPORT_2026-04-17.md` for audit findings
3. Contact the security team with specific concerns

---

**Last Updated**: 2026-04-22  
**Next Review**: 2026-05-15 (Certificate update deadline)
