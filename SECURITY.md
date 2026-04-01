# 🔒 Security Documentation - SIPELOR BEDAS

## Overview

Dokumen ini menjelaskan fitur keamanan yang telah diimplementasikan pada aplikasi SIPELOR BEDAS untuk melindungi data pengguna dan transaksi booking.

## 🛡️ Security Features Implemented

### 1. **Input Validation & Sanitization**
**File**: `lib/security/input_sanitizer.dart`

Mencegah serangan XSS, SQL Injection, dan injeksi lainnya:

```dart
// Sanitize HTML untuk mencegah XSS
final safe = InputSanitizer.sanitizeHtml(userInput);

// Validasi email
if (InputSanitizer.isValidEmail(email)) {
  // Email valid
}

// Validasi nomor telepon Indonesia
if (InputSanitizer.isValidPhone(phone)) {
  // Nomor valid
}

// Comprehensive validation
final result = InputSanitizer.validate(
  input,
  type: InputType.email,
  maxLength: 254,
);
```

**Fitur**:
- ✅ XSS Protection (HTML sanitization)
- ✅ SQL Injection Prevention
- ✅ Email validation (RFC compliant)
- ✅ Phone number validation (format Indonesia)
- ✅ URL validation & sanitization
- ✅ File name sanitization (path traversal prevention)
- ✅ Malicious pattern detection
- ✅ Price/amount validation
- ✅ Username sanitization

### 2. **SSL Certificate Pinning**
**File**: `lib/config/ssl_config.dart`

Mencegah Man-in-the-Middle (MITM) attacks:

```dart
// Konfigurasi certificate pinning
static const String primaryCertificatePin = 
    'sha256/L/7QEnurnUJBaSMfBpa/jjyrLwAFfW3uSsAYw4KSYbQ=';

// Otomatis aktif di production
static bool get sslPinningEnabled {
  if (isProduction) {
    return true; // Selalu aktif di production
  }
  return devPinningEnabled;
}
```

**Fitur**:
- ✅ SHA-256 certificate pinning
- ✅ Multiple pins untuk certificate rotation
- ✅ Automatic production enforcement
- ✅ Domain-specific pinning

### 3. **Request Signing & Authentication**
**File**: `lib/security/request_signing.dart`

Memastikan integritas dan autentikasi request:

```dart
// Generate signed request
final headers = RequestSigning.createSignedHeaders(
  method: 'POST',
  path: '/api/bookings',
  body: bookingData,
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);

// Headers akan include:
// X-API-Key, X-Signature, X-Timestamp, X-Nonce
```

**Fitur**:
- ✅ HMAC-SHA256 request signing
- ✅ Timestamp validation (replay attack prevention)
- ✅ Nonce generation (prevent duplicate requests)
- ✅ Request body hashing
- ✅ 5-minute request window

### 4. **Security Headers Validation**
**File**: `lib/security/security_headers_validator.dart`

Validasi dan enforce security headers:

```dart
// Validate response headers
final result = SecurityHeadersValidator.validateResponseHeaders(
  responseHeaders
);

if (!result.isSecure) {
  // Handle insecure response
  print('Warnings: ${result.warnings}');
  print('Errors: ${result.errors}');
}
```

**Checked Headers**:
- ✅ Strict-Transport-Security (HSTS)
- ✅ Content-Security-Policy (CSP)
- ✅ X-Content-Type-Options
- ✅ X-Frame-Options
- ✅ X-XSS-Protection
- ✅ Referrer-Policy
- ✅ Permissions-Policy
- ✅ Cache-Control validation

### 5. **Runtime Application Self-Protection (RASP)**
**File**: `lib/security/rasp_security.dart`

Deteksi ancaman real-time:

```dart
// Perform security check
final result = await RASPSecurity.performSecurityCheck();

if (!result.isSafe) {
  // Handle security threat
  final message = RASPSecurity.getSecurityMessage(result);
  // Show warning to user or block app
}

// Start continuous monitoring
await RASPSecurity.startRuntimeMonitoring();
```

**Deteksi**:
- ✅ Root/Jailbreak detection
- ✅ Emulator/Simulator detection
- ✅ Debug mode detection
- ✅ App integrity verification
- ✅ Frida/Xposed detection
- ✅ Library injection detection
- ✅ Environment tampering detection

**Security Levels**:
- 🟢 **Safe**: Tidak ada ancaman
- 🟡 **Warning**: Masalah minor, app bisa lanjut
- 🟠 **Danger**: Masalah major, peringatan ke user
- 🔴 **Critical**: Ancaman serius, block functionality

### 6. **Secure HTTP Client**
**File**: `lib/security/secure_http_client.dart`

HTTP client dengan built-in security:

```dart
// Create secure client
final client = SecureHttpClient(
  baseUrl: 'https://api.sipelor.com',
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
  enableCertificatePinning: true,
);

// Automatic security features
final response = await client.post(
  '/bookings',
  data: bookingData,
);
```

