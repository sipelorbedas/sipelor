# 🔗 Deep Links Configuration - SIPELOR BEDAS

> **Complete guide untuk setup deep linking di Android & iOS**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026  
> **Status**: ✅ Configured (Android), ⏳ Pending (iOS)

---

## 🎯 Overview

Deep links memungkinkan app untuk dibuka dari:
- Email (password reset, verification)
- SMS/WhatsApp
- Website links
- Push notifications
- QR codes

**SIPELOR BEDAS Deep Link Scheme**: `sipelor://`

---

## 📱 Android Configuration

### Status: ✅ Already Configured

Deep links sudah dikonfigurasi di `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Custom scheme for password reset -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="sipelor"/>
</intent-filter>

<!-- Supabase auth callback scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="io.supabase.sipelor"
          android:host="login-callback"/>
</intent-filter>
```

### Supported Deep Links

| Link Pattern | Purpose | Example |
|--------------|---------|---------|
| `sipelor://reset-password?token=XXX` | Password reset | From email |
| `sipelor://verify-email?token=XXX` | Email verification | From email |
| `sipelor://booking/:id` | View booking detail | From notification |
| `sipelor://ticket/:id` | View e-ticket | From notification |
| `sipelor://venue/:id` | View venue detail | From sharing |
| `sipelor://chat/:bookingId` | Open chat | From notification |
| `io.supabase.sipelor://login-callback` | OAuth callback | Supabase auth |

---

## 🍎 iOS Configuration

### Status: ⏳ Needs Setup

#### Step 1: Update Info.plist

Edit `ios/Runner/Info.plist`:

```xml
<!-- Add URL schemes -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.bedas.sipelor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>sipelor</string>
            <string>io.supabase.sipelor</string>
        </array>
    </dict>
</array>

<!-- Universal Links (Optional but recommended) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:sipelor-bedas.com</string>
    <string>applinks:app.sipelor-bedas.com</string>
</array>
```

#### Step 2: Update AppDelegate.swift

Edit `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL scheme deep links
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  // Handle Universal Links (if configured)
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      if let url = userActivity.webpageURL {
        // Handle universal link
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
      }
    }
    return false
  }
}
```

---

## 💻 Flutter Implementation

### Step 1: Install app_links Package

Package sudah ada di `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.3.4
```

### Step 2: Create Deep Link Handler Service

Create `lib/services/deep_link_service.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  
  /// Initialize deep link handling
  Future<void> initialize(BuildContext context) async {
    // Handle initial deep link (app opened via deep link)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(context, initialUri);
    }

    // Handle deep links while app is running
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(context, uri);
    });
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(BuildContext context, Uri uri) async {
    debugPrint('Deep link received: ${uri.toString()}');

    try {
      switch (uri.scheme) {
        case 'sipelor':
          await _handleSipelorLink(context, uri);
          break;
        case 'io.supabase.sipelor':
          await _handleSupabaseLink(context, uri);
          break;
        default:
          debugPrint('Unknown scheme: ${uri.scheme}');
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  /// Handle sipelor:// scheme links
  Future<void> _handleSipelorLink(BuildContext context, Uri uri) async {
    final path = uri.host;
    final params = uri.queryParameters;

    switch (path) {
      case 'reset-password':
        final token = params['token'];
        if (token != null) {
          Navigator.of(context).pushNamed(
            '/reset-password',
            arguments: {'token': token},
          );
        }
        break;

      case 'verify-email':
        final token = params['token'];
        if (token != null) {
          // Handle email verification
          await _verifyEmail(token);
        }
        break;

      case 'booking':
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        if (id != null) {
          Navigator.of(context).pushNamed(
            '/booking-detail',
            arguments: {'bookingId': id},
          );
        }
        break;

      case 'ticket':
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        if (id != null) {
          Navigator.of(context).pushNamed(
            '/e-ticket',
            arguments: {'bookingId': id},
          );
        }
        break;

      case 'venue':
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        if (id != null) {
          Navigator.of(context).pushNamed(
            '/venue-detail',
            arguments: {'venueId': id},
          );
        }
        break;

      case 'chat':
        final bookingId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        if (bookingId != null) {
          Navigator.of(context).pushNamed(
            '/user-chat',
            arguments: {'bookingId': bookingId},
          );
        }
        break;

      default:
        // Unknown path, navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  /// Handle io.supabase.sipelor:// scheme (auth callbacks)
  Future<void> _handleSupabaseLink(BuildContext context, Uri uri) async {
    // Supabase handles auth callbacks automatically
    debugPrint('Supabase auth callback received');
  }

  /// Verify email with token
  Future<void> _verifyEmail(String token) async {
    try {
      // TODO: Implement email verification logic
      debugPrint('Verifying email with token: $token');
    } catch (e) {
      debugPrint('Email verification error: $e');
    }
  }
}
```

### Step 3: Initialize in main.dart

Update `lib/main.dart`:

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep links after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPELOR BEDAS',
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/booking-detail': (context) => const BookingDetailScreen(),
        '/e-ticket': (context) => const ETicketScreen(),
        '/venue-detail': (context) => const VenueDetailScreen(),
        '/user-chat': (context) => const UserChatScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
