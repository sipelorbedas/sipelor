# 🔧 Fix: Notification Tidak Muncul Saat Status Berubah

## ❌ Masalah Saat Ini

Berdasarkan log error:
```
❌ [NotificationHelper] Stack trace: dart-sdk/lib/_internal/js_dev_runtime/private/ddc_runtime/errors.dart 274:3 throw_
```

**Penyebab:** Notification insert gagal karena **RLS (Row Level Security) policy untuk INSERT tidak ada atau salah konfigurasi** di tabel `notifications`.

## ✅ Solusi

### Step 0: Check Status Terlebih Dahulu (WAJIB!)

**Jalankan diagnostic dulu untuk cek apa masalahnya:**

1. Buka **Supabase Dashboard** → SQL Editor
2. Copy semua isi file `database/CHECK_NOTIFICATION_POLICIES.sql`
3. Paste dan **Run**
4. Lihat output - terutama **CHECK 6: Test Insert**

**Jika CHECK 6 FAILED** → Lanjut ke Step 1  
**Jika CHECK 6 PASSED** → Skip ke Step 3 (masalah di Flutter, bukan database)

---

### Step 1: Jalankan SQL Script di Supabase (UPDATED!)

**⚠️ GUNAKAN V2 - Lebih robust dan ada diagnostics:**

1. Buka **Supabase Dashboard**
2. Pilih project Anda
3. Buka **SQL Editor**
4. Copy semua isi file `database/FIX_NOTIFICATION_RLS_POLICY_V2.sql` (BUKAN V1!)
5. Paste di SQL Editor
6. Klik **Run** atau tekan `Ctrl+Enter`

**Expected Output:**
```
✅ Step 1: RLS already enabled
✅ Step 3: Dropped X existing policies
✅ Step 4: Created 3 policies (INSERT, SELECT, UPDATE)
✅ Step 5: Verified - 3 policies exist (1 for INSERT)
✅ Test 1 Success: Insert works with RLS DISABLED
✅ Test 2 Success: Insert works with RLS ENABLED
✅ Step 10: All permissions granted
✅✅✅ FINAL TEST SUCCESS! ✅✅✅
✅ NOTIFICATION RLS POLICY FIX V2 COMPLETE
```

**Jika ada test yang gagal:**
Script akan tetap lanjut dan memberikan diagnostics lengkap. Lihat output untuk identify masalahnya.

### Step 2: Run Diagnostic Lagi

Setelah run fix V2, jalankan diagnostic lagi:
```sql
-- Run CHECK_NOTIFICATION_POLICIES.sql lagi
```

Pastikan **CHECK 6 PASSED** sebelum lanjut ke Flutter.

---

### Step 3: Update Flutter Code (Already Done!)

File `lib/services/notification_helper.dart` sudah di-update dengan error logging yang lebih detail. Sekarang akan menampilkan:
- Error type (Permission denied, RLS violation, Schema error, etc.)
- Specific solution untuk setiap error type
- Full error details dari PostgreSQL

---

### Step 4: Rebuild & Test Flutter App

1. **Stop** Flutter app
2. **Clean build** (optional tapi recommended):
   ```powershell
   flutter clean
   flutter pub get
   ```
3. **Run** Flutter app lagi
4. Login sebagai admin
5. Ubah status booking:
   - `pending` → `confirmed` (akan kirim notif "Booking Disetujui")
   - `confirmed` → `completed` (akan kirim notif "Booking Selesai")

---

### Step 5: Check Console Logs (Improved!)

**Success logs yang diharapkan:**
```
📝 [NotificationHelper] Creating notification for user: xxx
📝 [NotificationHelper] Type: booking_approved
📝 [NotificationHelper] Title: Booking Disetujui! ✅
📝 [NotificationHelper] Body: Booking Anda untuk STADION JALAK HARUPAT telah disetujui...
📝 [NotificationHelper] Insert data: {...}
✅ [NotificationHelper] Notification created successfully  👈 INI HARUS MUNCUL!
```

**Jika masih error:**
```
❌ [NotificationHelper] Error creating notification: xxx
❌ [NotificationHelper] Stack trace: xxx
❌ [NotificationHelper] Insert data was: {...}
```

## 🔍 Troubleshooting

