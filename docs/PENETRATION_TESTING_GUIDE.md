# 🛡️ Penetration Testing Guide - SIPELOR BEDAS

> **Comprehensive guide untuk penetration testing sebelum production launch**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026  
> **Classification**: Confidential - Internal Use Only

---

## ⚠️ IMPORTANT DISCLAIMER

**ETHICAL HACKING ONLY**

Penetration testing hanya boleh dilakukan pada:
- ✅ Development environment
- ✅ Staging environment
- ✅ Production dengan explicit permission
- ❌ NEVER on production tanpa approval
- ❌ NEVER on competitor apps

**Legal Requirements**:
- Signed authorization dari stakeholders
- Defined scope & boundaries
- Non-disclosure agreement (NDA)
- Incident response plan

---

## 🎯 Testing Objectives

1. Identify security vulnerabilities before attackers do
2. Test effectiveness dari security controls
3. Validate compliance dengan security standards
4. Provide actionable recommendations
5. Ensure data protection & privacy

---

## 🔧 Testing Environment Setup

### Required Tools

#### 1. Mobile Security Testing

**Android**:
- **MobSF** (Mobile Security Framework) - Automated scanning
- **Frida** - Dynamic instrumentation
- **Objection** - Runtime mobile exploration
- **APKTool** - APK decompilation
- **Jadx / JD-GUI** - Java decompiler
- **Drozer** - Android security assessment
- **ADB** (Android Debug Bridge)

**iOS** (when available):
- **Frida** - Dynamic instrumentation
- **Objection** - Runtime exploration
- **Class-dump** - Extract class info
- **IPA Installer** - IPA deployment
- **iMazing** - iOS device manager

#### 2. Network Security Testing

- **Burp Suite Professional** - Web vulnerability scanner & proxy
- **OWASP ZAP** - Free alternative to Burp
- **Wireshark** - Network protocol analyzer
- **mitmproxy** - Interactive HTTPS proxy
- **Charles Proxy** - HTTP debugging proxy

#### 3. Penetration Testing Distributions

- **Kali Linux** - Complete pentesting distribution
- **Parrot Security OS** - Alternative to Kali
- **Android Tamer** - Mobile-focused pentesting OS

#### 4. Additional Tools

- **Nmap** - Network scanner
- **SQLMap** - SQL injection tool
- **John the Ripper** - Password cracker
- **Hashcat** - Advanced password recovery
- **Metasploit** - Exploitation framework

### Testing Device Setup

**Rooted Android Device** (recommended):
- Android 10+ dengan root access
- Frida server installed
- Xposed Framework (optional)
- SSL Kill Switch 2 (for bypassing SSL pinning)

**Non-rooted Testing** (limited):
- Can still test many vulnerabilities
- Use VPN-based MITM (e.g., HTTP Toolkit)
- Limited to runtime analysis

---

## 📱 Phase 1: Static Application Security Testing (SAST)

### 1.1 APK Analysis

#### Extract & Decompile APK

```bash
# Download APK from device
adb pull /data/app/com.bedas.sipelor-1/base.apk sipelor.apk

# Decompile dengan apktool
apktool d sipelor.apk -o sipelor_decompiled

# Decompile ke Java code dengan jadx
jadx -d sipelor_src sipelor.apk
```

#### Automated Scanning dengan MobSF

```bash
# Run MobSF (Docker)
docker pull opensecurity/mobile-security-framework-mobsf
docker run -it -p 8000:8000 opensecurity/mobile-security-framework-mobsf

# Upload APK via web interface: http://localhost:8000
# Review scan results
```

**Key Findings to Check**:
- [ ] Hardcoded API keys/secrets
- [ ] Insecure random number generation
- [ ] Weak cryptography usage
- [ ] Insecure data storage
- [ ] Dangerous permissions
- [ ] Exported activities/services
- [ ] Debug mode enabled
- [ ] Backup enabled (android:allowBackup)
- [ ] Clear text traffic allowed
- [ ] Weak WebView configuration

### 1.2 AndroidManifest.xml Review

Check `AndroidManifest.xml` untuk:

