# Top Notification Banner - Usage Guide

## Overview

`TopNotificationBanner` adalah custom widget yang menampilkan notifikasi dengan animasi slide down dari atas layar. Lebih elegan dan modern dibanding SnackBar.

## Features

✅ **Animasi Smooth** - Slide down dari atas dengan curve `easeOutBack`
✅ **Auto Dismiss** - Otomatis hilang setelah durasi tertentu
✅ **Swipe to Dismiss** - User bisa swipe up untuk menutup
✅ **Tap Action** - Bisa ditambahkan onTap callback
✅ **4 Variants** - Success, Info, Warning, Error
✅ **Gradient Background** - Tampilan modern dengan gradient
✅ **Shadow Effect** - Depth effect dengan shadow
✅ **Sound Notification** - System notification sound otomatis
✅ **Vibration Feedback** - Haptic feedback saat muncul
✅ **Real-time Trigger** - Langsung muncul tanpa delay saat status berubah

## Usage Examples

### 1. Success Notification (with Sound & Vibration)

```dart
TopNotificationBanner.showSuccess(
  context: context,
  title: '✅ Booking Dikonfirmasi',
  message: 'Pemesanan Anda telah dikonfirmasi! Tap untuk download E-Tiket.',
  onTap: () {
    // Navigate to bookings screen
    Navigator.push(context, ...);
  },
  duration: const Duration(seconds: 6),
  playSound: true,  // Play system notification sound
  vibrate: true,     // Vibrate device
);
```

### 2. Info Notification

```dart
TopNotificationBanner.showInfo(
  context: context,
  title: '📢 Informasi',
  message: 'Ada update jadwal untuk booking Anda.',
  duration: const Duration(seconds: 4),
);
```

### 3. Warning Notification

```dart
TopNotificationBanner.showWarning(
  context: context,
  title: '⚠️ Perhatian',
  message: 'Pembayaran akan expired dalam 5 menit!',
  onTap: () {
    // Navigate to payment screen
  },
  duration: const Duration(seconds: 6),
);
```

### 4. Error Notification

```dart
TopNotificationBanner.showError(
  context: context,
  title: '❌ Gagal',
  message: 'Gagal memproses pembayaran. Silakan coba lagi.',
  duration: const Duration(seconds: 4),
);
```

## Implementation in Home Screen

Notifikasi otomatis muncul di **Home Screen** ketika:

1. **Admin mengkonfirmasi booking** → Notifikasi success muncul **LANGSUNG**
2. **Real-time update** via Supabase → Detect perubahan status instan
3. **Immediate trigger** → Notifikasi muncul tanpa delay (< 1 detik)
4. **Sound + Vibration** → Feedback audio dan haptic otomatis
5. **Periodic check** setiap 30 detik → Fallback jika realtime gagal
6. **App resume** → Check notifikasi saat kembali ke foreground

### Flow Diagram (Real-time)

```
Admin clicks "Konfirmasi" button
       ↓ (< 1 second)
Supabase realtime callback triggered
       ↓ (immediate)
Check status change: pending → confirmed
       ↓ (immediate)
Play notification sound + vibrate
       ↓ (immediate)
Show TopNotificationBanner with animation
       ↓
User sees & hears notification
       ↓
User taps notification
       ↓
Navigate to Bookings tab
```

### Real-time Optimization

**Sebelum** (delay ~2-5 detik):
```dart
callback: (payload) {
  _loadBookingNotifications(); // fetch all bookings first
}
```

**Sesudah** (instant < 1 detik):
```dart
callback: (payload) {
  // Check payload immediately
  if (status changed to 'confirmed') {
    show notification NOW!  // instant, no fetch needed
  }
  _loadBookingNotifications(); // update badge later
}
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `context` | BuildContext | ✅ | Build context untuk overlay |
| `title` | String | ✅ | Judul notifikasi (bold, besar) |
| `message` | String | ✅ | Pesan detail notifikasi |
| `onTap` | VoidCallback? | ❌ | Callback ketika notifikasi di-tap |
| `duration` | Duration | ❌ | Durasi tampil (default 4 detik) |
| `playSound` | bool | ❌ | Play notification sound (default true) |
| `vibrate` | bool | ❌ | Vibrate device (default true) |

## Customization

### Colors

Setiap variant memiliki gradient warna berbeda:

- **Success**: Hijau (#007148) → Biru (#0075A4)
- **Info**: Biru muda (#2196F3) → Biru tua (#1976D2)
- **Warning**: Orange (#FF9800) → Orange tua (#F57C00)
- **Error**: Merah (#F44336) → Merah tua (#D32F2F)

### Animation Timing

- **Slide In**: 400ms dengan curve `easeOutBack`
- **Fade In**: 400ms dengan curve `easeIn`
- **Auto Dismiss**: Configurable (default 4 detik)

## Best Practices

✅ **DO:**
- Gunakan untuk notifikasi penting (booking confirmed, payment success)
- Berikan pesan yang jelas dan actionable
- Tambahkan onTap untuk navigate ke detail
- Gunakan durasi yang cukup (5-6 detik untuk baca + tap)
- Enable sound + vibration untuk notifikasi penting
- Trigger immediately di realtime callback untuk response cepat

❌ **DON'T:**
- Jangan spam notifikasi (tunggu yang sebelumnya hilang)
- Jangan gunakan untuk error yang perlu action immediate
- Jangan terlalu panjang message (max 3 lines)
- Jangan durasi terlalu pendek (< 3 detik)
- Jangan disable sound/vibration kecuali ada alasan kuat
- Jangan delay notification (show immediately di realtime callback)

## Sound & Vibration

Notifikasi menggunakan **system default notification sound** dan **haptic feedback**:

### Packages Used:

1. **flutter_ringtone_player** - Play system notification sound
   - Menggunakan built-in system sound (tidak perlu audio file)
   - Support Android & iOS
   - Otomatis respect device sound settings
   
2. **vibration** - Haptic feedback
   - Short vibration (200ms) saat notifikasi muncul
   - Check device capability sebelum vibrate
   - Graceful fallback jika device tidak support

### Behavior:

```dart
// Sound
await FlutterRingtonePlayer().playNotification();
// → Plays system default notification sound

