# Sentry Error Tracking Setup Guide

> **Panduan konfigurasi Sentry untuk monitoring error dan performance pada aplikasi SIPELOR BEDAS**
> 
> Tanggal: 26 Januari 2026
> Status: Production Ready

---

## 📋 Daftar Isi

1. [Pendahuluan](#pendahuluan)
2. [Persiapan Akun Sentry](#persiapan-akun-sentry)
3. [Konfigurasi Development](#konfigurasi-development)
4. [Konfigurasi Production](#konfigurasi-production)
5. [Testing & Verification](#testing--verification)
6. [Monitoring & Alerts](#monitoring--alerts)
7. [Best Practices](#best-practices)

---

## Pendahuluan

Sentry adalah platform error tracking dan performance monitoring yang sudah terintegrasi dalam aplikasi SIPELOR BEDAS. Service ini akan membantu tim development untuk:

- 📊 Monitor error dan crash real-time
- 🔍 Debug dengan context lengkap (user, device, breadcrumbs)
- 📈 Track performance issues
- 🚨 Receive alerts untuk critical errors
- 📉 Analyze error trends dan patterns

### Status Implementasi

✅ **Error Tracking Service**: Sudah diimplementasikan di `lib/services/error_tracking_service.dart`

✅ **Main Integration**: Sudah diintegrasikan di `lib/main.dart`

⏳ **Konfigurasi DSN**: Perlu setup (panduan di bawah)

---

## Persiapan Akun Sentry

### 1. Buat Akun Sentry

1. Kunjungi [https://sentry.io/signup/](https://sentry.io/signup/)
2. Daftar menggunakan email atau GitHub account
3. Pilih plan:
   - **Free Tier**: 5,000 events/month (cukup untuk development & small app)
   - **Paid Plans**: Untuk production dengan traffic tinggi

### 2. Buat Project Flutter

1. Setelah login, klik **"Create Project"**
2. Pilih platform: **Flutter**
3. Set project name: `sipelor-bedas` (atau sesuai preferensi)
4. Set alert settings (default OK untuk mulai)
5. Klik **"Create Project"**

### 3. Dapatkan DSN

Setelah project dibuat, Anda akan melihat:

```
Sentry DSN: https://[key]@[organization].ingest.sentry.io/[project-id]
```

**Copy DSN ini** - akan digunakan di langkah berikutnya.

**Contoh DSN:**
```
https://abc123def456ghi789@o1234567.ingest.sentry.io/9876543
```

---

## Konfigurasi Development

### Setup untuk Testing Lokal

#### Option 1: Disable Sentry (Recommended untuk Dev)

Sentry dinonaktifkan secara default di development mode. Tidak perlu konfigurasi tambahan.

Cek di `lib/services/error_tracking_service.dart`:
```dart
options.beforeSend = (event, hint) {
  // Don't send events in debug mode (optional)
  if (kDebugMode) {
    return null; // Sentry disabled in debug
  }
  return event;
};
```

#### Option 2: Enable Sentry untuk Development Testing

Jika ingin test Sentry di development:

1. **Buat project terpisah** di Sentry untuk development (recommended)
2. **Build dengan DSN development:**

**PowerShell (Windows):**
```powershell
flutter run --dart-define=SENTRY_DSN="https://[dev-key]@[org].ingest.sentry.io/[dev-project]"
```

**Bash (Linux/Mac):**
```bash
flutter run --dart-define=SENTRY_DSN="https://[dev-key]@[org].ingest.sentry.io/[dev-project]"
```

3. **Atau buat file `.env` untuk development** (NOT RECOMMENDED untuk production):

Create `.env.sentry` file:
```env
SENTRY_DSN=https://[dev-key]@[org].ingest.sentry.io/[dev-project]
```

⚠️ **WARNING**: Jangan commit file dengan DSN ke git!

---

## Konfigurasi Production

### Setup untuk Production Builds

#### Android APK/AAB Build

**PowerShell (Windows):**
```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="your-anon-key" `
  --dart-define=SENTRY_DSN="https://[key]@[org].ingest.sentry.io/[project]"
```

**Bash (Linux/Mac):**
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key" \
  --dart-define=SENTRY_DSN="https://[key]@[org].ingest.sentry.io/[project]"
```

#### iOS Build

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key" \
  --dart-define=SENTRY_DSN="https://[key]@[org].ingest.sentry.io/[project]"
```

#### Menggunakan Build Scripts (Recommended)

Gunakan build script yang sudah ada di `scripts/build_production.ps1`:

**Edit script dan tambahkan Sentry DSN:**

```powershell
# scripts/build_production.ps1

# Configuration
$SUPABASE_URL = "https://your-project.supabase.co"
$SUPABASE_ANON_KEY = "your-anon-key"
$SENTRY_DSN = "https://[key]@[org].ingest.sentry.io/[project]"  # ADD THIS LINE

# Build command
flutter build apk --release `
  --dart-define=SUPABASE_URL="$SUPABASE_URL" `
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" `
  --dart-define=SENTRY_DSN="$SENTRY_DSN"  # ADD THIS LINE
```

Jalankan:
```powershell
.\scripts\build_production.ps1
```

---

## Testing & Verification

### 1. Test Error Tracking

Tambahkan test error di aplikasi (misalnya di debug screen):

```dart
import 'package:sipelor/services/error_tracking_service.dart';

// Test manual error
ElevatedButton(
  onPressed: () async {
    await ErrorTrackingService.logError(
      Exception('Test error from SIPELOR'),
      StackTrace.current,
      context: 'Manual Test',
      extra: {
        'screen': 'Debug Screen',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test error sent to Sentry')),
    );
  },
  child: Text('Test Sentry Error'),
),

// Test manual message
ElevatedButton(
  onPressed: () async {
    await ErrorTrackingService.logMessage(
      'Test info message from SIPELOR',
      level: SentryLevel.info,
      extra: {'test': 'value'},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test message sent to Sentry')),
    );
  },
  child: Text('Test Sentry Message'),
),
```

### 2. Test Crash

Untuk test automatic crash capture:

```dart
// This will be automatically captured by Sentry
ElevatedButton(
  onPressed: () {
    throw Exception('Test crash from SIPELOR!');
  },
  child: Text('Test Crash'),
),
```

### 3. Verifikasi di Sentry Dashboard

1. Buka [https://sentry.io/](https://sentry.io/)
2. Login dan pilih project Anda
3. Navigate ke **Issues** tab
4. Anda harus melihat error/message yang baru saja dikirim
5. Klik untuk melihat detail lengkap

**Apa yang akan terlihat:**
- Error message & stack trace
- Device info (OS, model, app version)
- User context (jika sudah di-set)
- Breadcrumbs (activity sebelum error)
- Environment (development/production)

---

## Monitoring & Alerts

### Setup Alerts

1. Di Sentry dashboard, buka **Settings** → **Alerts**
2. Klik **Create Alert Rule**
3. Pilih kondisi:
   - **When**: Error occurs
   - **Filters**: Environment = production, severity = error
   - **Action**: Send notification to email/Slack/Discord

### Recommended Alert Rules

#### 1. Critical Errors Alert
- **Condition**: New issue dengan level = fatal atau error
- **Frequency**: Immediately
- **Action**: Email to team + Slack notification

#### 2. High Error Rate Alert
- **Condition**: Error rate > 10 errors/minute
- **Frequency**: Once per 15 minutes
- **Action**: Email to on-call engineer

#### 3. Daily Summary
- **Condition**: Daily digest
- **Frequency**: 9 AM every day
- **Action**: Email summary to team

### Integrations

Connect Sentry dengan tools lain:

- **Slack**: Real-time error notifications
- **Discord**: Team notifications
- **GitHub**: Auto-create issues untuk errors
- **Jira**: Project management integration

Setup di: **Settings** → **Integrations**

---

## Best Practices

### 1. Set User Context

Tambahkan user context saat login:

```dart
// In lib/services/supabase_service.dart or sign_in_screen.dart
import 'package:sipelor/services/error_tracking_service.dart';

// After successful login
ErrorTrackingService.setUser(
  id: user.id,
  email: user.email,
  username: profile['username'] as String?,
  data: {
    'role': profile['role'],
    'created_at': profile['created_at'],
  },
);
```

Clear context saat logout:

```dart
// In sign out function
ErrorTrackingService.clearUser();
```

### 2. Add Breadcrumbs

Track user actions untuk better debugging context:

```dart
// Example: Track navigation
ErrorTrackingService.addBreadcrumb(
  message: 'Navigate to booking screen',
  category: 'navigation',
  data: {'field_id': fieldId, 'venue_name': venueName},
);

// Example: Track user action
ErrorTrackingService.addBreadcrumb(
  message: 'User clicked confirm booking',
  category: 'user_action',
  data: {'booking_date': selectedDate.toIso8601String()},
);

// Example: Track API call
ErrorTrackingService.addBreadcrumb(
  message: 'API call: createBooking',
  category: 'http',
  data: {'endpoint': '/bookings', 'method': 'POST'},
);
```

### 3. Filter Sensitive Data

Service sudah otomatis filter keywords sensitif:
- password
- token
- secret
- api_key
- credit_card
- dll

Lihat di `error_tracking_service.dart`:
```dart
static bool _containsSensitiveData(String message) {
  final lowerMessage = message.toLowerCase();
  final sensitivePatterns = [
    'password', 'token', 'secret', 'api_key', // ...
  ];
  // ...
}
```

### 4. Performance Monitoring

Track performance untuk critical operations:

```dart
// Start transaction
final transaction = ErrorTrackingService.startTransaction(
  name: 'create_booking',
  operation: 'booking',
);

try {
  // Your booking logic
  await SupabaseService.createBooking(...);
  
  // Mark as success
  transaction?.status = SpanStatus.ok();
} catch (e) {
  transaction?.status = SpanStatus.internalError();
  rethrow;
} finally {
  // Finish transaction
  await transaction?.finish();
}
```

### 5. Release Tracking

Update version di `error_tracking_service.dart` saat release:

```dart
options.release = 'sipelor@1.0.0+1'; // Update sesuai pubspec.yaml
```

Ini membantu track regressions antar versi.

### 6. Environment Separation

Gunakan environment yang berbeda:
- `development` - untuk local testing
- `staging` - untuk pre-production testing
- `production` - untuk production release

Sudah otomatis di-set di service:
```dart
options.environment = kDebugMode ? 'development' : 'production';
```

---

## Troubleshooting

### Error: Sentry not sending events

**Check:**
1. DSN configured correctly?
2. Internet connection available?
3. `beforeSend` tidak return `null`?
4. Project quota tidak habis?

**Debug:**
```dart
// Enable debug logging
options.debug = true; // di error_tracking_service.dart
```

### Error: Too many events

**Solution:**
1. Increase sample rate:
   ```dart
   options.sampleRate = 0.3; // Only send 30% of errors
   ```
2. Add more specific filters di `beforeSend`
3. Upgrade Sentry plan

### Error: Performance monitoring not working

**Check:**
1. `tracesSampleRate` > 0
2. Transaction finished dengan `await transaction.finish()`

---

## FAQ

**Q: Apakah Sentry berbayar?**
A: Ada free tier (5,000 events/month). Cukup untuk small apps. Paid plans mulai dari $26/month.

**Q: Apakah data user aman?**
A: Ya. Sentry compliant dengan GDPR. Sensitive data sudah di-filter otomatis.

**Q: Bagaimana cara disable Sentry?**
A: Jangan pass SENTRY_DSN saat build. Service akan auto-disabled.

**Q: Berapa lama data disimpan?**
A: Free tier: 30 days. Paid plans: 90+ days.

**Q: Apakah bisa self-hosted?**
A: Ya, Sentry open source dan bisa di-host sendiri. Tapi managed service lebih mudah.

---

## Resources

- **Sentry Documentation**: [https://docs.sentry.io/platforms/flutter/](https://docs.sentry.io/platforms/flutter/)
- **Sentry Dashboard**: [https://sentry.io/](https://sentry.io/)
- **Flutter Package**: [https://pub.dev/packages/sentry_flutter](https://pub.dev/packages/sentry_flutter)
- **Best Practices**: [https://docs.sentry.io/platforms/flutter/best-practices/](https://docs.sentry.io/platforms/flutter/best-practices/)

---

## Kontak & Support

Jika ada pertanyaan atau issue dengan Sentry setup:

1. Check Sentry documentation
2. Check aplikasi logs untuk error messages
3. Contact development team
4. Email Sentry support (untuk account/billing issues)

---

**Dokumen ini akan di-update sesuai kebutuhan dan pengalaman implementasi.**

**Last Updated**: 26 Januari 2026  
**Version**: 1.0  
**Author**: Development Team
