# SSL Certificate Pinning - Quick Reference

## ✅ Implementation Status

**SSL Certificate Pinning has been successfully implemented and configured!**

- ✅ Certificate pins extracted and configured
- ✅ HTTP client with pinning support created
- ✅ Build configurations for dev/staging/production
- ✅ Monitoring scripts and alerts
- ✅ Documentation and procedures

---

## 🚀 Quick Start

### Development (SSL Pinning OFF)
```powershell
# Method 1: Run directly
flutter run

# Method 2: Build debug APK
.\scripts\build_development.ps1
```
**Features:**
- SSL pinning disabled
- Debugging tools enabled
- Charles/Fiddler proxy works

### Production (SSL Pinning ON)
```powershell
# Build production APK
.\scripts\build_production.ps1 -SupabaseKey "your_actual_key"
```
**Features:**
- SSL pinning enforced
- MITM protection active
- Code obfuscation enabled

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `lib/config/ssl_config.dart` | Certificate pins configuration |
| `lib/services/pinned_http_client.dart` | HTTP client with pinning |
| `lib/config/build_config.dart` | Environment management |
| `docs/SSL_CERTIFICATE_PINNING.md` | Full documentation |
| `scripts/check_certificate_expiry.ps1` | Certificate monitoring |
| `scripts/build_production.ps1` | Production build script |

---

## 🔒 Certificate Pins

**Current Configuration:**
```dart
Primary Pin:  sha256/L/7QEnurnUJBaSMfBpa/jjyrLwAFfW3uSsAYw4KSYbQ=
Backup Pin:   sha256/Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o=
Domain:       gbhprmibbcqfwjgrkfzq.supabase.co
Last Updated: 2026-01-26
Next Review:  2026-07-26
```

---

## 🔄 Certificate Update (When Needed)

### Step 1: Extract New Certificate
```powershell
# Run extraction script
$url = "gbhprmibbcqfwjgrkfzq.supabase.co"
$tcpClient = New-Object System.Net.Sockets.TcpClient($url, 443)
$sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, {$true})
$sslStream.AuthenticateAsClient($url)
$cert = $sslStream.RemoteCertificate
$certHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
$sha256 = "sha256/" + [System.Convert]::ToBase64String($certHash)
Write-Output $sha256
$sslStream.Close()
$tcpClient.Close()
```

### Step 2: Update lib/config/ssl_config.dart
```dart
// Update certificate pins
static const String primaryCertificatePin = 'sha256/NEW_HASH_HERE';
static const String backupCertificatePin = 'sha256/BACKUP_HASH_HERE';

// Update dates
/// Last Updated: YYYY-MM-DD
/// Next Review: YYYY-MM-DD (6 months from update)
```

### Step 3: Release Update
```powershell
.\scripts\build_production.ps1 -SupabaseKey "your_key"
```

---

## 📊 Monitoring

### Check Certificate Expiry
```powershell
# Manual check
.\scripts\check_certificate_expiry.ps1

# Output:
# ✅ OK: Certificate is valid for X days
# ⚠️  WARNING: Certificate expires in X days
# 🚨 URGENT: Certificate expires in X days!
```

### Setup Automated Monitoring
```powershell
# Run weekly (every Monday at 9 AM)
# Add to Windows Task Scheduler
schtasks /create /tn "SIPELOR-CertCheck" /tr "powershell.exe -File D:\path\to\scripts\check_certificate_expiry.ps1" /sc weekly /d MON /st 09:00
```

---

## 🧪 Testing

### Test SSL Pinning Works
1. Install Charles Proxy or Fiddler
2. Enable SSL proxying
3. Install production build
4. Try to use app

**Expected Results:**
- ❌ Production build: Connection fails (pinning works!)
- ✅ Development build: Connection works (debugging enabled)

### Verify Build Configuration
```powershell
# Check what's enabled
flutter run --release --dart-define=ENVIRONMENT=production

# Look for console output:
# ✅ SSL pinning configured and validated
# Environment: production
```

---

## 🐛 Troubleshooting

### Problem: "Certificate pin mismatch"
**Solution:** Certificate rotated, extract new hash and update

### Problem: Cannot debug network traffic
**Solution:** Use development build:
```powershell
flutter run --dart-define=ENABLE_SSL_PINNING=false
```

### Problem: App cannot connect in production
**Solution:** Check certificate expiry:
```powershell
.\scripts\check_certificate_expiry.ps1
```

---

## 📅 Maintenance Schedule

### Monthly
- [ ] Check crash reports for SSL errors

### Quarterly (Every 3 Months)
- [ ] Run certificate expiry check
- [ ] Test with MITM proxy (should fail)

### Semi-Annually (Every 6 Months)
- [ ] Extract current certificate
- [ ] Update pins if changed
- [ ] Update documentation dates

---

## 📚 Documentation

**Full Documentation:** [docs/SSL_CERTIFICATE_PINNING.md](./docs/SSL_CERTIFICATE_PINNING.md)

Includes:
- Detailed implementation guide
- Certificate rotation procedures
- Build configurations
- Monitoring and alerts
- Troubleshooting guide
- Maintenance checklist

---

## 🆘 Quick Help

**Need to update certificates urgently?**
1. Run: `.\scripts\check_certificate_expiry.ps1`
2. Extract new hash (see Step 1 above)
3. Update: `lib/config/ssl_config.dart`
4. Build: `.\scripts\build_production.ps1`
5. Test and deploy

**For detailed help:** See `docs/SSL_CERTIFICATE_PINNING.md`

---

**Last Updated:** 2026-01-26  
**Implementation Status:** ✅ Complete and Active  
**Next Review:** 2026-07-26