### Error: "permission denied for table notifications"

**Solusi:** RLS belum enabled atau policy belum dibuat. Jalankan ulang SQL script.

### Error: "new row violates row-level security policy"

**Solusi:** Policy WITH CHECK condition terlalu restrictive. Pastikan policy menggunakan `WITH CHECK (true)`.

### Notification Created tapi Tidak Muncul di Device

**Check:**

1. **Realtime Subscription**
   ```sql
   -- Di Supabase Dashboard → Database → Replication
   -- Pastikan 'notifications' table ada di replication list
   ```

2. **Push Notification Permission**
   - User sudah grant notification permission?
   - Check di Settings → Notifications

3. **PushNotificationService**
   - Service initialized di main.dart?
   - Check logs: `✅ [PushNotification] Initialized`

4. **Notification Settings**
   - User enable notification untuk booking updates?
   - Check di User Profile → Notification Settings

### Verify Notification di Database

```sql
-- Check notification ter-create di database
SELECT 
    id,
    user_id,
    type,
    title,
    body,
    is_read,
    created_at
FROM notifications 
WHERE user_id = 'ad5c7dd1-54b2-47fd-a491-3dc7cce181ed'  -- Ganti dengan user_id Anda
ORDER BY created_at DESC 
LIMIT 5;
```

**Jika ada data:** Berarti insert berhasil, masalah di delivery (realtime/push notification)  
**Jika tidak ada data:** Berarti insert gagal, masalah di RLS policy

## 📋 Checklist

- [ ] SQL script dijalankan di Supabase
- [ ] Test insert berhasil (lihat output SQL)
- [ ] Flutter app di-restart
- [ ] Change booking status di admin
- [ ] Console log menunjukkan "✅ Notification created successfully"
- [ ] Notification muncul di database (check via SQL)
- [ ] Notification muncul di user device

## 🎯 Root Cause Analysis

**Kenapa Error Terjadi:**

1. Tabel `notifications` memiliki RLS (Row Level Security) enabled
2. RLS policy untuk **INSERT** tidak ada atau misconfigured
3. Ketika NotificationHelper coba insert notification, database reject karena tidak ada policy yang allow
4. Insert gagal dengan error (sekarang di-catch, tidak block operasi utama)
5. Notification tidak ter-create di database
6. User tidak terima notification

**Kenapa Perlu WITH CHECK (true):**

- Policy `WITH CHECK (true)` artinya "allow insert for any row"
- Aman karena notification creation controlled di application layer
- Hanya specific services (NotificationHelper) yang call insert
- User tidak bisa arbitrary insert notification lewat API

## 📝 What Was Fixed in Code

File `lib/services/notification_helper.dart` sudah fixed:

1. ✅ **Line 43:** Removed `.select()` - tidak perlu response dari insert
2. ✅ **Line 54-56:** Removed `rethrow` - notification failure tidak block operasi utama
3. ✅ **Line 52:** Enhanced logging - print insert data saat error

**Yang Masih Perlu Di-Fix:**

- ❌ **Database RLS Policy** - Ini yang harus di-fix dengan SQL script di atas

## 🚀 After Fix

**What Happens:**

1. Admin change booking status → confirmed
2. `NotificationHelper.notifyBookingConfirmed()` called
3. Insert notification to database → **SUCCESS** ✅
4. Supabase Realtime triggers
5. PushNotificationService receives via subscription
6. Local notification shows to user
7. User sees notification! 🎉

**Benefits:**

- ✅ Notifications work reliably
- ✅ Main operations (booking, payment) never blocked
- ✅ Better error logging for debugging
- ✅ Simpler RLS policies (only need INSERT)

---

## ⚡ Quick Commands

```sql
-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'notifications';

-- Check existing policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'notifications';

-- Count notifications for user
SELECT COUNT(*) 
FROM notifications 
WHERE user_id = 'YOUR_USER_ID';

-- Recent notifications
SELECT type, title, body, created_at
FROM notifications 
WHERE user_id = 'YOUR_USER_ID'
ORDER BY created_at DESC 
LIMIT 10;
```

---

**Jika masih ada masalah setelah ini, share:**
1. Output dari SQL script
2. Console logs dari Flutter app
3. Results dari SQL verify queries di atas
