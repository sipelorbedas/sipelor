# 🐛 Chat Bug Fix - Instructions

## Masalah yang Diperbaiki

### 1. ❌ **Bug: Pesan muncul di semua user conversation**
**Gejala:** Ketika User A mengirim pesan "good job", pesan tersebut muncul di conversation User A, User B, User C, dll di Admin Dashboard.

**Penyebab:** 
- Pesan lama di database tidak memiliki `user_id` yang benar (NULL atau salah)
- Query tidak memfilter berdasarkan `user_id` dengan benar

**Solusi:**
- ✅ Update `fetchMessages()` untuk selalu memfilter berdasarkan `user_id`
- ✅ Update `subscribeToMessages()` untuk memfilter realtime messages berdasarkan `user_id`
- ✅ Update `fetchChatRoomsForAdmin()` untuk menghitung unread count dari pesan yang sudah di-filter
- ✅ Buat SQL script untuk memperbaiki pesan lama di database

### 2. ❌ **Bug: Semua dot hijau hilang ketika klik satu user**
**Gejala:** Ketika admin klik User A, dot hijau (unread indicator) hilang di User A, User B, User C, dll.

**Penyebab:** 
- Function `markAsRead()` tidak memfilter berdasarkan `user_id` conversation tertentu
- Semua pesan unread di-mark sebagai read, bukan hanya pesan dari user yang di-klik

**Solusi:**
- ✅ Update `markAsRead()` untuk menerima parameter `conversationUserId`
- ✅ Update semua pemanggilan `markAsRead()` di admin dashboard untuk mengirim `userId`
- ✅ Query sekarang memfilter: `WHERE user_id = conversationUserId AND read = false`

---

## 🚀 Langkah-langkah untuk Memperbaiki

### Step 1: Jalankan SQL Migration

1. Buka **Supabase Dashboard** → **SQL Editor**
2. Copy paste isi file [`FIX_CHAT_MESSAGES_USER_ID.sql`](./FIX_CHAT_MESSAGES_USER_ID.sql)
3. Klik **Run** untuk menjalankan script
4. Verifikasi hasilnya dengan query di bagian bawah script

**⚠️ PENTING:** Script ini akan mengupdate semua pesan lama agar memiliki `user_id` yang benar.

### Step 2: Test Chat Feature

1. **Login sebagai User A**
   - Buka chat dengan admin
   - Kirim pesan: "Halo admin, saya User A"
   
2. **Login sebagai User B** (browser/incognito lain)
   - Buka chat dengan admin
   - Kirim pesan: "Halo admin, saya User B"

3. **Login sebagai Admin**
   - Buka Admin Dashboard → Chat
   - Pastikan pesan User A **hanya muncul di conversation User A**
   - Pastikan pesan User B **hanya muncul di conversation User B**
   - Klik User A → pastikan **hanya dot hijau User A yang hilang**
   - Klik User B → pastikan **hanya dot hijau User B yang hilang**

### Step 3: Monitor Debug Logs

Jika masih ada masalah, cek debug log di console:

```
📥 [ChatService] Fetching messages for general chat for user: [user-id]
📊 [ChatService] User: User A (ID: xxx-xxx-xxx)
   Booking ID: null
   Messages count: 5
   - "Halo admin" by User A (userId: xxx-xxx-xxx, isAdmin: false, read: false)
   - "Halo juga" by Admin (userId: xxx-xxx-xxx, isAdmin: true, read: true)
   Unread count: 1
```

Pastikan setiap user memiliki `userId` yang benar di log.

---

## 📝 Files yang Diubah

1. **`lib/services/chat_service.dart`**
   - `markAsRead()` - Tambah parameter `conversationUserId`
   - `fetchChatRoomsForAdmin()` - Tambah debug logging
   - `subscribeToMessages()` - Tambah parameter `userId` dan filter

2. **`lib/widgets/admin/desktop_chat_interface_whatsapp.dart`**
   - `_loadMessages()` - Pass `conversationUserId` ke `markAsRead()`
   - `_setupRealtimeSubscription()` - Pass `userId` ke `subscribeToMessages()`

3. **`lib/widgets/admin/desktop_chat_interface.dart`**
   - `_loadMessages()` - Pass `conversationUserId` ke `markAsRead()`
   - `_setupRealtimeSubscription()` - Pass `userId` ke `subscribeToMessages()`

4. **`lib/screens/admin_chat_list_screen.dart`**
   - `onTap()` - Pass `conversationUserId` ke `markAsRead()`

5. **`docs/FIX_CHAT_MESSAGES_USER_ID.sql`** (NEW)
   - SQL script untuk memperbaiki pesan lama

---

## 🔍 Troubleshooting

### Pesan masih muncul di semua user

**Kemungkinan penyebab:**
1. SQL migration belum dijalankan
2. Masih ada pesan baru yang dikirim tanpa `user_id`

**Solusi:**
1. Jalankan SQL migration di Step 1
2. Cek query verification di script SQL:
   ```sql
   SELECT COUNT(*) as messages_without_user_id
   FROM chat_messages
   WHERE user_id IS NULL;
   ```
   Harusnya return 0 atau sangat sedikit

### Dot hijau masih hilang semua

**Kemungkinan penyebab:**
1. Code belum di-reload
2. Cache browser

**Solusi:**
1. Hot reload / restart app
2. Clear browser cache
3. Hard refresh (Ctrl + Shift + R)

### Pesan realtime tidak muncul

**Kemungkinan penyebab:**
1. Realtime subscription tidak setup dengan benar
2. Filter `userId` terlalu ketat

**Solusi:**
1. Cek log realtime:
   ```
   📡 [ChatService] Realtime event received!
   ⏭️  [ChatService] Skipping message (userId mismatch: expected xxx, got yyy)
   ```
2. Pastikan pesan memiliki `user_id` yang sama dengan conversation

---

## ✅ Expected Behavior After Fix

1. **Pesan Privacy:**
   - User A hanya lihat pesan User A ↔ Admin
   - User B hanya lihat pesan User B ↔ Admin
   - Admin lihat pesan per-user (tidak tercampur)

2. **Unread Indicator:**
   - Klik User A → hanya dot hijau User A hilang
   - Klik User B → hanya dot hijau User B hilang
   - Dot hijau user lain tetap ada

3. **Realtime Updates:**
   - User A kirim pesan → hanya muncul di conversation User A
   - User B kirim pesan → hanya muncul di conversation User B
   - Admin kirim pesan ke User A → hanya muncul di conversation User A

---

## 📞 Support

Jika masih ada masalah setelah mengikuti langkah-langkah di atas, cek:
1. Debug logs di console
2. Database queries di Supabase Dashboard
3. Network tab untuk melihat API responses

Happy coding! 🎉