```xml
<!-- ❌ BAD: Backup enabled (data leakage risk) -->
<application android:allowBackup="true">

<!-- ✅ GOOD: Backup disabled -->
<application android:allowBackup="false">

<!-- ❌ BAD: Cleartext traffic allowed -->
<application android:usesCleartextTraffic="true">

<!-- ✅ GOOD: Only HTTPS -->
<application android:usesCleartextTraffic="false">

<!-- ❌ BAD: Exported component without permission -->
<activity android:name=".AdminActivity" android:exported="true" />

<!-- ✅ GOOD: Protected with permission -->
<activity 
    android:name=".AdminActivity" 
    android:exported="true"
    android:permission="android.permission.ADMIN_ONLY" />

<!-- Check all dangerous permissions -->
<uses-permission android:name="android.permission.READ_CONTACTS" />
<!-- ^ Is this really needed? -->
```

### 1.3 Source Code Review

Review decompiled code untuk:

**1. Hardcoded Secrets**:

```bash
# Search for common secret patterns
grep -r "api_key" sipelor_src/
grep -r "password" sipelor_src/
grep -r "secret" sipelor_src/
grep -r "token" sipelor_src/
grep -r "supabase" sipelor_src/

# Check for base64 encoded secrets
grep -r "Base64" sipelor_src/
```

**2. Insecure Crypto**:

```bash
# Check for weak algorithms
grep -r "DES" sipelor_src/
grep -r "MD5" sipelor_src/
grep -r "SHA1" sipelor_src/
grep -r "ECB" sipelor_src/

# Check for insecure random
grep -r "Random()" sipelor_src/
# Should use: SecureRandom()
```

**3. SQL Injection Vectors**:

```bash
# Check for string concatenation in queries
grep -r "SELECT.*+" sipelor_src/
grep -r "WHERE.*+" sipelor_src/
```

**4. Logging Sensitive Data**:

```bash
# Check for debug logs
grep -r "Log.d" sipelor_src/
grep -r "Log.v" sipelor_src/
grep -r "print(" sipelor_src/ # Flutter
```

### 1.4 Dependency Vulnerability Scan

```bash
# Check Flutter dependencies
cd sipelor/
flutter pub outdated

# Generate dependency tree
flutter pub deps

# Check for known vulnerabilities
# (Manual check against CVE database)
```

---

## 🔍 Phase 2: Dynamic Application Security Testing (DAST)

### 2.1 Setup MITM Proxy

#### Configure Burp Suite

1. **Install Burp Certificate on Android**:

```bash
# Export Burp CA certificate
# Burp Suite → Proxy → Options → Import/Export CA certificate → Export → DER format

# Push to device
adb push cacert.der /sdcard/

# Install certificate
# Settings → Security → Encryption & credentials → Install from SD card
```

2. **Configure Proxy on Android**:

```
Settings → WiFi → Long press network → Modify network
→ Advanced → Proxy: Manual
→ Hostname: Your PC IP (e.g., 192.168.1.10)
→ Port: 8080
```

3. **Verify Interception**:

```
Open browser → Visit http://burp
Should see "Burp Suite" page
```

#### Bypass SSL Pinning

**Method 1: Frida Script**

```bash
# Start Frida server on device
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server"
adb shell "/data/local/tmp/frida-server &"

# Run SSL pinning bypass script
frida -U -f com.bedas.sipelor -l ssl-pinning-bypass.js --no-pause
```

**ssl-pinning-bypass.js**:

```javascript
Java.perform(function() {
    // Bypass certificate pinning
    var CertificatePinner = Java.use("okhttp3.CertificatePinner");
    CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function(str, list) {
        console.log("[+] Bypassing SSL pinning for: " + str);
        return;
    };
    
    console.log("[+] SSL Pinning bypass loaded");
});
```

**Method 2: Objection**

```bash
# Start objection
objection -g com.bedas.sipelor explore

# Disable SSL pinning
android sslpinning disable

# Test by browsing app
# All HTTPS traffic should now be interceptable
```

### 2.2 Authentication Testing

#### Test 1: Brute Force Protection

```bash
# Use Burp Intruder untuk test rate limiting
# Intercept login request
# Send to Intruder
# Set password as payload position
# Load password list (rockyou.txt)
# Start attack

# Expected: After 3 attempts, account locked for 1 hour
```

