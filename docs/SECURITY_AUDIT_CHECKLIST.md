# 🔒 Security Audit Checklist - SIPELOR BEDAS

> **Comprehensive security audit checklist sebelum production launch**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026  
> **Audit Type**: Pre-Production Security Review

---

## 🎯 Audit Scope

Audit ini mencakup:
- Application security (Flutter app)
- Backend security (Supabase)
- Network security
- Data protection
- Authentication & authorization
- API security
- Infrastructure security
- Compliance & privacy

---

## 📋 OWASP Mobile Top 10 (2024) Checklist

### M1: Improper Credential Usage

- [ ] **Hardcoded Secrets Check**
  - [ ] No API keys dalam source code
  - [ ] No passwords dalam strings.xml atau constants
  - [ ] No tokens dalam Git history
  - [ ] Use `--dart-define` untuk production credentials
  - [ ] `.env` file di `.gitignore`

- [ ] **Secure Storage**
  - [ ] Credentials stored in `flutter_secure_storage`
  - [ ] Session tokens encrypted
  - [ ] Biometric data not stored locally
  - [ ] No sensitive data dalam SharedPreferences (unencrypted)

- [ ] **Secret Management**
  - [ ] GitHub Secrets configured for CI/CD
  - [ ] Separate keys untuk dev/staging/prod
  - [ ] Key rotation policy exists
  - [ ] Emergency key revocation process documented

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M2: Inadequate Supply Chain Security

- [ ] **Dependency Security**
  - [ ] All packages dari pub.dev (official)
  - [ ] No unverified third-party packages
  - [ ] Run `flutter pub outdated` regularly
  - [ ] No packages dengan known vulnerabilities
  - [ ] Dependency version pinning dalam pubspec.lock

- [ ] **Package Verification**
  - [ ] Check package popularity (>100k pub points)
  - [ ] Check last updated date (< 6 months)
  - [ ] Review package permissions
  - [ ] Verify package publisher identity
  - [ ] Check for security advisories

- [ ] **Build Tools Security**
  - [ ] Flutter SDK dari official source
  - [ ] Android SDK dari official source
  - [ ] Gradle dependencies verified
  - [ ] No malicious build scripts

**Critical Packages Review**:
| Package | Version | Last Audit | Status |
|---------|---------|------------|--------|
| supabase_flutter | 2.5.0 | 2026-01-28 | ✅ |
| flutter_secure_storage | 10.0.0 | 2026-01-28 | ✅ |
| local_auth | 3.0.0 | 2026-01-28 | ✅ |
| sentry_flutter | 9.10.0 | 2026-01-28 | ✅ |

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M3: Insecure Authentication/Authorization

- [ ] **Password Policy**
  - [ ] Minimum 8 characters enforced
  - [ ] Complexity requirements (uppercase, lowercase, number, symbol)
  - [ ] Password strength indicator shown
  - [ ] Prevent common passwords
  - [ ] No password exposed in logs

- [ ] **Multi-Factor Authentication**
  - [ ] Biometric authentication available
  - [ ] Fallback to password exists
  - [ ] Cannot bypass biometric
  - [ ] Biometric data not stored by app

- [ ] **Session Management**
  - [ ] Sessions timeout after 15 minutes inactivity
  - [ ] Re-authentication untuk sensitive actions
  - [ ] Logout invalidates session server-side
  - [ ] Cannot reuse old tokens
  - [ ] Concurrent session handling

- [ ] **Account Lockout**
  - [ ] Account locked after 3 failed attempts
  - [ ] Lockout duration: 1 hour
  - [ ] Admin can unlock accounts
  - [ ] Failed attempts logged
  - [ ] Rate limiting on login endpoint

- [ ] **Email Verification**
  - [ ] Email verification mandatory
  - [ ] Cannot book without verification
  - [ ] Verification link expires (24 hours)
  - [ ] Resend rate limited

