# Ringkasan Perbaikan Notifikasi

## Masalah yang Ditemukan

### 1. **Push Notification Service tidak subscribe saat app restart**
- **Penyebab**: Service tidak memeriksa apakah user sudah login saat inisialisasi
- **Dampak**: Notifikasi tidak muncul setelah app restart, meskipun user sudah login
- **Fix**: Service sekarang memeriksa session yang tersimpan dan langsung subscribe jika user sudah login

### 2. **Column mismatch di database**
- **Error**: `Could not find the 'read' column of 'notifications' in the schema cache`
- **Penyebab**: Kode Flutter menggunakan `'read'` tapi database schema menggunakan `'is_read'`
- **Dampak**: Semua notifikasi gagal dibuat di database
- **Fix**: Mengubah semua referensi dari `'read'` ke `'is_read'` di:
  - [chat_service.dart](./lib/services/chat_service.dart)
  - [notification_helper.dart](./lib/services/notification_helper.dart)
  - [push_notification_service.dart](./lib/services/push_notification_service.dart)
  - [notification_debug_helper.dart](./lib/services/notification_debug_helper.dart)
  - [push_notification.dart](./lib/models/push_notification.dart)

### 3. **Izin Alarm & Pengingat tidak perlu**
- **Penyebab**: Kode meminta izin `exact alarm` yang tidak diperlukan untuk notifikasi push
- **Dampak**: Dialog "Alarm & Pengingat" muncul saat app dijalankan
- **Fix**: Menghapus permintaan izin exact alarm

## File yang Diubah

### Core Services
1. **lib/services/push_notification_service.dart**
   - ✅ Subscribe otomatis saat user sudah login
   - ✅ Ubah `'read'` → `'is_read'`
   - ✅ Hapus izin exact alarm
   - ✅ Hapus referensi `read_at` (kolom tidak ada di database)

2. **lib/services/notification_helper.dart**
   - ✅ Ubah `'read'` → `'is_read'`

3. **lib/services/chat_service.dart**
   - ✅ Ubah `'read'` → `'is_read'` untuk notifikasi chat

### Models
4. **lib/models/push_notification.dart**
   - ✅ Ubah parsing `'read'` → `'is_read'`
   - ✅ Ubah serialization `'read'` → `'is_read'`
   - ✅ Hapus field `read_at` (tidak ada di database)

### Debug Tools
5. **lib/services/notification_debug_helper.dart** (BARU)
   - ✅ Tool untuk testing sistem notifikasi
   - ✅ Dapat mengirim test notification
   - ✅ Memeriksa koneksi realtime
   - ✅ Melihat notifikasi terbaru

## Cara Testing

### 1. Test Notifikasi Payment Verification

**Admin Side:**
```dart
// Di payment confirmation screen
// Approve payment
await SupabaseService.verifyPaymentProof(
  proofId: proofId,
  isApproved: true,
);
```

**User Side:**
- Notifikasi harus muncul: "Pembayaran Terverifikasi! ✅"
- Body: "Pembayaran Anda untuk booking [venue] telah terverifikasi. Tap untuk download E-Tiket."

### 2. Test Notifikasi Chat

**Kirim Pesan:**
```dart
await ChatService.sendMessage(
  message: 'Halo, ada pertanyaan',
  senderName: 'Test User',
  isAdmin: false,
);
```

**Penerima:**
- Notifikasi harus muncul: "Pesan baru dari Test User"
- Body: preview pesan

### 3. Test dengan Debug Helper

**Tambahkan button di UI:**
```dart
import 'package:sipelor/services/notification_debug_helper.dart';

// Di widget
ElevatedButton(
  onPressed: () async {
    await NotificationDebugHelper.runFullDiagnostic();
  },
  child: Text('Test Notifikasi'),
),
```

**Atau test individual:**
```dart
// Check connection
await NotificationDebugHelper.checkConnectionStatus();

// Send test notification
await NotificationDebugHelper.sendTestNotification();

// List recent notifications
await NotificationDebugHelper.listRecentNotifications();

// Test realtime subscription
await NotificationDebugHelper.testRealtimeSubscription();
```

