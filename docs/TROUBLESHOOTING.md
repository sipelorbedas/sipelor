# 🔧 Troubleshooting Guide

Panduan mengatasi error umum saat fix RLS policies.

---

## Error: "policy already exists"

### Full Error Message:
```
Error: Failed to run sql query: ERROR: 42710: policy "Users can insert own profile" for table "profiles" already exists
```

### Penyebab:
SQL script mencoba create policy yang sudah ada di database.

### Solusi:

**Option 1: Gunakan Script SAFE (RECOMMENDED)** ⭐
```sql
-- File: docs/SUPABASE_SQL_SCRIPTS_SAFE.sql
-- Script ini otomatis drop semua policy lama sebelum create yang baru
```

1. Copy isi file `docs/SUPABASE_SQL_SCRIPTS_SAFE.sql`
2. Paste di Supabase SQL Editor
3. Run script
4. Done! ✅

**Option 2: Manual Drop Policies**

Jika tetap ingin menggunakan script biasa:

1. **Drop semua policy terlebih dahulu:**
```sql
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename IN ('profiles', 'chat_messages', 'bookings')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.tablename;
    END LOOP;
END $$;
```

2. **Kemudian run script biasa:** `SUPABASE_SQL_SCRIPTS.sql`

---

## Error: "infinite recursion detected"

### Full Error Message:
```
PostgrestException(message: infinite recursion detected in policy for relation "profiles", code: 42P17)
```

### Penyebab:
RLS policies memiliki circular reference.

### Solusi:
Run SQL fix script:
1. Gunakan `SUPABASE_SQL_SCRIPTS_SAFE.sql`
2. Restart Flutter app
3. Logout & login kembali

---

## Error: "permission denied"

### Full Error Message:
```
PostgrestException(message: permission denied for table profiles, code: 42501)
```

### Penyebab:
- RLS policies terlalu ketat
- User tidak punya permission

### Solusi:

**1. Cek apakah RLS enabled:**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');
```

**2. Cek policies yang ada:**
```sql
SELECT * FROM pg_policies 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');
```

**3. Grant permissions:**
```sql
GRANT SELECT ON profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON chat_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON bookings TO authenticated;
```

**4. Rerun fix script** jika policies salah.

---

## Error: Chat masih tidak berfungsi setelah fix

### Troubleshooting Steps:

**1. Verify policies berhasil dibuat:**
```sql
-- Harus ada minimal 5 policies untuk profiles
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'profiles';

-- Harus ada minimal 7 policies untuk chat_messages
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'chat_messages';
```

**2. Test RPC function:**
```sql
-- Ganti 'your-user-id' dengan actual user ID
SELECT * FROM get_user_profile_data('your-user-id');
```

**3. Clear app cache:**
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

**4. Logout & login ulang di app**

---

## Error: Booking masih gagal

### Cek hal berikut:

**1. Verify bookings table policies:**
```sql
SELECT * FROM pg_policies WHERE tablename = 'bookings';
```
Harus ada minimal 5 policies.

**2. Test create booking:**
```sql
-- Test sebagai authenticated user
INSERT INTO bookings (
  user_id, field_id, venue_id, 
  booking_date, start_time, end_time,
  duration_hours, total_amount,
  status, payment_status
) VALUES (
  auth.uid(),
  'test-field-id',
  'test-venue-id',
  '2026-02-01',
  '10:00:00',
  '12:00:00',
  2,
  100000,
  'pending',
  'pending'
);
```

**3. Cek error logs:**
```bash
flutter logs | grep -i "CreateBooking"
```

---

## Error: Profile data tidak tampil

### Troubleshooting:

**1. Cek apakah data ada di database:**
```sql
SELECT * FROM profiles WHERE id = auth.uid();
```

**2. Jika data kosong, insert manual:**
```sql
INSERT INTO profiles (
  id, username, full_name, email
) VALUES (
  auth.uid(),
  'your-username',
  'Your Full Name',
  'your-email@example.com'
);
```

**3. Test RPC function:**
```sql
SELECT * FROM get_user_profile_data(auth.uid());
```

**4. Restart app & reload profile**

---

## Verification Checklist

Setelah run fix script, verify semua OK:

### Database Policies
```sql
-- Should return ~5 rows
SELECT COUNT(*) as profiles_policies 
FROM pg_policies WHERE tablename = 'profiles';

-- Should return ~7 rows  
SELECT COUNT(*) as chat_policies 
FROM pg_policies WHERE tablename = 'chat_messages';

-- Should return ~5 rows
SELECT COUNT(*) as booking_policies 
FROM pg_policies WHERE tablename = 'bookings';
```

### RLS Status
```sql
-- All should be TRUE
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');
```

### RPC Function
```sql
-- Should return function details
SELECT proname, proargnames 
FROM pg_proc 
WHERE proname = 'get_user_profile_data';
```

### Permissions
```sql
-- Should show authenticated has SELECT, INSERT, UPDATE
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name IN ('profiles', 'chat_messages', 'bookings')
AND grantee = 'authenticated';
```

---

## Still Having Issues?

### Debug Mode
Enable debug logging di Flutter:

```dart
// lib/services/supabase_service.dart
static const bool enableDebugLogs = true;
```

### Check Logs
```bash
# Flutter logs
flutter logs

# Filter for errors
flutter logs | grep -i error

# Filter for specific features
flutter logs | grep -i "CreateBooking\|ChatService\|ProfileScreen"
```

### Contact Support
Jika masih error setelah mengikuti semua steps:

1. Screenshot error message
2. Copy logs dari console
3. Export policies dari Supabase:
```sql
SELECT * FROM pg_policies 
WHERE tablename IN ('profiles', 'chat_messages', 'bookings');
```
4. Hubungi tim developer dengan informasi di atas

---

## Quick Reference

| Error | File to Use |
|-------|------------|
| "policy already exists" | `SUPABASE_SQL_SCRIPTS_SAFE.sql` |
| "infinite recursion" | `SUPABASE_SQL_SCRIPTS_SAFE.sql` |
| "permission denied" | Re-run script + check grants |
| Chat tidak jalan | Verify chat_messages policies |
| Booking gagal | Verify bookings policies |
| Profile kosong | Check if profile data exists |

---

**Last Updated:** 2026-01-27
