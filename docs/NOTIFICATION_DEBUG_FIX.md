# Notification Not Showing - Debug Fix

## Issues Reported
1. ❌ Notifikasi tidak muncul ketika admin mengubah status pembayaran di dashboard
2. ❌ Notifikasi chat tidak muncul
3. ❌ Tidak ada suara notifikasi

## Root Cause Analysis

### Problem 1: Notification Service Not Subscribed After Login
**Issue**: `PushNotificationService` diinisialisasi di `main.dart` sebelum user login, sehingga subscription ke Supabase Realtime gagal karena belum ada authenticated user.

**Evidence**:
```dart
// Di push_notification_service.dart line 102-109
Future<void> _subscribeToNotifications() async {
  final user = _supabase.auth.currentUser;
  if (user == null) {
    print('⚠️ [PushNotification] No user logged in, skipping subscription');
    return;  // ❌ Skip subscription jika belum login
  }
  // ...
}
```

**Impact**: Service initialized tapi tidak subscribe, jadi tidak menerima notification updates dari database.

---

### Problem 2: No Re-subscription After Login
**Issue**: Tidak ada mechanism untuk re-subscribe ke notifications setelah user login.

**Impact**: Meskipun notification masuk ke database, app tidak mendengarkan perubahan database karena tidak subscribed.

---

## Solutions Implemented

### ✅ Solution 1: Auth State Listener
Menambahkan listener untuk auth state changes yang otomatis re-subscribe ketika user login.

**File**: `lib/services/push_notification_service.dart`

**Changes**:
1. Added `_authSubscription` untuk track auth listener
2. Added `_setupAuthListener()` method yang mendengarkan auth events
3. Auto-subscribe ketika user login (`AuthChangeEvent.signedIn`)
4. Auto-unsubscribe ketika user logout (`AuthChangeEvent.signedOut`)
5. Re-check subscription ketika token refreshed

**Code**:
```dart
void _setupAuthListener() {
  _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    
    if (event == AuthChangeEvent.signedIn) {
      // User logged in - subscribe to notifications
      _subscribeToNotifications();
    } else if (event == AuthChangeEvent.signedOut) {
      // User logged out - unsubscribe
      _unsubscribeFromNotifications();
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      // Token refreshed - ensure subscription is active
      if (_notificationChannel == null) {
        _subscribeToNotifications();
      }
    }
  });
}
```

---

### ✅ Solution 2: Enhanced Debug Logging
Menambahkan comprehensive logging untuk membantu debug notification flow.

**Logging Points**:
1. ✅ Auth events (login/logout/token refresh)
2. ✅ Subscription status
3. ✅ Notification received from database
4. ✅ Notification parsing
5. ✅ Notification type checking
6. ✅ Sound/vibration status
7. ✅ Local notification display
8. ✅ Error with stack traces

**Example Logs**:
```
🔐 [PushNotification] Auth event: signedIn, User: abc123...
👤 [PushNotification] User signed in, subscribing to notifications...
✅ [PushNotification] Subscribed to notifications for user: abc123...

🔔 [PushNotification] New notification received: {user_id: abc123, type: booking_approved, ...}
📬 [PushNotification] Processing notification data: {...}
📬 [PushNotification] Parsed notification:
   - Title: Booking Disetujui! ✅
   - Body: Booking Anda untuk Training Soccer telah disetujui...
   - Type: booking_approved
✓ [PushNotification] Notification type is enabled, proceeding...
🔊 [PushNotification] Sound enabled: true
📳 [PushNotification] Vibration enabled: true
🔔 [PushNotification] Showing local notification...
✅ [PushNotification] Local notification shown successfully
✅ [PushNotification] Notification handled successfully
```

---

### ✅ Solution 3: Enhanced Chat Notification Logging
Menambahkan detailed logging untuk chat notification flow.

**File**: `lib/services/chat_service.dart`

**Changes**:
- Added logging saat notification dikirim ke database
- Added notification data details
- Added stack trace untuk errors

---

### ✅ Solution 4: Fixed iOS Sound
Changed iOS sound from custom file to default system sound (more reliable).

**Before**:
```dart
sound: 'notification.mp3',  // ❌ Custom file might not exist
```

**After**:
```dart
sound: 'default',  // ✅ Use system default sound
```

---

## Files Modified

1. ✅ `lib/services/push_notification_service.dart`
   - Added auth state listener
   - Added re-subscription mechanism
   - Enhanced debug logging
   - Fixed iOS sound

2. ✅ `lib/services/chat_service.dart`
   - Enhanced chat notification logging
   - Added created_at timestamp to notification

**Total Lines Changed**: ~150 lines

---

## How It Works Now

### Initialization Flow:
```
1. App starts → main.dart
   ↓
2. PushNotificationService.initialize()
   ↓
3. _initializeLocalNotifications() → Setup notification plugin
   ↓
4. _subscribeToNotifications() → Skip if not logged in
   ↓
5. _setupAuthListener() → Listen for auth changes
   ↓
6. User logs in → AuthChangeEvent.signedIn
   ↓
7. _subscribeToNotifications() → Subscribe to user's notifications
   ↓
8. ✅ Ready to receive notifications!
```