- [ ] **Password Reset**
  - [ ] Reset tokens expire (1 hour)
  - [ ] One-time use tokens
  - [ ] Reset rate limited
  - [ ] No user enumeration
  - [ ] Notifications on password change

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M4: Insufficient Input/Output Validation

- [ ] **Input Sanitization**
  - [ ] XSS protection in user inputs
  - [ ] SQL injection prevention (Supabase RLS)
  - [ ] Command injection prevention
  - [ ] Path traversal prevention
  - [ ] No eval() or dangerous functions

- [ ] **Data Validation**
  - [ ] Email validation regex
  - [ ] Phone number validation
  - [ ] Date/time validation
  - [ ] File upload validation (type, size)
  - [ ] Image upload validation (format, dimensions)

- [ ] **Output Encoding**
  - [ ] HTML encoding untuk user-generated content
  - [ ] JSON encoding proper
  - [ ] URL encoding untuk deep links
  - [ ] No raw HTML rendering

- [ ] **File Upload Security**
  - [ ] File type whitelist (jpg, png only)
  - [ ] File size limit (5MB)
  - [ ] Filename sanitization
  - [ ] Virus scanning (if applicable)
  - [ ] Secure file storage

**Test Cases**:
- [ ] Try uploading `.exe` file → Should reject
- [ ] Try uploading 20MB image → Should reject
- [ ] Submit review dengan `<script>alert('XSS')</script>` → Should sanitize
- [ ] Enter email `test@test` → Should show validation error

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M5: Insecure Communication

- [ ] **SSL/TLS Configuration**
  - [ ] HTTPS enforced untuk all API calls
  - [ ] SSL certificate pinning implemented
  - [ ] Certificate validation not disabled
  - [ ] No cleartext traffic allowed
  - [ ] TLS 1.2+ only

- [ ] **Certificate Pinning**
  - [ ] Supabase certificate pinned
  - [ ] Backup pins configured
  - [ ] Certificate expiry monitoring
  - [ ] Pin update process documented

- [ ] **Network Security Config**
  - [ ] `android:usesCleartextTraffic="false"`
  - [ ] Network security config file exists
  - [ ] Debug builds handle carefully
  - [ ] No trust all certificates

- [ ] **API Security**
  - [ ] API keys not in URLs
  - [ ] No sensitive data dalam GET params
  - [ ] Proper HTTP methods (GET/POST/PUT/DELETE)
  - [ ] Rate limiting on API endpoints

**Test Certificate Pinning**:
```bash
# Should FAIL with certificate pinning:
# 1. Install Burp Suite or Charles Proxy
# 2. Install proxy certificate on device
# 3. Route app traffic through proxy
# Expected: Connection should fail
```

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M6: Inadequate Privacy Controls

- [ ] **Data Minimization**
  - [ ] Only collect necessary data
  - [ ] No excessive permissions requested
  - [ ] Clear purpose untuk each data collection
  - [ ] User can opt-out of optional data

- [ ] **Privacy Policy**
  - [ ] Privacy policy implemented
  - [ ] Accessible from app
  - [ ] Last updated within 6 months
  - [ ] Covers all data collection
  - [ ] Legal review completed

- [ ] **Terms of Service**
  - [ ] ToS implemented
  - [ ] User must accept on signup
  - [ ] Covers liability & refunds
  - [ ] Legal review completed

- [ ] **User Consent**
  - [ ] Consent untuk marketing emails
  - [ ] Consent untuk push notifications
  - [ ] Consent untuk data sharing
  - [ ] Consent withdrawal mechanism

- [ ] **Data Access Rights**
  - [ ] User can view their data
  - [ ] User can export data
  - [ ] User can delete account
  - [ ] Data deletion within 30 days

- [ ] **Third-Party Services**
  - [ ] List all third parties (Supabase, Sentry, etc.)
  - [ ] Privacy policy mentions them
  - [ ] Data Processing Agreements signed
  - [ ] GDPR compliant (if EU users)

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M7: Insufficient Binary Protections

