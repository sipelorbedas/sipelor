# 🔐 Security & Penetration Testing Checklist - SIPELOR BEDAS

> **Version**: 1.0.0  
> **Last Updated**: 28 Januari 2026  
> **Security Level**: High (Handles payments and personal data)

---

## 🎯 Security Testing Objectives

- Identify vulnerabilities before production deployment
- Verify security controls are working correctly
- Ensure compliance with security best practices
- Protect user data and payment information
- Prevent unauthorized access and data breaches

---

## 🔑 Authentication Security

### Password Security
- [ ] **Test**: Weak passwords are rejected
  - Try: "123456", "password", "abc123"
  - Expected: Validation error with requirements
- [ ] **Test**: Password is not visible in network logs
  - Use: Network inspector, Wireshark
  - Expected: Password is hashed/encrypted
- [ ] **Test**: Password is not stored in plain text
  - Check: Database, local storage, logs
  - Expected: Hashed with bcrypt/argon2
- [ ] **Test**: Password reset link expires
  - Use: Password reset feature
  - Expected: Link expires after use or timeout

### Brute Force Protection
- [ ] **Test**: Rate limiting on login
  - Try: 10 rapid login attempts
  - Expected: Blocked after 5 attempts, lockout message
- [ ] **Test**: Account lockout after failed attempts
  - Try: Multiple wrong passwords
  - Expected: Account locked for X minutes
- [ ] **Test**: Rate limiting on password reset
  - Try: Multiple reset requests
  - Expected: Limited to 3 per hour

### Session Management
- [ ] **Test**: Session expires after inactivity
  - Wait: 15+ minutes without activity
  - Expected: Auto logout, redirect to login
- [ ] **Test**: Session invalidated on logout
  - Logout, then use old session token
  - Expected: 401 Unauthorized
- [ ] **Test**: Multiple device sessions
  - Login on 2 devices simultaneously
  - Expected: Both sessions valid OR forced logout on one
- [ ] **Test**: Session hijacking prevention
  - Copy session token, use in another browser
  - Expected: Token validation fails (IP/device check)

### Token Security
- [ ] **Test**: JWT tokens have expiration
  - Check: Token payload
  - Expected: "exp" claim exists, reasonable duration
- [ ] **Test**: Refresh token works correctly
  - Wait for access token to expire
  - Expected: Auto refresh without re-login
- [ ] **Test**: Revoked tokens are rejected
  - Logout, then use old token
  - Expected: 401 Unauthorized

---

## 🛡️ Authorization & Access Control

### User Data Access
- [ ] **Test**: User can only access own data
  - Try: Change user_id in API request
  - Expected: 403 Forbidden or empty result