// Vibration
final hasVibrator = await Vibration.hasVibrator() ?? false;
if (hasVibrator) {
  await Vibration.vibrate(duration: 200);
}
// → Short vibration if device supports it
```

### Error Handling:

Jika sound/vibration gagal (permission denied, tidak support, dll):
- ✅ Notifikasi tetap muncul
- ✅ Error di-catch dan di-log
- ✅ Silent failure (tidak crash app)

## Comparison with SnackBar

| Feature | TopNotificationBanner | SnackBar |
|---------|----------------------|----------|
| Position | Top (slide down) | Bottom |
| Animation | Smooth slide + fade | Slide up |
| Dismissal | Swipe up / Auto | Swipe / Auto |
| Overlay | Full overlay | Bottom only |
| Tap action | ✅ Full card | ❌ Button only |
| Visual | Modern gradient | Flat color |
| Attention | High (dari atas) | Medium |
| Sound | ✅ System sound | ❌ Silent |
| Vibration | ✅ Haptic feedback | ❌ No vibration |
| Real-time | ✅ Instant trigger | ⚠️ Manual only |

## Integration Points

File yang sudah terintegrasi:

1. ✅ `lib/screens/home_screen.dart` - Real-time trigger saat booking confirmed
2. ✅ `lib/screens/user_bookings_screen.dart` - Show saat user buka tab bookings
3. ✅ `lib/widgets/top_notification_banner.dart` - Widget utama dengan sound/vibration
4. ✅ `pubspec.yaml` - Added flutter_ringtone_player & vibration packages

## Testing

### Manual Testing Steps:

1. Login sebagai user
2. Buat booking baru
3. Login sebagai admin (di browser/tab lain)
4. Konfirmasi booking user tersebut
5. Kembali ke app user (home screen)
6. **Notifikasi harus muncul dari atas** dalam beberapa detik

### Expected Behavior:

- ✅ Notifikasi slide down dari atas dengan smooth animation
- ✅ **System notification sound plays** (bunyi notifikasi sesuai device)
- ✅ **Device vibrates** (200ms haptic feedback)
- ✅ Tampil di home screen **LANGSUNG** (< 1 detik setelah admin confirm)
- ✅ Auto dismiss setelah 6 detik
- ✅ Tap notifikasi → navigate ke tab Bookings
- ✅ Swipe up → notifikasi hilang
- ✅ Badge notification di navbar ikut update
- ✅ Realtime: tidak perlu refresh/reload manual

## Troubleshooting

**Issue**: Notifikasi tidak muncul
**Solution**:
- Check realtime subscription: `✅ [Realtime] Successfully subscribed to booking notifications`
- Check status change log: `📡 [Realtime] Status change: pending → confirmed`
- Check immediate show log: `🎉 [Realtime] Booking confirmed! Showing notification immediately...`
- Check periodic refresh: `⏰ [Periodic] Auto-refreshing notifications...`
- Pastikan user ada di home screen (index 0)

**Issue**: Tidak ada suara notifikasi
**Solution**:
- Check device sound settings (tidak mute/silent mode)
- Check app permission untuk audio
- Lihat log error: `❌ [Notification] Error playing feedback:`
- Pastikan `playSound: true` di parameter

**Issue**: Tidak ada vibration
**Solution**:
- Check device support vibration (some devices tidak support)
- Check app permission untuk vibration
- Pastikan `vibrate: true` di parameter
- Silent failure adalah normal behavior (tidak crash)

**Issue**: Notifikasi muncul di tab lain
**Solution**:
- Code sudah filter: `if (_currentNavIndex == 0)` di home screen
- Pastikan kondisi ini tidak dihapus

**Issue**: Notifikasi overlap
**Solution**:
- Otomatis dismiss notifikasi sebelumnya saat show baru
- Lihat: `TopNotificationBanner.dismiss()` dipanggil di `_show()`

## Future Enhancements

- [ ] Queue system untuk multiple notifications
- [ ] Custom animation curves
- [ ] Sound/haptic feedback option
- [ ] Action buttons (selain tap full card)
- [ ] Progress indicator untuk duration
- [ ] Dark mode support