**Verify**:
- [ ] Account locked after 3 failed attempts
- [ ] Lockout duration is 1 hour
- [ ] Lockout message clear to user
- [ ] Admin can unlock account
- [ ] Failed attempts logged

#### Test 2: Session Management

```bash
# Test 1: Session fixation
# 1. Get session token before login
# 2. Login
# 3. Check if token changed
# Expected: Token should change after login

# Test 2: Session timeout
# 1. Login
# 2. Wait 15 minutes
# 3. Try API call
# Expected: Session expired error

# Test 3: Concurrent sessions
# 1. Login on device A
# 2. Login on device B with same account
# 3. Check if device A logged out
# Expected: Device A should be logged out (or limited concurrent sessions)
```

#### Test 3: Password Reset Flow

```bash
# Test for account enumeration
# 1. Request password reset untuk email@exists.com
# 2. Request password reset untuk email@notexist.com
# 3. Compare responses
# Expected: Same response (no enumeration)

# Test token expiry
# 1. Request password reset
# 2. Wait 61 minutes
# 3. Try to use token
# Expected: Token expired error

# Test token reuse
# 1. Reset password dengan token
# 2. Try to reuse same token
# Expected: Token invalid/used error
```

### 2.3 Authorization Testing

#### Test Horizontal Privilege Escalation

```bash
# Scenario: User A tries to access User B's data

# Test 1: View other user's bookings
GET /bookings?user_id=USER_B_ID
Authorization: Bearer USER_A_TOKEN

# Expected: Empty result atau Forbidden

# Test 2: Modify other user's profile
PATCH /profiles/USER_B_ID
Authorization: Bearer USER_A_TOKEN
Content: {"name":"Hacked"}

# Expected: 403 Forbidden

# Test 3: Delete other user's review
DELETE /reviews/REVIEW_BY_USER_B
Authorization: Bearer USER_A_TOKEN

# Expected: 403 Forbidden
```

#### Test Vertical Privilege Escalation

```bash
# Scenario: Regular user tries to access admin functions

# Test 1: Access admin dashboard
GET /admin/dashboard
Authorization: Bearer USER_TOKEN

# Expected: 403 Forbidden

# Test 2: Approve booking (admin only)
PATCH /bookings/BOOKING_ID
Authorization: Bearer USER_TOKEN
Content: {"status":"confirmed"}

# Expected: 403 Forbidden

# Test 3: View all users (admin only)
GET /admin/users
Authorization: Bearer USER_TOKEN

# Expected: 403 Forbidden
```

### 2.4 Input Validation Testing

#### Test SQL Injection

```bash
# Test 1: Login SQL injection
POST /auth/login
Content: {
  "email": "admin'--",
  "password": "anything"
}

# Expected: Login should fail (input sanitized)

# Test 2: Search SQL injection
GET /venues?name=' OR '1'='1

# Expected: No results atau error (input sanitized)

# Test 3: Boolean-based blind SQL injection
GET /venues?id=1' AND '1'='1
GET /venues?id=1' AND '1'='2

# Expected: Same response (no SQL injection)
```

#### Test XSS (Cross-Site Scripting)

```bash
# Test 1: Stored XSS dalam review
POST /reviews
Content: {
  "text": "<script>alert('XSS')</script>",
  "rating": 5
}

# Then view review
GET /reviews/REVIEW_ID

# Expected: Script tag sanitized, no alert

# Test 2: Reflected XSS dalam search
GET /search?q=<script>alert('XSS')</script>

# Expected: No script execution

# Test 3: DOM-based XSS
# Check if user input directly inserted into DOM
# Review decompiled Flutter code
```

#### Test File Upload Vulnerabilities

```bash
# Test 1: Upload executable
# Try upload .exe, .apk, .sh file as payment proof
# Expected: Only JPG/PNG allowed

# Test 2: Upload oversized file
# Upload 20MB image
# Expected: Max 5MB error

# Test 3: Upload with malicious filename
# Upload file dengan nama: ../../etc/passwd.jpg
# Expected: Filename sanitized

# Test 4: Upload PHP webshell
# Upload PHP file disguised as image
# Expected: File type validation based on content, not extension
```

