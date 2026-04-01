# ⚡ Quick Fix Guide - Database RLS Policy Error

## 🚨 Critical Issue
**Error:** `PostgrestException: infinite recursion detected in policy for relation "profiles"`

**Affected Features:**
- 🔴 Chat (tidak bisa kirim pesan)
- 🔴 Booking (tidak bisa create booking) 
- 🔴 Profile (data tidak tampil)

---

## ✅ Solusi Cepat (5 menit)

### Langkah 1: Login ke Supabase
1. Buka https://app.supabase.com
2. Login dengan akun admin
3. Pilih project SIPELOR

### Langkah 2: Jalankan SQL Fix
1. Klik menu **SQL Editor** di sidebar kiri
2. Buka file `docs/SUPABASE_SQL_SCRIPTS_SAFE.sql` di project ini ⭐ **USE THIS ONE**
3. **Copy SEMUA isi file** (Ctrl+A, Ctrl+C)
4. **Paste ke SQL Editor** di Supabase
5. Klik tombol **RUN** (atau tekan F5)

**Note:** Jika sudah pernah run script dan ada error "policy already exists", gunakan file `SUPABASE_SQL_SCRIPTS_SAFE.sql` yang otomatis drop semua policy lama terlebih dahulu.

### Langkah 3: Restart App
```bash
# Stop app yang sedang berjalan
# Kemudian restart:
flutter clean
flutter pub get
flutter run
```

### Langkah 4: Test
Test fitur-fitur berikut:
- ✅ Buka chat, kirim pesan
- ✅ Buat booking baru
- ✅ Buka profile, cek data tampil

---

## 📋 Detail Fix (Apa yang Dilakukan?)

SQL script akan melakukan:

1. **Drop policies lama yang bermasalah**
   - Menghapus RLS policies dengan circular reference

2. **Create policies baru yang benar**
   - Profiles: Allow users read own profile, admin read all
   - Chat: Allow users & admin send/read messages
   - Bookings: Allow users create own, admin manage all

3. **Create RPC function**
   - Bypass RLS untuk internal queries
   - Lebih aman dan efisien

4. **Grant permissions**
   - Authenticated users dapat akses tabel yang dibutuhkan

---

## ❓ Troubleshooting

### Error: "policy already exists"

Jika muncul error:
```
ERROR: 42710: policy "Users can insert own profile" for table "profiles" already exists
```

**Solusi:**
1. ❌ JANGAN gunakan `SUPABASE_SQL_SCRIPTS.sql`
2. ✅ GUNAKAN `SUPABASE_SQL_SCRIPTS_SAFE.sql` sebagai gantinya
3. Script SAFE akan otomatis drop semua policy lama terlebih dahulu

### Error masih terjadi setelah run SQL?

**1. Cek apakah SQL berhasil dijalankan:**
```sql
-- Run di SQL Editor untuk verify
SELECT * FROM pg_policies 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');
```
Harus ada policy-policy baru yang tercantum di [SUPABASE_SQL_SCRIPTS.sql](./SUPABASE_SQL_SCRIPTS.sql)

**2. Clear app cache:**
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

**3. Logout & Login ulang di app**
- Buka app → Profile → Logout
- Login kembali dengan username & password

**4. Cek Supabase logs:**
- Dashboard → Logs → Filter by "error"
- Cari error message terbaru

### Profile masih kosong?

Kemungkinan data profile belum ada di database:
```sql
-- Cek di SQL Editor
SELECT * FROM profiles WHERE email = 'your-email@example.com';
```

Jika kosong, profile akan dibuat otomatis saat:
- Edit profile pertama kali
- Atau login/signup ulang

---

## 📞 Kontak Support

Jika masalah belum teratasi setelah mengikuti panduan ini:

1. Screenshot error message
2. Copy logs dari console (`flutter logs`)
3. Hubungi tim developer dengan informasi di atas

---

## 📚 Dokumentasi Lengkap

Untuk penjelasan detail dan advanced troubleshooting:
- [SUPABASE_RLS_POLICY_FIX.md](./SUPABASE_RLS_POLICY_FIX.md) - Panduan lengkap
- [SUPABASE_SQL_SCRIPTS.sql](./SUPABASE_SQL_SCRIPTS.sql) - SQL scripts
- [README.md](./README.md) - Dokumentasi index

---

**⏱️ Estimasi waktu fix: 5-10 menit**
**✅ One-time fix, tidak perlu diulang**
