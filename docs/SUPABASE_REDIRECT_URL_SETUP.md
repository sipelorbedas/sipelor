# 🔗 Supabase Redirect URL Configuration Guide

> **Panduan setup Redirect URL agar email verification & password reset links berfungsi**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026

---

## ⚠️ MASALAH: Button Email Tidak Bisa Diklik

Jika button di email tidak bisa diklik atau link tidak berfungsi, ini karena **Redirect URL belum dikonfigurasi** di Supabase.

---

## 🎯 Solusi: Configure Redirect URLs

### Step 1: Login ke Supabase Dashboard

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Authentication** → **URL Configuration**

---

### Step 2: Add Redirect URLs

Di bagian **Redirect URLs**, tambahkan URL berikut:

#### For Development (Testing):

```
http://localhost:3000
http://localhost:3000/reset-password
http://127.0.0.1:3000
http://127.0.0.1:3000/reset-password
```

#### For Production (Mobile App dengan Deep Links):

```
sipelor://callback
sipelor://reset-password
sipelor://auth/callback
```

#### For Production (Web):

```
https://your-domain.com
https://your-domain.com/reset-password
https://your-domain.com/auth/callback
```

---

### Step 3: Set Site URL

Di bagian **Site URL**, set URL utama:

**Development:**
```
http://localhost:3000
```

**Production:**
```
https://your-domain.com
```
atau
```
sipelor://
```

---

### Step 4: Save Configuration

Click **Save** di bagian bawah halaman.

---

## 📧 Update Email Templates dengan Redirect URL

Setelah configure redirect URLs, update email templates:

### Template 1: Email Verification

**SEBELUM (tidak akan work):**
```html
<a href="{{ .ConfirmationURL }}" class="button">
    ✓ Verifikasi Email Saya
</a>
```

**SESUDAH (dengan redirect):**
```html
<a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=sipelor://callback" class="button">
    ✓ Verifikasi Email Saya
</a>
```

**Untuk Web:**
```html
<a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=https://your-domain.com/home" class="button">
    ✓ Verifikasi Email Saya
</a>
```

---

### Template 2: Password Reset

**SEBELUM:**
```html
<a href="{{ .ConfirmationURL }}" class="button">
    🔑 Reset Password Saya
</a>
```

**SESUDAH (dengan redirect untuk mobile app):**
```html
<a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=sipelor://reset-password" class="button">
    🔑 Reset Password Saya
</a>
```

**Untuk Web:**
```html
<a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=https://your-domain.com/reset-password" class="button">
    🔑 Reset Password Saya
</a>
```

---

## 🔧 Supabase Template Variables

Supabase menyediakan template variables berikut:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{ .Email }}` | User's email | user@example.com |
| `{{ .Token }}` | Raw token (deprecated) | abc123... |
| `{{ .TokenHash }}` | Hashed token (recommended) | def456... |
| `{{ .SiteURL }}` | Your Supabase project URL | https://xxx.supabase.co |
| `{{ .ConfirmationURL }}` | Auto-generated confirmation link | Uses configured redirect |
| `{{ .Data.* }}` | Custom metadata | Any custom data |

---

## 📱 Flutter Deep Link Handler (Updated)

Update Flutter app untuk handle deep links dari email:

### Update `lib/main.dart`

```dart
import 'package:app_links/app_links.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  late StreamSubscription<Uri> _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle deep link when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle deep link when app starts from terminated state
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling initial deep link: $e');
      }
    }
  }

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      print('Deep link received: $uri');
    }

    // Handle email verification callback
    if (uri.path == '/callback' || uri.path == '/auth/callback') {
      final type = uri.queryParameters['type'];
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];

      if (type == 'signup' && accessToken != null) {
        // Email verified successfully
        _handleEmailVerificationSuccess();
      }
    }

    // Handle password reset
    if (uri.path == '/reset-password') {
      final accessToken = uri.queryParameters['access_token'];
      
      if (accessToken != null) {
        // Navigate to reset password screen with token
        _navigateToResetPassword(accessToken);
      }
    }
  }

  void _handleEmailVerificationSuccess() {
    // Show success message
    // Navigate to home or login screen
  }

  void _navigateToResetPassword(String token) {
    // Navigate to reset password screen
    Navigator.of(context).pushNamed(
      '/reset-password',
      arguments: {'token': token},
    );
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoLogoutWrapper(
      child: MaterialApp(
        title: 'SIPELOR BEDAS',
        // ... rest of code
      ),
    );
  }
}
```

---

## 📦 Install Deep Link Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.3.2
```

