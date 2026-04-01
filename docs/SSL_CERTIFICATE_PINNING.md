# SSL Certificate Pinning - Implementation Guide

## 📋 Overview

SSL Certificate Pinning telah diimplementasikan untuk melindungi aplikasi SIPELOR dari Man-in-the-Middle (MITM) attacks. Dokumen ini menjelaskan implementasi, maintenance, dan troubleshooting.

---

## ✅ Implementasi

### 1. Konfigurasi File

#### `lib/config/ssl_config.dart`
- **Certificate Pins**: SHA-256 fingerprints dari Supabase SSL certificates
- **Primary Pin**: `sha256/L/7QEnurnUJBaSMfBpa/jjyrLwAFfW3uSsAYw4KSYbQ=`
- **Backup Pin**: `sha256/Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o=`
- **Auto-enabled**: Production builds only
- **Bypass**: Development builds (untuk debugging)

#### `lib/services/pinned_http_client.dart`
- Dio-based HTTP client dengan SSL pinning
- Validasi certificate pada setiap HTTPS request
- Automatic fallback untuk development

#### `lib/config/build_config.dart`
- Manajemen environment (dev/staging/production)
- Feature flags per environment
- Build configuration summary

### 2. Package Dependencies

```yaml
dependencies:
  dio: ^5.4.1                        # HTTP client dengan SSL pinning
  http_certificate_pinning: ^2.1.2  # Certificate validation helper
```

---

## 🏗️ Build Configurations

### Development Build (SSL Pinning OFF)
```bash
flutter run
# atau
flutter build apk --debug
```
- SSL pinning **disabled**
- Debugging tools **enabled**
- Verbose logging **enabled**
- Charles/Fiddler proxy **works**

### Staging Build (SSL Pinning ON - Optional)
```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=ENABLE_SSL_PINNING=true \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```
- SSL pinning **enabled** (optional)
- Similar to production
- Debug tools **enabled**

### Production Build (SSL Pinning ON - Enforced)
```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL=https://gbhprmibbcqfwjgrkfzq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_actual_key
```
- SSL pinning **always enabled**
- Debug tools **disabled**
- Verbose logging **disabled**
- MITM protection **active**

---

## 🔄 Certificate Update Procedures

### Kapan Harus Update Certificates?