- [ ] **Code Obfuscation**
  - [ ] ProGuard/R8 enabled untuk release builds
  - [ ] Obfuscation rules configured
  - [ ] Critical code obfuscated
  - [ ] No sensitive strings in plain text

- [ ] **Anti-Tampering**
  - [ ] App signing configured
  - [ ] Cannot install unsigned APK over signed
  - [ ] Root/jailbreak detection (optional)
  - [ ] Debug mode disabled in release

- [ ] **Reverse Engineering Protection**
  - [ ] Native code used untuk critical functions (optional)
  - [ ] Important algorithms protected
  - [ ] No hardcoded encryption keys

- [ ] **Build Configuration**
  - [ ] Debug flags removed in release
  - [ ] Logging disabled in release
  - [ ] Stack traces sanitized
  - [ ] No developer backdoors

**Verify Obfuscation**:
```bash
# Decompile APK dan check if code is obfuscated:
jadx-gui build/app/outputs/flutter-apk/app-release.apk
# Class names should be: a, b, c, etc. (obfuscated)
```

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M8: Security Misconfiguration

- [ ] **App Permissions**
  - [ ] Only necessary permissions requested
  - [ ] Permission rationale shown to user
  - [ ] Runtime permissions handled
  - [ ] No dangerous permissions without justification

**Android Permissions Audit**:
| Permission | Necessary? | Rationale | Status |
|-----------|-----------|-----------|--------|
| INTERNET | ✅ Yes | API calls | ✅ |
| ACCESS_NETWORK_STATE | ✅ Yes | Check connectivity | ✅ |
| READ_EXTERNAL_STORAGE | ✅ Yes | Photo upload | ✅ |
| WRITE_EXTERNAL_STORAGE | ✅ Yes | Save ticket | ✅ |
| CAMERA | ❌ No | Not used | ⚠️ Remove |
| LOCATION | ❌ No | Not used | ⚠️ Remove |
| READ_CONTACTS | ❌ No | Not used | ⚠️ Remove |

- [ ] **Backend Configuration**
  - [ ] Supabase RLS policies enabled
  - [ ] Row-level security on all tables
  - [ ] Admin functions protected
  - [ ] No public write access
  - [ ] Rate limiting configured

- [ ] **Storage Security**
  - [ ] Public buckets only untuk public assets
  - [ ] Private buckets untuk payment proofs
  - [ ] Bucket policies configured
  - [ ] No direct file access URLs

- [ ] **Environment Configuration**
  - [ ] Separate dev/staging/prod environments
  - [ ] Production keys not in dev
  - [ ] Debug tools disabled in production
  - [ ] Error messages don't leak info

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M9: Insecure Data Storage

- [ ] **Local Storage Security**
  - [ ] Sensitive data encrypted at rest
  - [ ] AES-256 encryption used
  - [ ] Encryption keys dari flutter_secure_storage
  - [ ] No sensitive data in logs
  - [ ] No sensitive data in crash reports

- [ ] **Database Security**
  - [ ] SQLite database encrypted (if used)
  - [ ] No plaintext passwords
  - [ ] No credit card data stored
  - [ ] Session tokens encrypted

- [ ] **File System Security**
  - [ ] Files saved di private app directory
  - [ ] Payment proofs encrypted
  - [ ] Temporary files deleted
  - [ ] No sensitive data dalam SD card

- [ ] **Cache Security**
  - [ ] Image cache doesn't contain sensitive images
  - [ ] API response cache sanitized
  - [ ] Cache cleared on logout
  - [ ] Old cache auto-cleaned

- [ ] **Clipboard Security**
  - [ ] Sensitive data not copied to clipboard
  - [ ] Clipboard cleared after use
  - [ ] Password fields prevent copy

- [ ] **Screenshot Prevention**
  - [ ] Screenshots prevented on sensitive screens (optional)
  - [ ] E-ticket screen allows screenshot (intended)
  - [ ] Payment proof screen allows screenshot (intended)

