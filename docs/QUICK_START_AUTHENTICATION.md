# Quick Start Guide: Authentication Features

> Quick reference for implementing and using the new authentication features

---

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
flutter pub get
```

New dependency added:
- `sentry_flutter: ^8.11.0`

### 2. Configure Sentry (Optional but Recommended)

```bash
# Get DSN from https://sentry.io
# Add to build command:
flutter build apk --release --dart-define=SENTRY_DSN=your_dsn_here
```

### 3. Configure OAuth (if using social login)

**Android** - Add to `AndroidManifest.xml`:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.sipelor" android:host="login-callback" />
</intent-filter>
```

**iOS** - Add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.sipelor</string>
    </array>
  </dict>
</array>
```

---

## 💻 Common Use Cases

### Forgot Password

```dart
import 'package:sipelor/services/password_service.dart';

// Request password reset
final error = await PasswordService.requestPasswordReset(
  email: emailController.text,
);

if (error == null) {
  // Success message
  showSnackBar('Reset link sent to your email');
}
```

### Change Password

```dart
import 'package:sipelor/services/password_service.dart';

final error = await PasswordService.changePassword(
  oldPassword: oldPasswordController.text,
  newPassword: newPasswordController.text,
  confirmPassword: confirmPasswordController.text,
);

if (error == null) {
  showSnackBar('Password changed successfully');
}
```

### Check Email Verification

```dart
import 'package:sipelor/services/email_verification_service.dart';

// Before critical action (booking, payment, etc.)
if (!EmailVerificationService.isEmailVerified()) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Email Verification Required'),
      content: Text('Please verify your email to continue'),
      actions: [
        TextButton(
          onPressed: () async {
            await EmailVerificationService.resendVerificationEmail();
          },
          child: Text('Resend Email'),
        ),
      ],
    ),
  );
  return;
}

// Proceed with action
```

### Social Login (Google Only)

```dart
import 'package:sipelor/services/social_auth_service.dart';

// Google Sign In (only provider active)
await SocialAuthService.signInWithGoogle();

// Note: Apple and Facebook are available in code but not in UI
```

### Error Tracking

```dart
import 'package:sipelor/services/error_tracking_service.dart';

try {
  // Your code
} catch (e, stackTrace) {
  await ErrorTrackingService.logError(
    e,
    stackTrace,
    context: 'feature_name',
  );
}
```

### Add Email Verification Banner

```dart
import 'package:sipelor/widgets/email_verification_banner.dart';

Scaffold(
  body: Column(
    children: [
      EmailVerificationBanner(
        onResendTap: () async {
          await EmailVerificationService.resendVerificationEmail();
        },
      ),
      // Your content
    ],
  ),
)
```

### Navigate to Legal Documents

```dart
import 'package:sipelor/screens/privacy_policy_screen.dart';
import 'package:sipelor/screens/terms_of_service_screen.dart';

// Privacy Policy
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PrivacyPolicyScreen(),
  ),
);

// Terms of Service
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TermsOfServiceScreen(),
  ),
);
```

---

## 🧪 Run Tests

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/services/password_service_test.dart

# With coverage
flutter test --coverage
```

---

## 🔍 Troubleshooting

### OAuth not working?
1. Check Supabase Dashboard → Authentication → Providers
2. Verify OAuth credentials configured
3. Ensure redirect URLs match: `io.supabase.sipelor://login-callback/`
4. Test deep linking configuration

### Email verification not enforced?
1. Check if banner is displayed
2. Verify `EmailVerificationService.isEmailVerified()` returns false
3. Check Supabase user's `email_confirmed_at` field

### Sentry not receiving errors?
1. Verify DSN is set correctly
2. Check network connectivity
3. Ensure not in debug mode (Sentry disabled by default in debug)
4. Check Sentry dashboard for events

### Rate limiting too strict?
1. Check `rate_limiter_service.dart` for limits
2. Adjust `maxAttempts` and `window` parameters
3. Clear SharedPreferences to reset limits during testing

---

## 📚 Full Documentation

For detailed implementation guide, see:
- [Implementation Authentication Features](./IMPLEMENTATION_AUTHENTICATION_FEATURES.md)

---

**Last Updated**: 26 January 2026