- [ ] **Test**: User cannot access admin endpoints
  - Try: Access /admin/* endpoints as user
  - Expected: 403 Forbidden
- [ ] **Test**: User cannot modify others' bookings
  - Try: Cancel another user's booking
  - Expected: 403 Forbidden

### Admin Access Control
- [ ] **Test**: Admin role verification
  - Try: Access admin features as regular user
  - Expected: Access denied
- [ ] **Test**: Role-based permissions work
  - Test: Different roles (Admin, Manager, Operator)
  - Expected: Each role has correct permissions
- [ ] **Test**: Staff cannot escalate privileges
  - Try: Change own role to Admin
  - Expected: 403 Forbidden

### API Security
- [ ] **Test**: Unauthorized API access blocked
  - Try: API calls without auth token
  - Expected: 401 Unauthorized
- [ ] **Test**: CORS policy is restrictive
  - Try: API call from unauthorized domain
  - Expected: CORS error
- [ ] **Test**: API rate limiting works
  - Try: 100 rapid API calls
  - Expected: 429 Too Many Requests

---

## 💉 Injection Attacks

### SQL Injection
- [ ] **Test**: SQL injection in login
  - Try: email = `' OR '1'='1' --`
  - Expected: Login fails, no SQL error
- [ ] **Test**: SQL injection in search
  - Try: search = `'; DROP TABLE users; --`
  - Expected: No database modification
- [ ] **Test**: Prepared statements used
  - Check: Supabase RLS policies
  - Expected: All queries use parameterized queries

### NoSQL Injection (if applicable)
- [ ] **Test**: NoSQL injection in queries
  - Try: `{"$gt": ""}` in JSON payload
  - Expected: Query fails safely

### Command Injection
- [ ] **Test**: File upload command injection
  - Try: Upload file named `; rm -rf /`
  - Expected: Filename sanitized
- [ ] **Test**: URL parameter command injection
  - Try: `param=value; ls -la`
  - Expected: Parameter sanitized

---

## 🌐 Cross-Site Scripting (XSS)

### Reflected XSS
- [ ] **Test**: XSS in search query
  - Try: `<script>alert('XSS')</script>`
  - Expected: Script does not execute
- [ ] **Test**: XSS in error messages
  - Try: Invalid input with `<script>` tags
  - Expected: Tags escaped in error display

### Stored XSS
- [ ] **Test**: XSS in review comments
  - Try: Post review with `<script>alert('XSS')</script>`
  - Expected: Script escaped, not executed
- [ ] **Test**: XSS in chat messages
  - Try: Send message with XSS payload
  - Expected: Message sanitized
- [ ] **Test**: XSS in user profile
  - Try: Set name to `<img src=x onerror=alert('XSS')>`
  - Expected: Tags escaped

### DOM-based XSS
- [ ] **Test**: XSS via URL fragments
  - Try: `#<script>alert('XSS')</script>`
  - Expected: Fragment not executed

---

## 🔓 Cross-Site Request Forgery (CSRF)

- [ ] **Test**: CSRF token on forms
  - Check: Form submissions include CSRF token
  - Expected: Token validated on server
- [ ] **Test**: CSRF on critical actions
  - Try: Trigger booking without CSRF token
  - Expected: Request rejected
- [ ] **Test**: SameSite cookie attribute
  - Check: Cookie headers
  - Expected: `SameSite=Strict` or `Lax`

---

## 📁 File Upload Security

### File Type Validation
- [ ] **Test**: Upload executable file
  - Try: Upload .exe, .sh, .bat file
  - Expected: Rejected with error message
- [ ] **Test**: Upload file with double extension
  - Try: Upload file.jpg.php
  - Expected: Detected and rejected
- [ ] **Test**: Upload file with no extension
  - Try: Upload file without extension
  - Expected: Rejected or forced extension
- [ ] **Test**: MIME type validation
  - Try: Rename .exe to .jpg, upload
  - Expected: MIME type checked, rejected

### File Size Validation
- [ ] **Test**: Upload oversized file
  - Try: Upload 100MB image
  - Expected: Rejected, error message with limit
- [ ] **Test**: Zip bomb attack
  - Try: Upload small file that expands to GB
  - Expected: Decompression prevented or limited

### File Content Validation
- [ ] **Test**: Upload image with embedded code
  - Try: Upload SVG with `<script>` tag
  - Expected: Script stripped or file rejected
- [ ] **Test**: Upload malformed image
  - Try: Upload corrupted image file
  - Expected: Validation fails gracefully

### File Storage Security
- [ ] **Test**: Uploaded files are not executable
  - Check: File permissions on server
  - Expected: No execute permission
- [ ] **Test**: Direct file access is restricted
  - Try: Access uploaded file URL directly
  - Expected: Authorization required or signed URL
- [ ] **Test**: File encryption at rest
  - Check: Payment proof files
  - Expected: Files encrypted with AES-256

---

## 🔐 Encryption & Data Protection

### Data in Transit
- [ ] **Test**: All traffic uses HTTPS
  - Check: All API calls
  - Expected: No HTTP requests
- [ ] **Test**: SSL/TLS version
  - Check: Certificate details
  - Expected: TLS 1.2 or higher
- [ ] **Test**: SSL certificate validation
  - Try: Connect with invalid cert
  - Expected: Connection rejected
- [ ] **Test**: Certificate pinning works
  - Try: MITM proxy (e.g., Charles, mitmproxy)
  - Expected: Connection fails due to pinning

### Data at Rest
- [ ] **Test**: Sensitive data is encrypted
  - Check: Database, local storage
  - Expected: Passwords, tokens, PII encrypted
- [ ] **Test**: Encryption keys are secure
  - Check: Key storage location
  - Expected: Keys in secure storage, not in code
- [ ] **Test**: Encrypted preferences service
  - Check: Stored preferences
  - Expected: Data encrypted with AES-256

### Sensitive Data Exposure
- [ ] **Test**: No passwords in logs
  - Check: Debug logs, crash reports
  - Expected: Passwords redacted
- [ ] **Test**: No tokens in logs
  - Check: Network logs, debug output
  - Expected: Tokens redacted or masked
- [ ] **Test**: No PII in error messages
  - Trigger errors, check messages
  - Expected: Generic errors, no user data
- [ ] **Test**: No sensitive data in URLs
  - Check: URL parameters
  - Expected: Use POST body, not GET params

---

## 🔍 Security Misconfiguration

### Debug Mode
- [ ] **Test**: Debug mode is off in production
  - Check: Build flags, environment
  - Expected: kDebugMode = false in release
- [ ] **Test**: No debug endpoints exposed
  - Try: Access /debug, /test endpoints
  - Expected: 404 Not Found

### Error Handling
- [ ] **Test**: Generic error messages
  - Trigger various errors
  - Expected: User-friendly messages, no stack traces
- [ ] **Test**: No sensitive info in errors
  - Check: Error responses
  - Expected: No database names, paths, versions

### Security Headers (Web)
- [ ] **Test**: X-Frame-Options header
  - Check: Response headers
  - Expected: `DENY` or `SAMEORIGIN`
- [ ] **Test**: X-Content-Type-Options
  - Expected: `nosniff`
- [ ] **Test**: Content-Security-Policy
  - Expected: Restrictive CSP
- [ ] **Test**: Strict-Transport-Security
  - Expected: HSTS enabled

---

## 📱 Mobile-Specific Security

### Local Storage
- [ ] **Test**: Secure storage for tokens
  - Check: FlutterSecureStorage usage
  - Expected: Tokens in secure storage, not SharedPreferences
- [ ] **Test**: App data in backups
  - Check: Android/iOS backup settings
  - Expected: Sensitive data excluded from backups
- [ ] **Test**: Clipboard security
  - Copy sensitive data, check clipboard
  - Expected: Passwords auto-clear from clipboard

### App Security
- [ ] **Test**: Root/jailbreak detection
  - Test on rooted/jailbroken device
  - Expected: Warning or restricted functionality
- [ ] **Test**: Screenshot prevention
  - Try: Screenshot on sensitive screens
  - Expected: Prevented on payment/password screens
- [ ] **Test**: App signature verification
  - Try: Install modified APK
  - Expected: Installation fails or app detects tampering

### Deep Link Security
- [ ] **Test**: Deep link validation
  - Try: Malicious deep link
  - Expected: URL validated, rejected if invalid
- [ ] **Test**: Deep link token validation
  - Try: Deep link with expired token
  - Expected: Token validated, rejected if expired

---

## 🚨 Business Logic Vulnerabilities

### Payment Flow
- [ ] **Test**: Price manipulation
  - Try: Modify price in booking request
  - Expected: Server validates price, rejects
- [ ] **Test**: Double booking
  - Try: Book same slot simultaneously (2 devices)
  - Expected: Only one booking succeeds
- [ ] **Test**: Payment proof tampering
  - Try: Upload fake payment proof
  - Expected: Admin manually verifies (can't automate)
- [ ] **Test**: Booking without payment
  - Try: Access e-ticket without payment
  - Expected: Access denied until approved

### Booking Logic
- [ ] **Test**: Expired booking exploitation
  - Try: Use expired booking after 30 min
  - Expected: Booking auto-cancelled
- [ ] **Test**: Time slot manipulation
  - Try: Book past date or invalid time
  - Expected: Validation error
- [ ] **Test**: Capacity limits
  - Try: Exceed max bookings per user/day
  - Expected: Limit enforced

### Review System
- [ ] **Test**: Review without booking
  - Try: Review venue without booking
  - Expected: Only users with completed bookings can review
- [ ] **Test**: Multiple reviews per booking
  - Try: Review same booking twice
  - Expected: Only one review allowed
- [ ] **Test**: Rating manipulation
  - Try: Submit invalid rating (e.g., 10 stars)
  - Expected: Rating limited to 1-5

---

## 🛑 Denial of Service (DoS)

### Rate Limiting
- [ ] **Test**: API rate limiting
  - Send 1000 requests in 1 minute
  - Expected: 429 Too Many Requests after threshold
- [ ] **Test**: Login rate limiting
  - Try 20 login attempts rapidly
  - Expected: Blocked after 5 attempts

### Resource Exhaustion
- [ ] **Test**: Large payload handling
  - Send very large JSON payload
  - Expected: Request size limit enforced
- [ ] **Test**: Regex DoS
  - Send complex regex patterns
  - Expected: Timeout or rejection
- [ ] **Test**: Recursive requests
  - Try to create circular references
  - Expected: Depth limit enforced

---

## 📊 Monitoring & Logging

### Error Tracking
- [ ] **Test**: Errors are logged to Sentry
  - Trigger an error
  - Expected: Error appears in Sentry dashboard
- [ ] **Test**: Sensitive data not in error logs
  - Check Sentry logs
  - Expected: Passwords, tokens filtered
- [ ] **Test**: User context in errors
  - Trigger error while logged in
  - Expected: User ID logged (not PII)

### Audit Logs
- [ ] **Test**: Critical actions are logged
  - Perform admin actions (approve, delete)
  - Expected: Actions appear in audit log
- [ ] **Test**: Audit logs are immutable
  - Try to delete/modify audit log
  - Expected: Not possible
- [ ] **Test**: Audit log retention
  - Check old logs (>6 months)
  - Expected: Logs retained per policy

---

## 🔧 Security Tools & Testing

### Automated Scanning
- [ ] **Tool**: OWASP ZAP scan
  - Run passive and active scans
  - Review findings, fix critical issues
- [ ] **Tool**: Burp Suite scan
  - Intercept and analyze traffic
  - Test for common vulnerabilities
- [ ] **Tool**: SQLMap (if applicable)
  - Test for SQL injection
  - Expected: No vulnerabilities found

### Manual Testing
- [ ] **Tool**: Postman / Insomnia
  - Test API endpoints with various payloads
  - Verify authentication and authorization
- [ ] **Tool**: Charles Proxy / mitmproxy
  - Intercept mobile app traffic
  - Verify SSL pinning works
  - Check for sensitive data in requests
- [ ] **Tool**: Wireshark
  - Capture network traffic
  - Verify all traffic is encrypted

### Code Analysis
- [ ] **Tool**: Dart analysis
  - Run `flutter analyze`
  - Fix all warnings and errors
- [ ] **Review**: Security best practices
  - Check for hardcoded secrets
  - Check for insecure random number generation
  - Check for weak crypto algorithms

---

## ✅ Security Compliance Checklist

### OWASP Top 10 (2021)
- [ ] A01: Broken Access Control
- [ ] A02: Cryptographic Failures
- [ ] A03: Injection
- [ ] A04: Insecure Design
- [ ] A05: Security Misconfiguration
- [ ] A06: Vulnerable Components
- [ ] A07: Authentication Failures
- [ ] A08: Software and Data Integrity
- [ ] A09: Security Logging and Monitoring
- [ ] A10: Server-Side Request Forgery

### Mobile Security (OWASP MASVS)
- [ ] Secure data storage
- [ ] Secure communication
- [ ] Authentication and session management
- [ ] Code quality and build settings
- [ ] Resilience against reverse engineering

---

## 📝 Remediation Priority

### Critical (Fix immediately)
- SQL injection vulnerabilities
- Authentication bypass
- Sensitive data exposure
- Remote code execution

### High (Fix before production)
- XSS vulnerabilities
- CSRF vulnerabilities
- Insecure file uploads
- Weak encryption

### Medium (Fix in next sprint)
- Information disclosure
- Weak password policy
- Missing security headers
- Insufficient logging

### Low (Fix when possible)
- Minor configuration issues
- Non-critical information leaks
- UI/UX security improvements

---

## ✅ Sign-off

**Security Tester**: _____________________  
**Date**: _____________________  
**Build Version**: _____________________  

**Security Status**: 
- [ ] Secure (ready for production)
- [ ] Minor issues (can deploy with monitoring)
- [ ] Major issues (requires fixes before deploy)
- [ ] Critical issues (DO NOT DEPLOY)

**Critical Findings**: _____________________  
**High Findings**: _____________________  
**Medium Findings**: _____________________  
**Low Findings**: _____________________  

**Recommendations**:
_________________________________________________________
_________________________________________________________
_________________________________________________________