**Test Data Storage**:
```bash
# Extract app data dan check for sensitive info:
adb backup -f sipelor.ab -apk com.bedas.sipelor
# Convert to tar dan inspect
# Should not find plaintext: passwords, tokens, credit cards
```

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### M10: Insufficient Cryptography

- [ ] **Encryption Algorithms**
  - [ ] AES-256 untuk data encryption
  - [ ] Bcrypt untuk password hashing (Supabase)
  - [ ] SHA-256 untuk checksums
  - [ ] No custom/weak crypto algorithms

- [ ] **Key Management**
  - [ ] Keys tidak hardcoded
  - [ ] Keys derived properly
  - [ ] Key storage secure (Keychain/Keystore)
  - [ ] Key rotation policy exists

- [ ] **Random Number Generation**
  - [ ] Cryptographically secure RNG used
  - [ ] No predictable tokens
  - [ ] UUIDs properly generated

- [ ] **SSL/TLS**
  - [ ] Strong cipher suites only
  - [ ] No SSL 2.0/3.0
  - [ ] TLS 1.2+ required
  - [ ] Perfect Forward Secrecy enabled

**Test Weak Crypto**:
- [ ] No MD5 usage detected
- [ ] No SHA-1 usage detected
- [ ] No DES/3DES usage detected
- [ ] No ECB mode usage detected

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

## 🔍 Additional Security Checks

### Logging & Monitoring

- [ ] **Logging Security**
  - [ ] No passwords dalam logs
  - [ ] No API keys dalam logs
  - [ ] No PII dalam production logs
  - [ ] Logs sanitized before Sentry

- [ ] **Error Handling**
  - [ ] Generic error messages to user
  - [ ] Detailed errors logged securely
  - [ ] Stack traces sanitized
  - [ ] No system info leaked

- [ ] **Monitoring**
  - [ ] Sentry configured
  - [ ] Error tracking active
  - [ ] Failed login attempts tracked
  - [ ] Suspicious activity alerts

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### Authentication Deep Dive

- [ ] **Brute Force Protection**
  - [ ] Login rate limited (3 attempts/hour)
  - [ ] Password reset rate limited
  - [ ] OTP rate limited
  - [ ] IP-based limiting (optional)

- [ ] **Session Security**
  - [ ] JWT tokens used properly
  - [ ] Tokens short-lived (configurable)
  - [ ] Refresh token rotation
  - [ ] Logout invalidates tokens

- [ ] **OAuth/Social Login** (if implemented)
  - [ ] Proper redirect URI validation
  - [ ] State parameter used (CSRF protection)
  - [ ] No token leakage
  - [ ] Secure token storage

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### API Security Testing

- [ ] **Authorization Testing**
  - [ ] Cannot access other user's bookings
  - [ ] Cannot modify other user's data
  - [ ] Cannot delete other user's reviews
  - [ ] Admin-only endpoints protected
  - [ ] RLS policies prevent horizontal privilege escalation

- [ ] **Rate Limiting**
  - [ ] API calls rate limited
  - [ ] Booking creation rate limited
  - [ ] Review submission rate limited
  - [ ] Chat message rate limited

- [ ] **Input Validation**
  - [ ] All inputs validated server-side
  - [ ] File uploads validated
  - [ ] SQL injection prevented
  - [ ] XSS prevented

**Manual API Tests**:
```bash
# Test 1: Access other user's booking
curl -H "Authorization: Bearer USER1_TOKEN" \
  https://xxx.supabase.co/rest/v1/bookings?id=eq.USER2_BOOKING_ID
# Expected: Should return empty or forbidden

# Test 2: Modify other user's data
curl -X PATCH -H "Authorization: Bearer USER1_TOKEN" \
  https://xxx.supabase.co/rest/v1/profiles?id=eq.USER2_ID \
  -d '{"name":"Hacked"}'
# Expected: Should fail

# Test 3: SQL Injection
curl "https://xxx.supabase.co/rest/v1/venues?name=eq.'; DROP TABLE venues; --"
# Expected: Should be sanitized
```

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

