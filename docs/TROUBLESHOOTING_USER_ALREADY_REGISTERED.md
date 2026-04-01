# Troubleshooting: "User Already Registered" Error

## Problem

Ketika mencoba signup dengan email, muncul error:
```
❌ User already registered
Status code: 422
Error code: user_already_exists
```

Tetapi ketika cek di tabel `profiles`, user tidak ada atau hanya ada 1 admin.

---

## Root Cause

Supabase memiliki **DUA tabel terpisah**:

1. **`auth.users`** - Tabel Supabase Auth (mengelola authentication)
   - Anda TIDAK bisa melihat ini di Table Editor
   - Hanya bisa diakses via SQL Editor atau Authentication UI
   
2. **`public.profiles`** - Tabel custom aplikasi (mengelola profile data)
   - Ini yang Anda lihat di Table Editor
   - Data tambahan seperti username, bio, role, dll

**Yang terjadi**: User terdaftar di `auth.users` tapi TIDAK ada di `profiles`.

Ini bisa terjadi karena:
- Signup gagal di tengah jalan (auth berhasil, profile gagal)
- Profile dihapus manual tapi auth user tidak dihapus
- Trigger untuk membuat profile tidak berjalan

---

## Diagnosis

### Step 1: Cek auth.users Table

Buka **Supabase Dashboard** → **SQL Editor** → Run query ini:

```sql
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'goodwin.rama@gmail.com';
```

**Jika ada hasil**: User SUDAH terdaftar di auth.users ✅  
**Jika kosong**: Ada masalah lain ❌

### Step 2: Cek profiles Table

```sql
SELECT 
  id,
  email,
  username,
  role
FROM profiles
WHERE email = 'goodwin.rama@gmail.com';
```

**Jika kosong**: Ini konfirmasi masalahnya - user ada di auth tapi tidak di profiles ✅

### Step 3: Lihat Semua Mismatches

```sql
SELECT 
  au.id,
  au.email as auth_email,
  au.created_at,
  p.email as profile_email,
  p.username,
  CASE 
    WHEN p.id IS NULL THEN '❌ Missing Profile'
    ELSE '✅ OK'
  END as status
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
ORDER BY au.created_at DESC;
```

Ini akan menampilkan SEMUA user dan menunjukkan mana yang tidak punya profile.

---

## Solutions

### Solution 1: Delete User dari auth.users (RECOMMENDED)

Jika ini untuk testing atau Anda ingin user signup ulang:

```sql
-- Delete user dari Supabase Auth
DELETE FROM auth.users 
WHERE email = 'goodwin.rama@gmail.com';

-- Verify sudah terhapus
SELECT COUNT(*) FROM auth.users 
WHERE email = 'goodwin.rama@gmail.com';
-- Harus return 0
```

✅ **Sekarang user bisa signup lagi dengan email yang sama**

---

### Solution 2: Create Profile untuk User yang Sudah Ada

Jika Anda ingin keep auth user dan hanya perlu create profilenya:

```sql
-- 1. Get user ID
SELECT id FROM auth.users 
WHERE email = 'goodwin.rama@gmail.com';

-- 2. Insert profile (ganti USER_ID dengan hasil query di atas)
INSERT INTO profiles (id, email, username, full_name, role, created_at, updated_at)
VALUES (
  'USER_ID_HERE',  -- Ganti dengan user ID dari query di atas
  'goodwin.rama@gmail.com',
  'rama',
  'Rama',
  'user',
  NOW(),
  NOW()
);
```

✅ **User sekarang bisa login dengan akun yang sudah ada**

---

### Solution 3: Clean Up SEMUA Orphaned Users

Jika ada banyak user yang tidak punya profile (dari testing berulang kali):

```sql
-- Preview dulu siapa yang akan dihapus
SELECT 
  au.id,
  au.email,
  au.created_at
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Jika sudah yakin, hapus semuanya
DELETE FROM auth.users
WHERE id IN (
  SELECT au.id
  FROM auth.users au
  LEFT JOIN profiles p ON au.id = p.id
  WHERE p.id IS NULL
);
```

⚠️ **WARNING**: Ini akan menghapus SEMUA user yang tidak punya profile!

---

## Prevention: Install Auto-Create Profile Trigger

Untuk mencegah masalah ini di masa depan, install trigger yang otomatis membuat profile saat user signup:

```sql
-- Create function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    'user',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

✅ **Sekarang setiap kali user signup, profile akan otomatis dibuat**

---

## Quick Fix Summary

**Untuk kasus Anda (goodwin.rama@gmail.com)**:

1. Buka Supabase SQL Editor
2. Run:
   ```sql
   DELETE FROM auth.users WHERE email = 'goodwin.rama@gmail.com';
   ```
3. Coba signup lagi di app
4. Seharusnya berhasil ✅

---

## Alternative: Delete via Supabase Dashboard

Jika tidak mau pakai SQL:

1. Buka **Supabase Dashboard**
2. Go to **Authentication** → **Users**
3. Cari user `goodwin.rama@gmail.com`
4. Klik tanda **⋮** (three dots)
5. Pilih **Delete user**
6. Confirm

✅ **User sudah terhapus, bisa signup lagi**

---

## Verification

Setelah fix, verify bahwa semuanya sync:

```sql
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM profiles) as total_profiles,
  (SELECT COUNT(*) 
   FROM auth.users au 
   LEFT JOIN profiles p ON au.id = p.id 
   WHERE p.id IS NULL) as orphaned_users
;
```

**Expected result**:
```
total_auth_users | total_profiles | orphaned_users
-----------------|----------------|---------------
       1         |       1        |       0
```

---

## Related Files

- SQL Scripts: [FIX_USER_ALREADY_REGISTERED.sql](./FIX_USER_ALREADY_REGISTERED.sql)
- Signup Logic: [lib/screens/sign_up_screen.dart](../lib/screens/sign_up_screen.dart)
- Auth Service: [lib/services/supabase_service.dart](../lib/services/supabase_service.dart)

---

## Notes

- Error "User already registered" adalah **behavior yang correct** dari Supabase
- Yang perlu diperbaiki adalah **sinkronisasi** antara auth.users dan profiles
- Install trigger untuk **prevention** agar tidak terjadi lagi di production