**Features**:
- ✅ Automatic certificate pinning
- ✅ Request signing integration
- ✅ Security headers injection
- ✅ Response validation
- ✅ URL security check
- ✅ Sensitive data in URL detection

### 7. **Secure Storage**
**File**: `lib/services/secure_storage_service.dart`

Encrypted storage untuk data sensitif:

```dart
// Store credentials securely
await SecureStorageService.write(
  key: 'auth_token',
  value: token,
);

// Read securely
final token = await SecureStorageService.read(
  key: 'auth_token',
);
```

**Features**:
- ✅ Platform-specific encryption (Keychain/KeyStore)
- ✅ Encrypted SharedPreferences (Android)
- ✅ Keychain accessibility control (iOS)
- ✅ Biometric credentials storage

### 8. **Password Security**
**File**: `lib/config/security_config.dart`

Password policy enforcement:

```dart
// Password requirements
- Minimum 8 characters
- Maximum 128 characters (DoS prevention)
- Requires uppercase letter
- Requires lowercase letter
- Requires number
- Requires special character
```

### 9. **Rate Limiting**
**File**: `lib/config/security_config.dart`

Mencegah brute force dan abuse:

```dart
// Login rate limiting
- Max 5 login attempts
- 15-minute window
- 30-minute block after max attempts

// Password reset rate limiting
- Max 3 reset attempts per hour
- 2-hour block after max attempts

// Booking rate limiting
- Max 10 booking attempts per hour
```

### 10. **Session Management**
**File**: `lib/config/security_config.dart`

Secure session handling:

```dart
// Auto logout after inactivity
- Auto logout: 10 minutes inactivity
- Session token: 24 hours expiration
- Refresh token: 30 days expiration
```

### 11. **File Upload Security**
**File**: `lib/config/security_config.dart`

Validasi file upload:

```dart
// File restrictions
- Max file size: 10 MB
- Allowed images: .jpg, .jpeg, .png, .webp
- Allowed documents: .pdf
- File name sanitization
- Content-type validation
```

### 12. **OWASP Mobile Top 10 Compliance**
**File**: `lib/services/owasp_security_checks.dart`

Implementasi best practices OWASP:

- ✅ M1: Improper Platform Usage
- ✅ M2: Insecure Data Storage
- ✅ M3: Insecure Communication
- ✅ M4: Insecure Authentication
- ✅ M5: Insufficient Cryptography
- ✅ M6: Insecure Authorization
- ✅ M7: Client Code Quality
- ✅ M8: Code Tampering
- ✅ M9: Reverse Engineering
- ✅ M10: Extraneous Functionality

## 🚀 Usage Examples

### Example 1: Secure API Call with All Features

```dart
import 'package:sipelor/security/secure_http_client.dart';
import 'package:sipelor/security/input_sanitizer.dart';

Future<void> createBooking(String venueName, String userInput) async {
  // 1. Sanitize inputs
  final sanitizedVenue = InputSanitizer.sanitizeForDisplay(venueName);
  
  // 2. Validate input
  final validation = InputSanitizer.validate(
    userInput,
    type: InputType.text,
    maxLength: 500,
  );
  
  if (!validation.isValid) {
    throw Exception(validation.error);
  }
  
  // 3. Create secure client with automatic signing & pinning
  final client = SecureHttpClient(
    baseUrl: 'https://gbhprmibbcqfwjgrkfzq.supabase.co',
    apiKey: 'your-api-key',
    secretKey: 'your-secret-key',
    enableCertificatePinning: true,
  );
  
  // 4. Make secure request
  final response = await client.post(
    '/rest/v1/bookings',
    data: {
      'venue': sanitizedVenue,
      'notes': validation.sanitizedValue,
    },
  );
  
  // Response headers are automatically validated
  print('Booking created: ${response.data}');
}
```

### Example 2: App Startup Security Check

```dart
import 'package:sipelor/security/rasp_security.dart';

Future<void> performStartupSecurityCheck() async {
  // Check device security on app start
  final result = await RASPSecurity.performSecurityCheck();
  
  switch (result.securityLevel) {
    case SecurityLevel.safe:
      // Continue normally
      break;
      
    case SecurityLevel.warning:
      // Show info message
      print('⚠️  ${RASPSecurity.getSecurityMessage(result)}');
      break;
      
    case SecurityLevel.danger:
      // Show warning dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Peringatan Keamanan'),
          content: Text(RASPSecurity.getSecurityMessage(result)),
        ),
      );
      break;
      
    case SecurityLevel.critical:
      // Block app or exit
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Aplikasi Tidak Dapat Berjalan'),
          content: Text(RASPSecurity.getSecurityMessage(result)),
          actions: [
            TextButton(
              onPressed: () => exit(0),
              child: Text('Keluar'),
            ),
          ],
        ),
      );
      break;
  }
  
  // Start continuous monitoring
  await RASPSecurity.startRuntimeMonitoring();
}
```

### Example 3: Form Input with Sanitization

