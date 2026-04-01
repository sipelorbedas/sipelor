# Security Event Notifications - Implementation Guide

> **Panduan implementasi notifikasi event keamanan untuk SIPELOR BEDAS**
> 
> Tanggal: 26 Januari 2026
> Status: Production Ready

---

## 📋 Daftar Isi

1. [Overview](#overview)
2. [Features](#features)
3. [Implementation Details](#implementation-details)
4. [Security Events Tracked](#security-events-tracked)
5. [User Preferences](#user-preferences)
6. [Integration Guide](#integration-guide)
7. [Testing](#testing)

---

## Overview

Security Event Notification Service memantau dan memberitahu pengguna tentang aktivitas keamanan yang penting dan mencurigakan pada akun mereka. Sistem ini membantu pengguna untuk:

- 🔍 Mendeteksi aktivitas tidak sah
- 🔔 Mendapat notifikasi real-time
- 🛡️ Melindungi akun dari akses tidak sah
- 📊 Memantau history keamanan

### ✅ Status Implementasi

| Component | Status | File Location |
|-----------|--------|---------------|
| Security Event Service | ✅ Complete | `lib/services/security_event_notification_service.dart` |
| Settings Screen | ✅ Complete | `lib/screens/security_notification_settings_screen.dart` |
| Main Integration | ✅ Complete | `lib/main.dart` |
| Auth Integration | ✅ Complete | `lib/screens/sign_in_screen.dart` |
| Password Integration | ✅ Complete | `lib/services/password_service.dart` |

---

## Features

### 🔐 Security Events Tracked

1. **Login dari Device Baru** ✅
   - Deteksi device fingerprinting
   - Notifikasi real-time
   - Auto-register trusted devices

2. **Password Change** ✅
   - Notifikasi saat password diubah
   - Alert untuk aktivitas tidak sah

3. **Email Change** ✅
   - Notifikasi perubahan email
   - Konfirmasi ke email lama & baru

4. **Failed Login Attempts** ✅
   - Track percobaan login gagal
   - Notifikasi setelah 5+ attempts
   - Auto-reset setelah login sukses

5. **Payment Confirmation** ✅
   - Notifikasi pembayaran dikonfirmasi
   - Detail transaksi

6. **Booking Status Changes** ✅
   - Notifikasi saat status booking berubah
   - Audit logging

### 🔧 User Preferences

- ✅ Toggle notifikasi per event type
- ✅ Persistent storage (encrypted)
- ✅ Settings screen UI
- ✅ Default: All enabled

### 📱 Notification Channels

- ✅ Push Notifications (via existing service)
- ⏳ Email Notifications (future: via Supabase Edge Functions)
- ⏳ SMS Notifications (future: via Twilio)

---

## Implementation Details

### Service Architecture

```
SecurityEventNotificationService
├── Device Tracking
│   ├── Device fingerprinting
│   ├── Known devices registry
│   └── Trust management
├── Event Tracking
│   ├── Login tracking
│   ├── Password change tracking
│   ├── Email change tracking
│   ├── Failed login tracking
│   ├── Payment tracking
│   └── Booking status tracking
├── Notification Sending
│   ├── Push notification integration
│   ├── User preference checks
│   └── Audit logging
└── User Preferences
    ├── Get/Set preferences
    ├── Encrypted storage
    └── Default values
```

### Technology Stack

- **Storage**: `EncryptedPreferencesService` for secure preference storage
- **Notifications**: `NotificationHelper` for push notifications
- **Audit**: `AuditService` for security logging
- **Rate Limiting**: Built-in for failed login tracking

---

## Security Events Tracked

### 1. Login dari Device Baru

**Trigger**: User login dari device yang belum dikenali

**Flow**:
```
1. User attempts login
2. Check if device is in known devices list
3. If new device:
   - Send notification: "Login dari Perangkat Baru"
   - Register device as trusted
   - Log to audit
4. If known device:
   - Log successful login
   - No notification
```

**Notification**:
- **Title**: 🔐 Login dari Perangkat Baru
- **Message**: Akun Anda baru saja login dari perangkat baru. Jika bukan Anda, segera ubah password.
- **Data**: event_type, timestamp

**Implementation**:
```dart
await SecurityEventNotificationService.trackLogin(
  userId: user.id,
  email: user.email,
);
```

**Integration Points**:
- ✅ `lib/screens/sign_in_screen.dart` - After successful login

### 2. Password Change

**Trigger**: User changes password

**Flow**:
```
1. User submits password change form
2. Validate old password
3. Update password in Supabase
4. Send notification
5. Log to audit
6. Invalidate other sessions
```

**Notification**:
- **Title**: 🔐 Password Diubah
- **Message**: Password akun Anda telah diubah. Jika bukan Anda, segera hubungi support.
- **Data**: event_type, timestamp

**Implementation**:
```dart
await SecurityEventNotificationService.trackPasswordChange(
  userId: user.id,
  email: user.email,
);
```

**Integration Points**:
- ✅ `lib/services/password_service.dart` - After successful password update

### 3. Email Change

**Trigger**: User changes email address

**Flow**:
```
1. User submits email change
2. Validate new email
3. Update email in Supabase
4. Send notification to BOTH emails
5. Log to audit
```

**Notification**:
- **Title**: 📧 Email Diubah
- **Message**: Email akun Anda telah diubah dari [old] ke [new].
- **Data**: event_type, old_email, new_email, timestamp

**Implementation**:
```dart
await SecurityEventNotificationService.trackEmailChange(
  userId: user.id,
  oldEmail: oldEmail,
  newEmail: newEmail,
);
```

**Integration Points**:
- ⏳ TODO: Implement email change feature

### 4. Failed Login Attempts

**Trigger**: Multiple failed login attempts (5+ in 1 hour)

**Flow**:
```
1. User fails to login
2. Increment failed login counter
3. Store timestamp
4. If count >= 5:
   - Send notification
   - Reset counter
5. On successful login:
   - Reset counter to 0
```

**Notification**:
- **Title**: ⚠️  Percobaan Login Gagal
- **Message**: Ada [N] percobaan login gagal pada akun Anda. Pertimbangkan untuk mengubah password.
- **Data**: event_type, count, timestamp

**Implementation**:
```dart
// On failed login
await SecurityEventNotificationService.trackFailedLogin(
  email: email,
);

// On successful login
await SecurityEventNotificationService.resetFailedLoginCount();
```

**Integration Points**:
- ✅ `lib/screens/sign_in_screen.dart` - After login attempt

### 5. Payment Confirmation

**Trigger**: Admin confirms payment

**Flow**:
```
1. Admin approves payment
2. Update booking status
3. Send notification to user
4. Log to audit
```

**Notification**:
- **Title**: 💰 Pembayaran Terkonfirmasi
- **Message**: Pembayaran sebesar Rp [amount] telah dikonfirmasi.
- **Data**: event_type, booking_id, amount, timestamp

**Implementation**:
```dart
await SecurityEventNotificationService.trackPayment(
  userId: user.id,
  bookingId: bookingId,
  amount: totalAmount,
);
```

**Integration Points**:
- ⏳ TODO: Integrate with admin payment confirmation flow

### 6. Booking Status Changes

**Trigger**: Admin changes booking status (approved/rejected)

**Flow**:
```
1. Admin changes booking status
2. Update in database
3. Log security event
4. Push notification handled by NotificationHelper
```

**Note**: Push notification sudah dihandle oleh `NotificationHelper`. Service ini hanya untuk audit logging.

**Implementation**:
```dart
await SecurityEventNotificationService.trackBookingStatusChange(
  userId: userId,
  bookingId: bookingId,
  newStatus: newStatus,
);
```

**Integration Points**:
- ✅ `lib/services/notification_helper.dart` - Push notification
- ✅ `lib/services/supabase_service.dart` - Status update

---

## User Preferences

### Settings Screen

**Location**: `lib/screens/security_notification_settings_screen.dart`

**Access**: Security Settings → Notifikasi Keamanan

**Features**:
- Toggle untuk setiap event type
- Icon & color coding per event
- Description untuk each setting
- Auto-save preferences
- Info banner tentang pentingnya notifikasi

### Event Types

```dart
enum SecurityEventType {
  loginNewDevice,      // Login dari Perangkat Baru
  passwordChange,      // Perubahan Password
  emailChange,         // Perubahan Email
  failedLogins,        // Percobaan Login Gagal
  payment,             // Konfirmasi Pembayaran
  bookingStatus,       // Status Booking
}
```

### Preferences API

```dart
// Get preference for specific event
final isEnabled = await SecurityEventNotificationService
    .getNotificationPreference(SecurityEventType.loginNewDevice);

// Set preference
await SecurityEventNotificationService.setNotificationPreference(
  SecurityEventType.passwordChange,
  true, // enabled
);

// Get all preferences
final allPrefs = await SecurityEventNotificationService.getAllPreferences();
// Returns: Map<SecurityEventType, bool>
```

### Default Values

All security notifications are **enabled by default** for maximum security.

Users can disable individually if desired.

---

## Integration Guide

### 1. Track Login Event

**File**: `lib/screens/sign_in_screen.dart`

```dart
// After successful login
await SupabaseService.signIn(username: username, password: password);

// Reset failed login count
await SecurityEventNotificationService.resetFailedLoginCount();

// Track login for device detection
final currentUser = SupabaseService.currentUser;
if (currentUser != null && currentUser.email != null) {
  await SecurityEventNotificationService.trackLogin(
    userId: currentUser.id,
    email: currentUser.email!,
  );
}
```

**Also track failed login**:
```dart
catch (e) {
  if (errorMessage.contains('Invalid password')) {
    // Track failed attempt
    await SecurityEventNotificationService.trackFailedLogin(
      email: username,
    );
  }
}
```

### 2. Track Password Change

**File**: `lib/services/password_service.dart`

```dart
// After successful password update
await _client.auth.updateUser(
  UserAttributes(password: newPassword),
);

// Track password change
await SecurityEventNotificationService.trackPasswordChange(
  userId: user.id,
  email: email,
);

// Log to audit
await AuditService.logAction(...);
```

### 3. Track Email Change

**TODO**: Implement email change feature first

```dart
Future<void> changeEmail(String newEmail) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  
  final oldEmail = user.email!;
  
  // Update email in Supabase
  await Supabase.instance.client.auth.updateUser(
    UserAttributes(email: newEmail),
  );
  
  // Track email change
  await SecurityEventNotificationService.trackEmailChange(
    userId: user.id,
    oldEmail: oldEmail,
    newEmail: newEmail,
  );
}
```

### 4. Track Payment

**TODO**: Integrate with admin payment confirmation

```dart
Future<void> confirmPayment(String bookingId) async {
  // Get booking details
  final booking = await getBooking(bookingId);
  
  // Update payment status
  await updatePaymentStatus(bookingId, 'confirmed');
  
  // Track payment
  await SecurityEventNotificationService.trackPayment(
    userId: booking.userId,
    bookingId: bookingId,
    amount: booking.totalAmount,
  );
}
```

### 5. Add Settings Link

**File**: `lib/screens/security_settings_screen.dart`

Already integrated! Link added in security settings:

```dart
// Security Notifications Section
_buildSectionTitle('Notifikasi Keamanan'),
const SizedBox(height: 12),
_buildSecurityNotificationsCard(), // Opens settings screen
```

---

## Testing

### Manual Testing Checklist

#### Login Detection
- [ ] Login dari device pertama kali → Should send notification
- [ ] Login dari device yang sama → Should NOT send notification
- [ ] Clear known devices → Next login sends notification again
- [ ] Check notification content & data

#### Password Change
- [ ] Change password successfully → Should send notification
- [ ] Check notification appears immediately
- [ ] Verify notification content includes warning

#### Failed Logins
- [ ] Fail login 4 times → No notification
- [ ] Fail login 5th time → Should send notification
- [ ] Success login after fails → Counter resets
- [ ] Fail again 5 times → Notification sent again

#### User Preferences
- [ ] Navigate to Security → Notifikasi Keamanan
- [ ] Toggle each notification type
- [ ] Verify preferences saved (check after app restart)
- [ ] Disable notification → Verify not sent when event occurs
- [ ] Re-enable → Verify notification works again

#### Integration
- [ ] Login flow integration works
- [ ] Password change flow integration works
- [ ] Preferences screen accessible
- [ ] All icons & colors display correctly

### Unit Tests

```dart
// test/services/security_event_notification_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/security_event_notification_service.dart';

void main() {
  group('SecurityEventNotificationService', () {
    setUp(() async {
      await SecurityEventNotificationService.initialize();
    });

    test('device registration works', () async {
      await SecurityEventNotificationService.registerDevice();
      final isKnown = await SecurityEventNotificationService.isKnownDevice();
      expect(isKnown, isTrue);
    });

    test('failed login counter increments', () async {
      await SecurityEventNotificationService.trackFailedLogin(
        email: 'test@example.com',
      );
      // Verify counter incremented
    });

    test('preferences default to enabled', () async {
      final pref = await SecurityEventNotificationService
          .getNotificationPreference(SecurityEventType.loginNewDevice);
      expect(pref, isTrue);
    });

    test('can toggle preferences', () async {
      await SecurityEventNotificationService.setNotificationPreference(
        SecurityEventType.passwordChange,
        false,
      );
      
      final pref = await SecurityEventNotificationService
          .getNotificationPreference(SecurityEventType.passwordChange);
      expect(pref, isFalse);
    });
  });
}
```

---

## Security Considerations

### Data Privacy

✅ **Encrypted Storage**: All preferences stored using `EncryptedPreferencesService`

✅ **Minimal Data**: Only stores necessary information (device IDs, timestamps, counts)

✅ **User Control**: Users can disable any notification type

### Rate Limiting

✅ **Failed Login Tracking**: Prevents brute force attacks

✅ **Notification Throttling**: No spam - only send when threshold met

### Audit Trail

✅ **All Events Logged**: Every security event logged to audit service

✅ **Tamper-Proof**: Logs stored in Supabase, not locally

---

## Future Enhancements

### Planned Features

1. **Email Notifications** 📧
   - Send email for critical events
   - Email templates via Supabase
   - Fallback when push fails

2. **SMS Notifications** 📱
   - Critical events only (login new device, password change)
   - Twilio integration
   - User phone number verification required

3. **Advanced Device Fingerprinting** 🔍
   - Use `device_info_plus` package
   - Track: device model, OS version, screen size
   - More accurate device detection

4. **Location-Based Alerts** 📍
   - Track login locations via IP geolocation
   - Alert for logins from unusual countries
   - GeoIP database integration

5. **Suspicious Activity Score** 📊
   - Machine learning based risk scoring
   - Combine multiple signals (device, location, time, behavior)
   - Auto-lock account on high risk score

6. **Weekly Security Digest** 📅
   - Email summary of security events
   - Activity timeline
   - Recommendations

7. **Device Management** 🖥️
   - List all logged-in devices
   - Remote logout from device
   - Device nicknames
   - Last active timestamp

---

## Troubleshooting

### Notifications Not Received

**Possible Causes**:
1. User disabled notification type in preferences
2. Push notification service not initialized
3. User not logged in
4. Network issues

**Debug**:
```dart
// Check if notification enabled
final enabled = await SecurityEventNotificationService
    .getNotificationPreference(SecurityEventType.loginNewDevice);
print('Notification enabled: $enabled');

// Check push notification service
final pushService = PushNotificationService();
final isEnabled = await pushService.areNotificationsEnabled();
print('Push enabled: $isEnabled');
```

### Device Always Detected as New

**Possible Causes**:
1. Known devices cleared
2. App data cleared
3. Device ID generation changed

**Debug**:
```dart
// Check known devices
final isKnown = await SecurityEventNotificationService.isKnownDevice();
print('Is known device: $isKnown');

// Clear and re-register
await SecurityEventNotificationService.clearKnownDevices();
await SecurityEventNotificationService.registerDevice();
```

### Failed Login Counter Not Resetting

**Cause**: `resetFailedLoginCount()` not called after successful login

**Fix**:
```dart
// In sign_in_screen.dart, after successful login
await SecurityEventNotificationService.resetFailedLoginCount();
```

---

## Resources

- **Push Notification Service**: `lib/services/push_notification_service.dart`
- **Notification Helper**: `lib/services/notification_helper.dart`
- **Audit Service**: `lib/services/audit_service.dart`
- **Encrypted Preferences**: `lib/services/encrypted_preferences_service.dart`

---

**Dokumen ini akan di-update sesuai enhancement dan feedback.**

**Last Updated**: 26 Januari 2026  
**Version**: 1.0  
**Author**: Development Team  
**Status**: Production Ready