### Notification Flow:
```
1. Admin updates payment status
   ↓
2. NotificationHelper.notifyPaymentVerified() → Insert to database
   ↓
3. Supabase Realtime → Detect INSERT in notifications table
   ↓
4. PushNotificationService._handleNewNotification() → Receive event
   ↓
5. Parse notification data
   ↓
6. Check if notification type enabled
   ↓
7. _showLocalNotification() → Show on device
   ↓
8. _playNotificationSound() → Play sound
   ↓
9. _vibrateDevice() → Vibrate
   ↓
10. ✅ User sees & hears notification!
```

---

## Testing Instructions

### Pre-requisites:
1. ✅ App must be installed on device (physical device recommended)
2. ✅ Notification permissions granted
3. ✅ Device not in silent/DND mode
4. ✅ App running in foreground OR background

### Test 1: Payment Status Notification

#### Step A: Setup
1. Login sebagai **User** di device 1
2. Buat booking baru
3. Upload bukti pembayaran
4. **Penting**: Jangan logout, biarkan app terbuka (bisa di background)

#### Step B: Trigger Notification
1. Login sebagai **Admin** di device 2 atau browser
2. Buka Admin Dashboard
3. Lihat tabel "Booking Terbaru"
4. Find booking yang baru dibuat user
5. Click dropdown status pembayaran
6. Pilih **"Verified"** atau **"Rejected"**

#### Step C: Expected Result on User Device
```
✅ Notification muncul di notification tray
✅ Title: "Pembayaran Terverifikasi! ✅" (atau "Pembayaran Ditolak ❌")
✅ Body: "Pembayaran Anda untuk booking [Venue] telah terverifikasi..."
✅ Sound: Suara notification berbunyi
✅ Vibration: Device bergetar
✅ Bisa di-tap untuk buka app
```

#### Step D: Check Console Logs
Look for these logs in User's device:
```
🔔 [PushNotification] New notification received: {...}
📬 [PushNotification] Processing notification data: {...}
✅ [PushNotification] Notification handled successfully
```

---

### Test 2: Chat Notification

#### Step A: Setup (User → Admin)
1. Login sebagai **User** di device 1
2. Buka halaman Chat dengan Admin
3. **Penting**: Biarkan app terbuka (bisa di background)

#### Step B: Setup (Admin)
1. Login sebagai **Admin** di device 2
2. Buka Admin Dashboard → Chat List

#### Step C: Send Message (User → Admin)
1. Di User device: Ketik dan kirim pesan ke Admin
2. Di Admin device: **Expected Result**
   ```
   ✅ Notification muncul
   ✅ Title: "Pesan baru dari [User Name]"
   ✅ Body: Isi pesan
   ✅ Sound berbunyi
   ✅ Vibration
   ```

#### Step D: Send Message (Admin → User)
1. Di Admin device: Balas pesan ke User
2. Di User device: **Expected Result**
   ```
   ✅ Notification muncul
   ✅ Title: "Pesan baru dari Admin"
   ✅ Body: Isi pesan
   ✅ Sound berbunyi
   ✅ Vibration
   ```

#### Step E: Check Console Logs
**In Chat sender's device:**
```
📬 [ChatService] Sending chat notification to [receiver_id]
✅ [ChatService] Chat notification sent successfully to database
```

**In Chat receiver's device:**
```
🔔 [PushNotification] New notification received: {...}
📬 [PushNotification] Parsed notification:
   - Title: Pesan baru dari [Name]
   - Type: chat_message
✅ [PushNotification] Notification handled successfully
```

---

### Test 3: Booking Status Notification

#### Test Confirmed Status:
1. Admin changes booking status to **"Confirmed"**
2. User receives:
   ```
   Title: "Booking Disetujui! ✅"
   Body: "Booking Anda untuk [Venue] telah disetujui. Tap untuk download E-Tiket."
   ```

#### Test Completed Status:
1. Admin changes booking status to **"Completed"**
2. User receives:
   ```
   Title: "Booking Selesai ✅"
   Body: "Bagaimana pengalaman Anda? Yuk beri review untuk [Venue]!"
   ```

#### Test Canceled Status:
1. Admin changes booking status to **"Canceled"**
2. User receives:
   ```
   Title: "Booking Ditolak ❌"
   Body: "Booking Anda untuk [Venue] ditolak."
   ```

---

## Troubleshooting

### Issue: Notification tidak muncul sama sekali

#### Check 1: Notification Permission
```
Android: Settings > Apps > SIPELOR > Permissions > Notifications
iOS: Settings > Notifications > SIPELOR
```
**Fix**: Enable notification permission

#### Check 2: User Logged In?
Check console logs saat app start:
```
✅ [PushNotification] Subscribed to notifications for user: [user_id]
```
If you see:
```
⚠️ [PushNotification] No user logged in, skipping subscription
```
**Fix**: User harus login dulu. Coba logout dan login kembali.