```dart
import 'package:sipelor/security/input_sanitizer.dart';

class BookingForm extends StatefulWidget {
  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _emailError;
  String? _phoneError;
  
  void _validateAndSubmit() {
    // Validate email
    final email = _emailController.text;
    if (!InputSanitizer.isValidEmail(email)) {
      setState(() {
        _emailError = 'Format email tidak valid';
      });
      return;
    }
    
    // Validate phone
    final phone = _phoneController.text;
    if (!InputSanitizer.isValidPhone(phone)) {
      setState(() {
        _phoneError = 'Format nomor telepon tidak valid';
      });
      return;
    }
    
    // Sanitize notes
    final notes = InputSanitizer.sanitizeForDisplay(
      _notesController.text
    );
    
    // Check for malicious patterns
    if (InputSanitizer.containsMaliciousPattern(notes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Input mengandung karakter tidak valid')),
      );
      return;
    }
    
    // Proceed with clean data
    _submitBooking(email, phone, notes);
  }
  
  // ... rest of widget
}
```

## 🔐 Security Best Practices

### For Developers

1. **Always Validate Input**
   ```dart
   // ❌ JANGAN
   final name = userInput;
   
   // ✅ LAKUKAN
   final name = InputSanitizer.sanitizeForDisplay(userInput);
   ```

2. **Use Secure Storage for Sensitive Data**
   ```dart
   // ❌ JANGAN
   prefs.setString('password', password);
   
   // ✅ LAKUKAN
   await SecureStorageService.write(key: 'password', value: password);
   ```

3. **Always Use HTTPS**
   ```dart
   // ❌ JANGAN
   final url = 'http://api.example.com';
   
   // ✅ LAKUKAN
   final url = 'https://api.example.com';
   ```

4. **Enable Certificate Pinning in Production**
   ```dart
   // Automatically enabled in production builds
   SecureHttpClient(
     baseUrl: apiUrl,
     enableCertificatePinning: SSLConfig.sslPinningEnabled,
   );
   ```

5. **Never Log Sensitive Data**
   ```dart
   // ❌ JANGAN
   print('Password: $password');
   
   // ✅ LAKUKAN
   if (kDebugMode) {
     print('Login attempt for user');
   }
   ```

### For Deployment

1. **Environment Variables**
   - Store API keys in environment variables
   - Use different keys for dev/staging/production
   - Never commit secrets to Git

2. **Certificate Pinning**
   - Update pins before certificate expiry
   - Maintain at least 2 valid pins
   - Test pin updates in staging first

3. **Security Monitoring**
   - Monitor security events in production
   - Set up alerts for suspicious activities
   - Regular security audits

4. **Regular Updates**
   - Keep dependencies updated
   - Apply security patches promptly
   - Review OWASP Mobile Top 10 annually

## 🧪 Testing Security Features

### Test Input Sanitization
```bash
flutter test test/security/input_sanitizer_test.dart
```

### Test Request Signing
```bash
flutter test test/security/request_signing_test.dart
```

### Test RASP Features
```bash
flutter test test/security/rasp_security_test.dart
```

## 📋 Security Checklist

### Before Release

- [ ] SSL certificate pinning enabled
- [ ] All inputs sanitized and validated
- [ ] Secure storage used for sensitive data
- [ ] Request signing implemented for critical APIs
- [ ] RASP security checks on app start
- [ ] Rate limiting configured
- [ ] Password policy enforced
- [ ] File upload restrictions in place
- [ ] Security headers validated
- [ ] No sensitive data in logs
- [ ] Environment variables configured
- [ ] ProGuard/R8 enabled (Android)
- [ ] Bitcode enabled (iOS)
- [ ] Security testing completed

### Regular Maintenance

- [ ] Review security logs weekly
- [ ] Update SSL certificates before expiry
- [ ] Update dependencies monthly
- [ ] Conduct security audit quarterly
- [ ] Review and update security policies annually

## 🆘 Incident Response

### If Security Breach Detected:

1. **Immediate Action**
   - Disable affected features
   - Revoke compromised tokens
   - Notify affected users

2. **Investigation**
   - Review security logs
   - Identify attack vector
   - Assess damage

3. **Remediation**
   - Patch vulnerability
   - Force password reset if needed
   - Update security measures

4. **Post-Incident**
   - Document incident
   - Update security procedures
   - Conduct security training

## 📚 References

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [OWASP Mobile Security Testing Guide](https://github.com/OWASP/owasp-mstg)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)
- [Supabase Security](https://supabase.com/docs/guides/platform/security)

## 🔄 Security Update History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-20 | 1.0.0 | Initial comprehensive security implementation |
|  |  | - Input sanitization |
|  |  | - Request signing |
|  |  | - RASP security |
|  |  | - Security headers validation |
|  |  | - Secure HTTP client |

## 📞 Security Contact

For security concerns or to report vulnerabilities:
- Email: security@sipelor.com
- Create a private security advisory on GitHub

**Do NOT disclose security vulnerabilities publicly!**

---

**Last Updated**: 2026-02-20  
**Version**: 1.0.0  
**Maintained by**: SIPELOR Development Team