### Penetration Testing

- [ ] **OWASP ZAP Scan**
  - [ ] Active scan completed
  - [ ] No high/critical vulnerabilities
  - [ ] False positives identified
  - [ ] Remediation completed

- [ ] **Manual Penetration Test**
  - [ ] Authentication bypass attempts
  - [ ] Authorization bypass attempts
  - [ ] SQL injection tests
  - [ ] XSS attempts
  - [ ] CSRF attempts
  - [ ] File upload vulnerabilities
  - [ ] Business logic flaws

- [ ] **Mobile-Specific Tests**
  - [ ] Insecure data storage
  - [ ] Insecure communication
  - [ ] Code injection
  - [ ] Runtime manipulation
  - [ ] Reverse engineering

**Recommended Tools**:
- OWASP ZAP (free)
- Burp Suite (paid)
- MobSF (mobile security)
- Jadx (APK decompiler)
- Frida (runtime instrumentation)

**Status**: [ ] Pass [ ] Fail [ ] Needs Review  
**Notes**: _________________________

---

## 📊 Risk Assessment Matrix

| Risk Category | Severity | Likelihood | Impact | Mitigation | Status |
|---------------|----------|------------|--------|------------|--------|
| Hardcoded secrets | 🔴 Critical | Low | High | Use --dart-define | ✅ Done |
| Weak passwords | 🟡 High | Medium | High | Password policy | ✅ Done |
| No SSL pinning | 🔴 Critical | High | Critical | Implement pinning | ✅ Done |
| Insecure storage | 🔴 Critical | Medium | High | Use secure_storage | ✅ Done |
| No encryption | 🔴 Critical | Low | Critical | AES-256 encryption | ✅ Done |
| XSS vulnerability | 🟡 High | Medium | Medium | Input sanitization | ⏳ Needs test |
| SQL injection | 🟡 High | Low | High | Supabase RLS | ✅ Done |
| No rate limiting | 🟡 High | High | Medium | Implement limits | ✅ Done |
| Session hijacking | 🔴 Critical | Low | Critical | Short-lived tokens | ✅ Done |
| MITM attack | 🔴 Critical | Low | Critical | SSL pinning | ✅ Done |

---

## ✅ Security Compliance

### GDPR Compliance (if applicable)

- [ ] Privacy policy compliant
- [ ] User consent mechanisms
- [ ] Data access rights
- [ ] Data deletion (right to be forgotten)
- [ ] Data portability
- [ ] Data breach notification process
- [ ] DPO designated (if required)

### Indonesia Privacy Law Compliance

- [ ] Privacy policy dalam Bahasa Indonesia
- [ ] User data protected
- [ ] Third-party disclosures
- [ ] Data retention policy

---

## 🎯 Audit Summary

### Critical Findings

| Finding | Severity | Status | Due Date |
|---------|----------|--------|----------|
| Example: Weak password policy | 🔴 Critical | ⏳ In Progress | 2026-02-01 |

### High Priority Findings

| Finding | Severity | Status | Due Date |
|---------|----------|--------|----------|
|  |  |  |  |

### Recommendations

1. **Immediate Actions** (Fix before launch):
   - [ ] 
   - [ ] 

2. **Short-Term** (Fix within 1 month):
   - [ ] 
   - [ ] 

3. **Long-Term** (Ongoing improvements):
   - [ ] 
   - [ ] 

---

## 📝 Audit Sign-Off

**Auditor**: _______________________  
**Date**: _______________________  
**Next Audit Date**: _______________________

**Overall Security Rating**: [ ] Excellent [ ] Good [ ] Acceptable [ ] Needs Improvement [ ] Critical Issues

**Ready for Production**: [ ] Yes [ ] No [ ] Yes with conditions

**Conditions (if any)**:
_____________________________________________
_____________________________________________

---

**Last Updated**: 28 Januari 2026  
**Version**: 1.0  
**Next Review**: Before Production Launch