#### Check 3: Auth Listener Active?
Check logs after login:
```
🔐 [PushNotification] Auth event: signedIn, User: [user_id]
👤 [PushNotification] User signed in, subscribing to notifications...
✅ [PushNotification] Subscribed to notifications for user: [user_id]
```
If not present:
**Fix**: Auth listener mungkin tidak setup. Restart app.

#### Check 4: Database Notification Created?
Check Supabase dashboard → `notifications` table.
Query:
```sql
SELECT * FROM notifications 
WHERE user_id = '[user_id]'
ORDER BY created_at DESC
LIMIT 10;
```
If no records:
**Fix**: Notification creation failed. Check admin console logs.

#### Check 5: Realtime Connection
Check logs:
```
✅ [PushNotification] Subscribed to notifications for user: [user_id]
```
Then after notification created:
```
🔔 [PushNotification] New notification received: {...}
```
If first log exists but second doesn't:
**Fix**: Supabase Realtime might be down or blocked. Check network.

---

### Issue: Notification muncul tapi tidak ada suara

#### Check 1: Device Sound Settings
- Check volume tidak muted
- Check "Do Not Disturb" tidak aktif
- Check app notification settings bisa play sound

#### Check 2: Sound Preference
Check SharedPreferences:
```dart
final prefs = await SharedPreferences.getInstance();
final soundEnabled = prefs.getBool('notif_sound_enabled') ?? true;
```
**Fix**: Enable sound di notification settings app

#### Check 3: Console Logs
Look for:
```
🔊 [PushNotification] Sound enabled: false
```
**Fix**: User disabled sound. Enable di settings.

---

### Issue: Notification muncul terlambat

**Cause**: Background restrictions di Android.

**Fix**:
1. Settings > Apps > SIPELOR > Battery
2. Select "Unrestricted"
3. Disable battery optimization untuk SIPELOR

---

### Issue: Multiple notifications untuk satu event

**Cause**: Multiple subscription channels active.

**Fix**: 
1. Force close app
2. Restart app
3. Login kembali

Should see only one subscription log:
```
✅ [PushNotification] Subscribed to notifications for user: [user_id]
```

---

## Key Debug Logs Reference

### Successful Notification Flow:
```
// User Login
🔐 [PushNotification] Auth event: signedIn, User: abc123
👤 [PushNotification] User signed in, subscribing to notifications...
✅ [PushNotification] Subscribed to notifications for user: abc123

// Notification Created (admin side)
📝 [UpdatePaymentStatus] Updating payment for booking UUID: xyz789
✅ [UpdatePaymentStatus] Payment status updated to: verified
✅ [UpdatePaymentStatus] Notification sent to user

// Notification Received (user side)
🔔 [PushNotification] New notification received: {user_id: abc123, ...}
📬 [PushNotification] Processing notification data: {...}
📬 [PushNotification] Parsed notification:
   - Title: Pembayaran Terverifikasi! ✅
   - Body: Pembayaran Anda untuk booking...
   - Type: booking_approved
✓ [PushNotification] Notification type is enabled, proceeding...
🔊 [PushNotification] Sound enabled: true
📳 [PushNotification] Vibration enabled: true
🔔 [PushNotification] Showing local notification...
✅ [PushNotification] Local notification shown successfully
✅ [PushNotification] Notification handled successfully
```

### Failed Notification (Not Subscribed):
```
⚠️ [PushNotification] No user logged in, skipping subscription
// Later when notification created - nothing happens!
```

### Failed Notification (Type Disabled):
```
🔔 [PushNotification] New notification received: {...}
⚠️ [PushNotification] Notification type booking_approved is disabled
// Notification received but not shown
```

---

## Additional Notes

### Notification Channels (Android)
App sekarang menggunakan 2 notification channels:
1. **sipelor_notifications** - Untuk booking, payment, general
2. **sipelor_chat_notifications** - Untuk chat messages

User bisa manage masing-masing channel independently di Android settings.

### Background vs Foreground
- **Foreground**: Notification ditampilkan via local notification plugin
- **Background**: OS handles notification display
- **Both**: Should work with this fix karena subscription active

### Testing on Emulator
Emulator might not support:
- Vibration
- Sound (depending on emulator settings)

**Recommendation**: Test on physical device untuk hasil akurat.

---

## Summary

### What Was Fixed:
1. ✅ Auth state listener untuk auto re-subscribe after login
2. ✅ Unsubscribe mechanism saat logout
3. ✅ Token refresh check untuk maintain subscription
4. ✅ Enhanced debug logging di semua notification flow
5. ✅ Fixed iOS notification sound
6. ✅ Added created_at timestamp untuk chat notifications

### What To Do Next:
1. ✅ Deploy update ke production
2. ✅ Test dengan real users
3. ✅ Monitor console logs untuk errors
4. ✅ Collect feedback tentang notification reliability
5. ⚠️ Consider implementing FCM (Firebase Cloud Messaging) untuk more reliable notifications

---

Generated: 2026-02-02
