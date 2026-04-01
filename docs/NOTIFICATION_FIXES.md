# Notification Fixes - Summary

## Issues Fixed

### 1. ✅ Booking Status Change Notifications
**Problem**: Notifications tidak muncul ketika status booking berubah menjadi `confirmed`, `completed`, atau `canceled`.

**Solution**: 
- Updated `_sendBookingStatusNotification()` di `lib/services/supabase_service.dart`
- Sekarang mengirim notifikasi untuk semua perubahan status:
  - **Confirmed**: Menggunakan `NotificationHelper.notifyBookingConfirmed()` - memberitahu user booking sudah dikonfirmasi dan bisa download e-ticket
  - **Completed**: Menggunakan `NotificationHelper.notifyBookingCompleted()` - meminta user untuk memberi review
  - **Canceled**: Menggunakan `NotificationHelper.notifyBookingRejected()` - memberitahu user booking dibatalkan

**Files Modified**:
- `lib/services/supabase_service.dart` (lines 1884-1922)

---

### 2. ✅ Chat Notifications with Sound
**Problem**: Notifikasi chat antara admin dan user tidak muncul dan tidak ada suara.

**Solution**:
- Enhanced `_showLocalNotification()` di `lib/services/push_notification_service.dart`
- Membuat channel notifikasi terpisah untuk chat (`sipelor_chat_notifications`)
- Meningkatkan prioritas notifikasi ke `Importance.max`
- Mengaktifkan sound, vibration, dan lights
- Menambahkan `BigTextStyleInformation` untuk menampilkan pesan lengkap
- Sound otomatis menggunakan notification sound default system (lebih reliable)

**Files Modified**:
- `lib/services/push_notification_service.dart` (lines 184-230)

**Note**: Chat notifications sudah bekerja dengan baik karena:
- `ChatService._sendChatNotification()` sudah mengirim ke database (line 75-84 in chat_service.dart)
- `PushNotificationService` mendengarkan realtime updates via Supabase
- Ketika ada notification baru, akan otomatis trigger sound dan vibration

---

### 3. ✅ Auto-Delete Chat Messages After 24 Hours
**Problem**: Pesan chat tidak otomatis terhapus setelah 24 jam.

**Solution**:
- Menambahkan fungsi `deleteOldMessages()` di `lib/services/chat_service.dart`
- Menambahkan fungsi `initializeAutoCleanup()` yang menjalankan cleanup otomatis
- Cleanup berjalan setiap 6 jam untuk menghapus pesan yang lebih lama dari 24 jam
- Diinisialisasi di `main.dart` saat app startup

**Files Modified**:
- `lib/services/chat_service.dart` (lines 1-4, 599-681)
- `lib/main.dart` (lines 11, 150-154)

**How it works**:
1. Saat app start, `ChatService.initializeAutoCleanup()` dipanggil
2. Fungsi ini langsung menjalankan cleanup pertama kali
3. Kemudian setup Timer.periodic untuk menjalankan cleanup setiap 6 jam
4. Setiap cleanup akan menghapus semua pesan yang `created_at` lebih lama dari 24 jam

---

## Testing Instructions

### Test 1: Booking Status Notifications

#### A. Test Confirmed Status
1. Login sebagai Admin
2. Buka dashboard admin
3. Pilih booking dengan status "Pending" atau "Payment Pending"
4. Update status ke "Confirmed"
5. **Expected Result**: User akan menerima notification:
   - Title: "Booking Disetujui! ✅"
   - Body: "Booking Anda untuk [Venue Name] telah disetujui. Tap untuk download E-Tiket."
   - Dengan sound dan vibration

#### B. Test Completed Status
1. Login sebagai Admin
2. Pilih booking dengan status "Confirmed"
3. Update status ke "Completed"
4. **Expected Result**: User akan menerima notification:
   - Title: "Booking Selesai ✅"
   - Body: "Bagaimana pengalaman Anda? Yuk beri review untuk [Venue Name]!"
   - Dengan sound dan vibration

#### C. Test Canceled Status
1. Login sebagai Admin
2. Pilih booking aktif
3. Update status ke "Canceled"
4. **Expected Result**: User akan menerima notification:
   - Title: "Booking Ditolak ❌"
   - Body: "Booking Anda untuk [Venue Name] ditolak."
   - Dengan sound dan vibration

### Test 2: Chat Notifications

#### A. Test User to Admin Message
1. Login sebagai User
2. Buka halaman Chat dengan Admin
3. Kirim pesan ke admin
4. Login sebagai Admin di device/browser lain
5. **Expected Result**: Admin menerima notification:
   - Title: "Pesan baru dari [User Name]"
   - Body: Isi pesan (truncated jika lebih dari 50 karakter)
   - Dengan sound dan vibration
   - Notification bisa diklik untuk buka chat