```

---

## 🔧 Supabase Configuration

### Step 1: Configure Redirect URLs

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Navigate to **Authentication** → **URL Configuration**
3. Add redirect URLs:

**Site URL**:
```
https://sipelor-bedas.com
```

**Redirect URLs**:
```
sipelor://reset-password
sipelor://verify-email
io.supabase.sipelor://login-callback
http://localhost:3000/auth/callback (for web testing)
```

### Step 2: Update Email Templates

Edit email templates untuk use deep links:

**Password Reset Email**:
```html
<a href="sipelor://reset-password?token={{ .Token }}">Reset Password</a>
```

**Email Verification**:
```html
<a href="sipelor://verify-email?token={{ .Token }}">Verify Email</a>
```

## 🧪 Testing Deep Links

### Method 1: ADB Command (Android)

```bash
# Test password reset link
adb shell am start -W -a android.intent.action.VIEW \
  -d "sipelor://reset-password?token=test-token" \
  com.bedas.sipelor

# Test booking deep link
adb shell am start -W -a android.intent.action.VIEW \
  -d "sipelor://booking/123e4567-e89b-12d3-a456-426614174000" \
  com.bedas.sipelor

# Test venue deep link
adb shell am start -W -a android.intent.action.VIEW \
  -d "sipelor://venue/venue-id-123" \
  com.bedas.sipelor
```

### Method 2: Trigger from App

Create test button in dev menu:

```dart
ElevatedButton(
  onPressed: () {
    final uri = Uri.parse('sipelor://booking/test-id');
    DeepLinkService()._handleDeepLink(context, uri);
  },
  child: Text('Test Deep Link'),
)
```

### Method 3: Send Test Email

Send test email dengan deep link:

```dart
final resetLink = 'sipelor://reset-password?token=${generateToken()}';
// Send email dengan link ini
```

### Method 4: Browser Test (Android)

1. Open Chrome pada Android device
2. Enter URL di address bar:
   ```
   sipelor://booking/test-id
   ```
3. Chrome akan prompt untuk open dengan SIPELOR app

---

## 📊 Analytics & Monitoring

Track deep link usage:

```dart
Future<void> _handleDeepLink(BuildContext context, Uri uri) async {
  // Log to analytics
  await ErrorTrackingService.logMessage(
    'Deep link opened: ${uri.toString()}',
    level: SentryLevel.info,
  );

  // Track in analytics
  // await Analytics.logEvent('deep_link_opened', {
  //   'scheme': uri.scheme,
  //   'path': uri.path,
  //   'source': 'email' or 'notification' or 'share',
  // });

  // Handle the link
  // ... rest of code
}
```

---

## 🚨 Troubleshooting

### Issue 1: Deep Link Not Working on Android

**Solution**:
1. Check AndroidManifest.xml intent-filter correct
2. Verify app installed dan signed correctly
3. Clear app data: `adb shell pm clear com.bedas.sipelor`
4. Reinstall app

### Issue 2: Deep Link Opens Browser Instead of App

**Solution**:
1. Android may have multiple apps registered for scheme
2. Go to Settings → Apps → Default Apps → Opening Links
3. Select SIPELOR BEDAS
4. Enable "Open supported links"

### Issue 3: Token Expired from Email

**Solution**:
1. Supabase tokens expire after 1 hour (default)
2. Check token timestamp
3. Request new reset email if expired

### Issue 4: Deep Link Works but Navigates to Wrong Screen

**Solution**:
1. Check route names match di MaterialApp routes
2. Verify arguments passed correctly
3. Add debug logging in _handleDeepLink

---

## 🎯 Best Practices

1. **Always Validate Tokens**: Don't trust deep link parameters
2. **Handle Errors Gracefully**: Show user-friendly errors
3. **Log Deep Link Events**: For debugging and analytics
4. **Test on Multiple Devices**: Android versions behave differently
5. **Provide Fallback**: If deep link fails, show manual option

---

## 📱 Universal Links (iOS) - Optional

Universal Links allow `https://` URLs to open app:

### Step 1: Create apple-app-site-association File

Create file di web server root:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.bedas.sipelor",
        "paths": [
          "/reset-password/*",
          "/verify-email/*",
          "/booking/*",
          "/venue/*"
        ]
      }
    ]
  }
}
```

Host at: `https://sipelor-bedas.com/.well-known/apple-app-site-association`

### Step 2: Add Associated Domains

In Xcode:
1. Select Runner target
2. Signing & Capabilities
3. Add Associated Domains capability
4. Add: `applinks:sipelor-bedas.com`

---

## ✅ Implementation Checklist

### Android
- [x] AndroidManifest.xml configured
- [x] Custom scheme registered (`sipelor://`)
- [x] Supabase scheme registered (`io.supabase.sipelor://`)
- [ ] Tested with ADB commands
- [ ] Tested from email links
- [ ] Tested from notifications

### iOS
- [ ] Info.plist updated
- [ ] CFBundleURLSchemes added
- [ ] AppDelegate.swift handles URLs
- [ ] Tested on physical device
- [ ] Universal Links configured (optional)

### Flutter Code
- [x] app_links package added
- [ ] DeepLinkService created
- [ ] Initialized in main.dart
- [ ] All routes configured
- [ ] Error handling added
- [ ] Analytics tracking added

### Supabase
- [ ] Redirect URLs configured
- [ ] Email templates updated
- [ ] Password reset uses deep link
- [ ] Email verification uses deep link
- [ ] Tested email delivery

### Testing
- [ ] Password reset flow end-to-end
- [ ] Email verification flow
- [ ] Booking deep links
- [ ] Venue sharing links
- [ ] Chat notifications
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Tested with real emails

---

**Last Updated**: 28 Januari 2026  
**Status**: Android ✅ | iOS ⏳ | Flutter ⏳  
**Next Steps**: Create DeepLinkService, Test on real device