1. **Certificate Expiration** (biasanya 90 hari untuk Let's Encrypt)
2. **Certificate Rotation** oleh Supabase/Cloudflare
3. **Security Incident** requiring certificate reissue
4. **Migration** ke provider/domain baru

### Cara Update Certificates

#### Step 1: Extract New Certificate Hash

**Windows (PowerShell):**
```powershell
$url = "gbhprmibbcqfwjgrkfzq.supabase.co"
$tcpClient = New-Object System.Net.Sockets.TcpClient($url, 443)
$sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, {$true})
$sslStream.AuthenticateAsClient($url)
$cert = $sslStream.RemoteCertificate
$certHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
$sha256 = "sha256/" + [System.Convert]::ToBase64String($certHash)
Write-Output "Certificate SHA256 Pin: $sha256"
$sslStream.Close()
$tcpClient.Close()
```

**Linux/Mac:**
```bash
openssl s_client -servername gbhprmibbcqfwjgrkfzq.supabase.co \
  -connect gbhprmibbcqfwjgrkfzq.supabase.co:443 \
  -showcerts </dev/null 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

#### Step 2: Update `lib/config/ssl_config.dart`

```dart
// BEFORE certificate rotation:
static const String primaryCertificatePin = 'sha256/OLD_HASH_1';
static const String backupCertificatePin = 'sha256/OLD_HASH_2';

// AFTER getting new certificate (add new as backup first):
static const String primaryCertificatePin = 'sha256/OLD_HASH_1';  // Keep old
static const String backupCertificatePin = 'sha256/NEW_HASH';     // Add new

// Release app version with both pins

// AFTER all users updated (2-4 weeks later):
static const String primaryCertificatePin = 'sha256/NEW_HASH';    // Promote new
static const String backupCertificatePin = 'sha256/NEXT_HASH';    // Add next backup
```

#### Step 3: Update Documentation

```dart
/// Primary certificate SHA-256 fingerprint
/// 
/// Extracted: 2026-XX-XX  ← Update date
/// Issuer: Let's Encrypt / Cloudflare
/// Valid Until: YYYY-MM-DD  ← Add expiry date
static const String primaryCertificatePin = 'sha256/...';
```

Update di `ssl_config.dart`:
- `Last Updated` date
- `Next Review` date (6 bulan dari update)

#### Step 4: Testing

```bash
# Test dengan staging build
flutter build apk --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=ENABLE_SSL_PINNING=true

# Install dan test semua fitur
flutter install

# Monitor logs untuk SSL errors
adb logcat | grep -i "ssl\|certificate\|pinning"
```

#### Step 5: Release

1. Build production APK dengan certificate baru
2. Upload ke Play Console/App Store
3. Monitor crash reports untuk SSL errors
4. Keep old certificate pin untuk 2-4 minggu
5. Remove old pin setelah semua users update

---

## 📊 Monitoring & Alerts

### Certificate Expiry Monitoring

**Built-in Warning System:**
```dart
// Di main.dart, otomatis check setiap startup
final warning = SSLConfig.getCertificateExpiryWarning();
// Output:
// - 60+ days: No warning
// - 30-60 days: "Review scheduled in X days"
// - 0-30 days: "⚠️ Certificate pins need review in X days"
// - Overdue: "⚠️ URGENT: Certificate pins are overdue for review!"
```

**Setup Automated Monitoring:**

1. **Create Scheduled Task (Windows)**
   ```powershell
   # Save script as: scripts/check_certificate_expiry.ps1
   ```

2. **Cron Job (Linux/Mac)**
   ```bash
   # Add to crontab (check weekly on Monday 9 AM):
   0 9 * * 1 cd /path/to/project && ./scripts/check_certificate_expiry.sh
   ```

3. **CI/CD Integration** (GitHub Actions)
   ```yaml
   # .github/workflows/certificate-check.yml
   name: Certificate Expiry Check
   on:
     schedule:
       - cron: '0 0 * * 1' # Every Monday
   jobs:
     check:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - name: Check Certificate
           run: ./scripts/check_certificate_expiry.sh
   ```

### Error Tracking

**Sentry Integration (Recommended):**
```dart
// In main.dart
if (BuildConfig.isProduction) {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'your-sentry-dsn';
      options.environment = BuildConfig.environment;
      // Track SSL errors
      options.beforeSend = (event, hint) {
        if (event.message?.contains('SSL') ?? false) {
          // Alert team immediately
          sendSlackNotification('🚨 SSL Error detected: ${event.message}');
        }
        return event;
      };
    },
  );
}
```

**Firebase Crashlytics:**
```dart
// Track SSL pinning failures
try {
  // HTTP request
} catch (e) {
  if (e.toString().contains('Certificate') || e.toString().contains('SSL')) {
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'SSL Certificate Pinning Failure',
      fatal: true,
    );
  }
}
```

---

## 🐛 Troubleshooting

### Problem 1: "Certificate pin mismatch"

**Symptoms:**
- App tidak bisa connect ke server di production
- Error log: "Certificate pin mismatch"

**Causes:**
1. Supabase rotated their certificate
2. Certificate pins outdated
3. Wrong hash format

**Solutions:**
1. Extract current certificate (see Step 1 above)
2. Update pins in `ssl_config.dart`
3. Release hotfix update

**Immediate Workaround (Emergency Only):**
```dart
// In ssl_config.dart (TEMPORARY!)
static bool get sslPinningEnabled {
  return false; // Disable temporarily
}
```
⚠️ **Never commit this to production!** Use only for emergency testing.

---

### Problem 2: "Insecure URL detected in production"

**Symptoms:**
- HTTP requests blocked
- Error: "Only HTTPS requests are allowed"

**Causes:**
- Using `http://` instead of `https://`
- Local testing URL leaked to production

**Solutions:**
```dart
// Wrong:
final url = 'http://example.com/api';

// Correct:
final url = 'https://example.com/api';
```