### 2.5 Business Logic Testing

#### Test Payment Bypass

```bash
# Test 1: Book tanpa payment
# 1. Start booking flow
# 2. Intercept payment confirmation request
# 3. Modify status to "paid" in request
# Expected: Server-side validation prevents this

# Test 2: Modify price
# 1. Start booking untuk Rp 150.000
# 2. Intercept request
# 3. Change amount to Rp 1.000
# Expected: Server recalculates price, tidak accept client-side price

# Test 3: Expired booking reuse
# 1. Let booking expire
# 2. Try to upload payment proof
# Expected: Booking already cancelled error
```

#### Test Booking Logic

```bash
# Test 1: Double booking
# 1. Book slot 09:00-10:00 dengan user A
# 2. Simultaneously book same slot dengan user B
# Expected: Only one succeeds (race condition handled)

# Test 2: Past date booking
# 1. Try book yesterday's date
# Expected: Error - cannot book past dates

# Test 3: Overlapping bookings
# 1. Book 09:00-11:00
# 2. Try book 10:00-12:00 (overlaps)
# Expected: Slot not available
```

### 2.6 API Security Testing

#### Test Rate Limiting

```bash
# Test booking creation rate limit
for i in {1..100}; do
  curl -X POST https://api.sipelor/bookings \
    -H "Authorization: Bearer TOKEN" \
    -d '{"venue_id":"xxx","date":"2026-02-01"}'
done

# Expected: After X requests, rate limit error

# Test login rate limit
for i in {1..10}; do
  curl -X POST https://api.sipelor/auth/login \
    -d '{"email":"test@test.com","password":"wrong"}'
done

# Expected: After 3 attempts, account locked
```

#### Test API Authentication

```bash
# Test 1: No authentication token
GET /bookings
# Expected: 401 Unauthorized

# Test 2: Invalid token
GET /bookings
Authorization: Bearer INVALID_TOKEN
# Expected: 401 Unauthorized

# Test 3: Expired token
GET /bookings
Authorization: Bearer EXPIRED_TOKEN
# Expected: 401 Unauthorized

# Test 4: Token from different user
GET /bookings/USER_A_BOOKING
Authorization: Bearer USER_B_TOKEN
# Expected: 403 Forbidden
```

---

## 📲 Phase 3: Runtime Analysis

### 3.1 Memory Dump Analysis

```bash
# Dump app memory
adb shell "su -c cat /proc/$(pidof com.bedas.sipelor)/maps"

# Search for sensitive data dalam memory
strings memory_dump | grep -i "password"
strings memory_dump | grep -i "token"
strings memory_dump | grep -i "api"

# Expected: No plaintext passwords/tokens dalam memory
```

### 3.2 Local Storage Analysis

```bash
# Extract app data
adb backup -f sipelor.ab -apk com.bedas.sipelor

# Convert to tar
dd if=sipelor.ab bs=24 skip=1 | openssl zlib -d > sipelor.tar

# Extract
tar xvf sipelor.tar

# Inspect databases
cd apps/com.bedas.sipelor/db/
sqlite3 database.db

# Check for sensitive data
.tables
SELECT * FROM users;  # Should not have plaintext passwords
SELECT * FROM sessions;  # Tokens should be encrypted

# Check SharedPreferences
cd ../sp/
cat *.xml

# Expected: No plaintext sensitive data
```

### 3.3 Network Traffic Analysis

```bash
# Capture network traffic
adb shell "tcpdump -i wlan0 -w /sdcard/capture.pcap"

# Analyze dalam Wireshark
# Check for:
# - Unencrypted HTTP traffic (should be none)
# - Sensitive data dalam URLs
# - Weak TLS versions
# - Insecure cipher suites
```

---

## 🔒 Phase 4: Specific Security Feature Testing

### 4.1 Test SSL Certificate Pinning

```bash
# Without bypass
# 1. Setup Burp proxy
# 2. Open app
# 3. Try to browse venues

# Expected: Connection should FAIL (pinning working)

# With bypass (Frida/Objection)
# 1. Bypass SSL pinning
# 2. Open app
# 3. Browse venues

# Expected: Can intercept traffic (confirms pinning exists and can be bypassed by determined attacker)
```