Then run:
```bash
flutter pub get
```

---

## 🤖 Android Deep Link Configuration

### Update `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <application>
        <activity
            android:name=".MainActivity"
            android:exported="true">
            
            <!-- Existing intent filters -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Deep link intent filter for email verification -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                
                <!-- sipelor:// scheme -->
                <data
                    android:scheme="sipelor"
                    android:host="callback" />
                <data
                    android:scheme="sipelor"
                    android:host="reset-password" />
                <data
                    android:scheme="sipelor"
                    android:host="auth" />
            </intent-filter>

            <!-- HTTPS deep links (optional, for universal links) -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                
                <data
                    android:scheme="https"
                    android:host="your-domain.com"
                    android:pathPrefix="/auth" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

---

## 🍎 iOS Deep Link Configuration

### Update `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.dispora.sipelor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>sipelor</string>
        </array>
    </dict>
</array>

<!-- Universal Links (optional) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:your-domain.com</string>
</array>
```

---

## ✅ Testing Checklist

### Test Email Verification:

1. ☐ Signup new user via Flutter app
2. ☐ Check email inbox
3. ☐ Click "Verifikasi Email" button
4. ☐ App should open automatically
5. ☐ User should be verified and logged in

### Test Password Reset:

1. ☐ Request password reset via Flutter app
2. ☐ Check email inbox
3. ☐ Click "Reset Password" button
4. ☐ App should open to reset password screen
5. ☐ Enter new password
6. ☐ Password should update successfully

### Test Deep Links Manually:

**Android:**
```bash
# Test verification callback
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://callback?type=signup&access_token=test123"

# Test password reset
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password?access_token=test123"
```

**iOS:**
```bash
# Test using xcrun simctl
xcrun simctl openurl booted "sipelor://callback?type=signup&access_token=test123"

xcrun simctl openurl booted "sipelor://reset-password?access_token=test123"
```

---

## 🐛 Troubleshooting

### Button tetap tidak bisa diklik

1. **Clear browser cache** - Email client mungkin cache email lama
2. **Check Redirect URLs** - Pastikan semua URL sudah ditambahkan
3. **Re-send email** - Send email baru setelah update template
4. **Test di different email client** - Gmail, Outlook, etc.

### Deep link tidak buka app

1. **Verify AndroidManifest.xml** - Check deep link configuration
2. **Verify Info.plist** - Check iOS configuration
3. **Reinstall app** - Kadang perlu reinstall untuk apply manifest changes
4. **Check app_links package** - Ensure properly installed

### Email shows "Invalid redirect URL"

1. **Add URL to Redirect URLs list** - Must be whitelisted in Supabase
2. **Check Site URL** - Must match one of redirect URLs
3. **URL encoding** - Ensure redirect_to parameter is properly encoded

---

## 📚 Additional Resources

- [Supabase Auth Deep Links](https://supabase.com/docs/guides/auth/redirect-urls)
- [Flutter App Links Package](https://pub.dev/packages/app_links)
- [Android Deep Links Guide](https://developer.android.com/training/app-links)
- [iOS Universal Links Guide](https://developer.apple.com/ios/universal-links/)

---

**Last Updated**: 28 Januari 2026  
**Maintained By**: Development Team