---

### Problem 3: Cannot debug network traffic

**Symptoms:**
- Charles Proxy / Fiddler tidak bisa intercept traffic
- Unable to inspect API requests

**Causes:**
- SSL pinning enabled in development

**Solutions:**
```bash
# Option 1: Use development build (auto-bypass)
flutter run

# Option 2: Explicitly disable pinning
flutter run --dart-define=ENABLE_SSL_PINNING=false

# Option 3: Build debug APK
flutter build apk --debug
```

---

### Problem 4: Certificate expired

**Symptoms:**
- App stopped working suddenly
- "Certificate has expired" error

**Immediate Actions:**
1. Check certificate expiry: `openssl s_client -connect ...`
2. Extract new certificate hash
3. Update `ssl_config.dart` with new pins
4. Build and release emergency update

**Prevention:**
- Setup monitoring alerts (60 days before expiry)
- Always maintain 2+ valid pins
- Review certificates every 6 months

---

## 🧪 Testing SSL Pinning

### Test 1: Verify Pinning Works

```bash
# Install Charles Proxy or Fiddler
# Enable SSL proxying
# Try to intercept traffic

# Expected Result in Production Build:
# - ❌ Connection should FAIL
# - ❌ Cannot see decrypted traffic
# - ✅ App logs: "Certificate pin mismatch"

# Expected Result in Development Build:
# - ✅ Connection should WORK
# - ✅ Can see decrypted traffic
# - ℹ️ App logs: "SSL pinning disabled (development mode)"
```

### Test 2: Certificate Rotation

```bash
# 1. Change certificate pin to invalid value
# 2. Build production APK
# 3. Test app

# Expected Result:
# - ❌ Cannot connect to Supabase
# - Error: Certificate validation failed
```

### Test 3: Multi-Environment

```bash
# Development
flutter run
# → Should bypass SSL pinning

# Staging
flutter build apk --release --dart-define=ENVIRONMENT=staging
# → Should enforce SSL pinning (if enabled)

# Production
flutter build apk --release --dart-define=ENVIRONMENT=production
# → Should ALWAYS enforce SSL pinning
```

---

## 📅 Maintenance Checklist

### Monthly
- [ ] Check app crash reports for SSL errors
- [ ] Review Sentry/Firebase Crashlytics for certificate issues

### Quarterly (Every 3 Months)
- [ ] Run certificate expiry check
- [ ] Verify backup pins are still valid
- [ ] Test app with Charles Proxy (should fail)
- [ ] Review and update documentation

### Semi-Annually (Every 6 Months)
- [ ] Extract current certificate from Supabase
- [ ] Compare with pinned certificates
- [ ] Update pins if certificate changed
- [ ] Test certificate rotation procedure
- [ ] Update `Next Review` date in code

### Before Every Release
- [ ] Verify SSL pinning enabled for production
- [ ] Check certificate expiry warnings
- [ ] Test production build with MITM proxy (should fail)
- [ ] Confirm both primary and backup pins are valid

---

## 📚 Additional Resources

### Internal Documentation
- `lib/config/ssl_config.dart` - Certificate configuration
- `lib/config/build_config.dart` - Build environments
- `lib/services/pinned_http_client.dart` - HTTP client implementation
- `ANALISIS_KEBUTUHAN_PENGEMBANGAN.md` - Security requirements

### External Resources
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-top-10/)
- [Certificate Pinning Best Practices](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
- [Let's Encrypt Certificate Lifecycle](https://letsencrypt.org/docs/cert-management/)
- [Dio SSL Pinning](https://pub.dev/packages/dio#certificate-pinning)

---

## 🆘 Support & Contact

**For SSL/Certificate Issues:**
1. Check this documentation first
2. Review app logs: `adb logcat | grep SSL`
3. Validate certificate: Run extraction script
4. Contact: Development Team Lead

**Emergency Contact:**
- Security Team: security@sipelor.app
- DevOps Team: devops@sipelor.app
- On-Call Engineer: +62-xxx-xxx-xxxx

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-26  
**Next Review:** 2026-07-26  
**Maintained By:** Development Team