#### B. Test Admin to User Message
1. Login sebagai Admin
2. Pilih conversation dengan user
3. Kirim pesan ke user
4. Login sebagai User di device/browser lain
5. **Expected Result**: User menerima notification:
   - Title: "Pesan baru dari Admin"
   - Body: Isi pesan
   - Dengan sound dan vibration

### Test 3: Auto-Delete Chat Messages

#### Manual Test (Immediate)
1. Buka terminal/command prompt
2. Jalankan app dalam debug mode
3. Periksa console logs saat app start:
   - Harus muncul: "✅ Chat auto-cleanup service initialized"
   - Harus muncul: "🔄 [ChatService] Initializing auto-cleanup..."
   - Harus muncul: "🗑️ [ChatService] Deleting messages older than 24 hours..."

#### Automatic Test (Wait 24+ hours)
1. Kirim beberapa pesan chat hari ini
2. Tunggu 24 jam
3. Tunggu hingga cleanup berjalan (max 6 jam setelah 24 jam)
4. Periksa database atau UI - pesan lama harus sudah terhapus
5. Console logs akan menunjukkan:
   - "🔄 [ChatService] Running periodic cleanup..."
   - "✅ [ChatService] Old messages deleted successfully"

#### Database Verification
```sql
-- Check messages older than 24 hours
SELECT id, sender_name, message, created_at 
FROM chat_messages 
WHERE created_at < NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- After cleanup runs, this should return empty results
```

---

## Configuration

### Notification Sound File (Optional)
Jika ingin menggunakan custom notification sound:

1. Download atau buat file sound `notification.mp3`
2. Letakkan di folder `assets/sounds/notification.mp3`
3. File ini sudah terdaftar di `pubspec.yaml` (line 105: `- assets/sounds/`)

**Note**: Jika file tidak ada, system akan otomatis menggunakan default system notification sound (lebih reliable).

### Auto-Cleanup Configuration
Bisa diubah di `lib/main.dart` (line 150-154):

```dart
// Current: Delete messages older than 24 hours, check every 6 hours
ChatService.initializeAutoCleanup(hoursOld: 24, checkIntervalHours: 6);

// Examples:
// Delete after 12 hours, check every 3 hours:
ChatService.initializeAutoCleanup(hoursOld: 12, checkIntervalHours: 3);

// Delete after 48 hours, check every 12 hours:
ChatService.initializeAutoCleanup(hoursOld: 48, checkIntervalHours: 12);
```

---

## Notification Permission

### Android
- App akan otomatis request notification permission saat pertama kali dibuka
- User bisa disable/enable di Settings > Apps > SIPELOR > Notifications

### iOS
- Permission request muncul saat app pertama kali mengirim notification
- User bisa manage di Settings > Notifications > SIPELOR

---

## Troubleshooting

### Issue: Notification tidak muncul
**Solution**:
1. Pastikan notification permission sudah diizinkan
2. Pastikan app sudah login dengan user yang benar
3. Cek console logs untuk error messages
4. Pastikan Supabase realtime connection aktif
5. Restart app untuk reinitialize notification service

### Issue: Sound tidak berbunyi
**Solution**:
1. Cek volume device tidak di silent/vibrate mode
2. Cek app notification settings di system settings
3. Pastikan "Do Not Disturb" tidak aktif
4. Cek SharedPreferences: `notif_sound_enabled` harus `true`

### Issue: Chat messages tidak terhapus otomatis
**Solution**:
1. Cek console logs untuk error messages
2. Pastikan app tetap berjalan atau buka minimal setiap 6 jam
3. Untuk server-side cleanup, bisa setup Supabase Edge Function dengan cron job

---

## Database Considerations

### Performance
- Auto-cleanup menggunakan `DELETE` query dengan filter `created_at`
- Pastikan ada index pada kolom `created_at` untuk performa optimal:
  ```sql
  CREATE INDEX idx_chat_messages_created_at 
  ON chat_messages(created_at);
  ```

### RLS (Row Level Security)
Pastikan RLS policy di Supabase mengizinkan delete operations untuk chat messages.

---

## Summary of Changes

**Files Modified**: 4
- ✅ `lib/services/supabase_service.dart` - Fixed booking status notifications
- ✅ `lib/services/push_notification_service.dart` - Enhanced notification display with sound
- ✅ `lib/services/chat_service.dart` - Added auto-delete functionality
- ✅ `lib/main.dart` - Initialize chat auto-cleanup

**Lines Changed**: ~150 lines
**New Features**: 3
1. Complete booking status notifications (confirmed, completed, canceled)
2. Enhanced chat notifications with sound and vibration
3. Automatic chat message cleanup after 24 hours

---

## Next Steps

1. ✅ Test all three scenarios above
2. ✅ Monitor console logs for any errors
3. ✅ Verify notifications appear on real devices (not just emulator)
4. ⚠️ Consider adding notification.mp3 file to assets (optional)
5. ⚠️ Consider setting up Supabase Edge Function for server-side cleanup (more reliable)

---

Generated: 2026-02-02