### 4.2 Test Data Encryption

```bash
# Test encrypted local storage
adb shell
cd /data/data/com.bedas.sipelor/app_flutter/

# Check secure storage
cat *.json

# Expected: Encrypted data, not plaintext

# Test payment proof encryption
cd files/payment_proofs/
file *.jpg

# Expected: If encryption enabled, should show encrypted file
```

### 4.3 Test Biometric Authentication

```bash
# Test 1: Bypass biometric dengan fingerprint
# 1. Enable biometric login
# 2. Logout
# 3. Try login dengan unregistered fingerprint
# Expected: Login fails

# Test 2: Fallback to password
# 1. Cancel biometric prompt
# 2. Should offer password fallback
# Expected: Can login dengan password

# Test 3: Biometric after device restart
# 1. Enable biometric
# 2. Restart device
# 3. Try biometric login
# Expected: May require password first (security best practice)
```

---

## 📊 Phase 5: Reporting & Remediation

### Vulnerability Classification

Use CVSS (Common Vulnerability Scoring System):

| Severity | Score | Action | Example |
|----------|-------|--------|---------|
| 🔴 Critical | 9.0-10.0 | Fix immediately | Hardcoded API keys, SQL injection |
| 🟠 High | 7.0-8.9 | Fix before launch | XSS, weak encryption |
| 🟡 Medium | 4.0-6.9 | Fix soon | Info disclosure, CSRF |
| 🟢 Low | 0.1-3.9 | Fix eventually | Verbose errors, outdated libs |

### Report Template

```markdown
## Vulnerability Report

**Title**: SQL Injection dalam Search Function

**Severity**: 🔴 Critical (CVSS 9.8)

**Affected Component**: /api/venues/search endpoint

**Description**:
The venue search endpoint is vulnerable to SQL injection. An attacker can inject malicious SQL code through the 'name' parameter.

**Steps to Reproduce**:
1. Send GET request to /api/venues/search?name=' OR '1'='1
2. Observe that all venues are returned, bypassing search filter

**Proof of Concept**:
```bash
curl "https://api.sipelor.com/venues/search?name=' OR '1'='1"
```

**Impact**:
- Unauthorized data access
- Potential data modification/deletion
- Database compromise

**Recommendation**:
1. Use parameterized queries (Supabase handles this if using .select() properly)
2. Implement input validation
3. Use prepared statements
4. Apply principle of least privilege untuk database user

**References**:
- OWASP SQL Injection: https://owasp.org/www-community/attacks/SQL_Injection
- CWE-89: https://cwe.mitre.org/data/definitions/89.html
```

---

## ✅ Final Checklist

### Pre-Launch Security Verification

- [ ] All Critical vulnerabilities fixed
- [ ] All High vulnerabilities fixed
- [ ] Medium vulnerabilities assessed (fix or accept risk)
- [ ] Low vulnerabilities documented
- [ ] Re-test all fixed vulnerabilities
- [ ] Third-party security audit completed (if budget allows)
- [ ] Penetration test report reviewed by management
- [ ] Incident response plan ready
- [ ] Security monitoring active (Sentry)
- [ ] Backup & disaster recovery tested

---

## 📚 Additional Resources

### Learning Resources

- **OWASP Mobile Security Testing Guide**: https://mobile-security.gitbook.io/
- **OWASP Top 10 Mobile**: https://owasp.org/www-project-mobile-top-10/
- **Android Security Documentation**: https://source.android.com/security
- **Supabase Security Best Practices**: https://supabase.com/docs/guides/security

### Tools & Cheat Sheets

- **Mobile Pentesting Cheat Sheet**: https://github.com/tanprathan/MobileApp-Pentest-Cheatsheet
- **Frida Codeshare**: https://codeshare.frida.re/
- **Burp Suite Extensions**: https://portswigger.net/bappstore

---

**Last Updated**: 28 Januari 2026  
**Security Team**: Development & IT Security  
**Next Audit**: After major updates or annually

**⚠️ CONFIDENTIAL - DO NOT SHARE EXTERNALLY**