### 4. Manual Test di Supabase

**Query notifications:**
```sql
SELECT * FROM notifications 
WHERE user_id = '[user_id]'
ORDER BY created_at DESC
LIMIT 10;
```

**Insert test notification:**
```sql
INSERT INTO notifications (user_id, type, title, body, is_read)
VALUES (
  '[user_id]',
  'general',
  'Manual Test',
  'Testing from Supabase SQL editor',
  false
);
```

## Checklist Validasi

### ✅ **Setup Complete**
- [x] Push notification service diinisialisasi di [main.dart](./lib/main.dart)
- [x] Service subscribe saat user sudah login
- [x] Auth listener setup untuk handle login/logout
- [x] Local notifications permission requested

### ✅ **Database Schema Fixed**
- [x] Semua kode menggunakan `is_read` bukan `read`
- [x] Field `read_at` dihapus dari kode (tidak ada di database)
- [x] Data types sesuai dengan schema database

### ✅ **Notification Creation**
- [x] Payment verification creates notification
- [x] Chat messages create notification
- [x] Booking status changes create notification
- [x] All notification types use correct schema

### 🔍 **Testing Required**
- [ ] Test payment verification → user terima notifikasi
- [ ] Test chat message → penerima terima notifikasi
- [ ] Test booking completion → user terima notifikasi review reminder
- [ ] Test notification tap → navigate ke screen yang benar

## Console Logs untuk Monitor

### Saat App Start (Success):
```
✅ Push notification service initialized
👤 [PushNotification] User already logged in, subscribing to notifications...
🔌 [PushNotification] Creating channel for user: [user_id]
📡 [PushNotification] Channel status: RealtimeSubscribeStatus.subscribed
✅ [PushNotification] Successfully subscribed to notifications
```

### Saat Notifikasi Diterima (Success):
```
🔔 [PushNotification] New notification received: {user_id: ..., title: ..., body: ...}
📬 [PushNotification] Processing notification data: ...
✅ [PushNotification] Notification type is enabled, proceeding...
🔔 [PushNotification] Showing local notification...
✅ [PushNotification] Local notification shown successfully
```

### Jika Ada Masalah:
```
❌ [PushNotification] Error subscribing to notifications: ...
⚠️ [PushNotification] No user logged in, skipping subscription
❌ [NotificationHelper] Error creating notification: ...
```

## Kemungkinan Masalah Lain

Jika notifikasi masih tidak muncul setelah fix ini, periksa:

### 1. Supabase Realtime Settings
- Buka Supabase Dashboard → Settings → API
- Pastikan **Realtime** is enabled
- Enable realtime untuk table `notifications`

### 2. Row Level Security (RLS) Policies

**Check policies:**
```sql
SELECT * FROM pg_policies 
WHERE tablename = 'notifications';
```

**Required policies:**
```sql
-- Users can read their own notifications
CREATE POLICY "Users can read own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- System can insert notifications
CREATE POLICY "System can insert notifications"
ON notifications FOR INSERT
WITH CHECK (true);

-- Users can update their own notifications
CREATE POLICY "Users can update own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);
```

### 3. Schema Cache Issue

Jika masih error "column not found", coba refresh schema:
```sql
NOTIFY pgrst, 'reload schema';
```

Atau restart Supabase Realtime dari dashboard.

### 4. Permission Issues (Android 13+)

Pastikan user sudah grant notification permission:
```dart
// Check di app
final permissionGranted = await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();

print('Notification permission: $permissionGranted');
```

## Next Steps

1. **Restart aplikasi** untuk memastikan semua perubahan apply
2. **Login** dengan akun user
3. **Check console logs** untuk memastikan subscription berhasil
4. **Test** dengan salah satu skenario di atas
5. **Verifikasi** notifikasi muncul di layar

## Support

Jika masih ada masalah, periksa:
- Console logs untuk error message
- Supabase Dashboard → Table Editor → notifications (apakah data ter-insert?)
- Supabase Dashboard → Logs → Realtime (apakah ada error?)

Atau gunakan debug helper untuk diagnostic:
```dart
await NotificationDebugHelper.runFullDiagnostic();
```
