# 🔐 Verifikasi Akses Superadmin

## Checklist untuk Memastikan Superadmin Berfungsi

### ✅ 1. Verifikasi Data di Database

Jalankan query berikut di Supabase SQL Editor untuk memastikan user memiliki role superadmin:

```sql
-- Cek role user di tabel profiles
SELECT id, email, role, created_at, updated_at
FROM profiles
WHERE role = 'superadmin'
ORDER BY created_at DESC;

-- Jika tidak ada hasil, cek semua profiles
SELECT id, email, role
FROM profiles
ORDER BY created_at DESC
LIMIT 10;
```

**Jika user belum memiliki role superadmin**, update dengan:

```sql
-- Ganti 'user_email@example.com' dengan email superadmin yang sebenarnya
UPDATE profiles
SET role = 'superadmin', updated_at = NOW()
WHERE email = 'user_email@example.com';

-- Verifikasi update berhasil
SELECT id, email, role FROM profiles WHERE email = 'user_email@example.com';
```

### ✅ 2. Verifikasi Nilai Role yang Valid

Pastikan kolom `role` di tabel `profiles` hanya berisi salah satu dari:
- `'user'` - User biasa
- `'admin'` - Admin dengan akses terbatas
- `'superadmin'` - Superadmin dengan akses penuh

```sql
-- Cek semua nilai role yang ada di database
SELECT DISTINCT role, COUNT(*) as count
FROM profiles
GROUP BY role
ORDER BY role;
```

### ✅ 3. Test Login dan Navigasi

1. **Logout** dari aplikasi (jika sudah login)
2. **Login** dengan akun yang sudah di-set sebagai superadmin
3. **Perhatikan log** di console/logcat:

```
👤 [AdminDashboardDesktop] User role: superadmin
👤 [AdminDashboardDesktop] Is admin: true
👤 [AdminDashboardDesktop] Is superadmin: true
```

### ✅ 4. Verifikasi Menu Sidebar

Setelah login sebagai superadmin, menu berikut harus muncul:

#### Menu untuk Semua Admin (admin & superadmin):
- ✅ Dashboard
- ✅ Kelola Lapangan
- ✅ Time Slots
- ✅ Review Masukan
- ✅ Chat

#### Menu Khusus Superadmin:
- 🔒 **Analytics & Reports**
- 🔒 **Audit Logs**
- 🔒 **Staff Management**

### ✅ 5. Troubleshooting

#### Problem: User tidak bisa login ke admin dashboard

**Solusi:**
1. Pastikan `role` di database adalah `'superadmin'` (lowercase, tanpa spasi)
2. Clear cache aplikasi dan coba login ulang
3. Cek log untuk melihat error spesifik

#### Problem: Superadmin bisa login tapi menu khusus tidak muncul

**Solusi:**
1. Cek log console untuk memastikan role terdeteksi dengan benar:
   ```
   👤 [AdminDashboardDesktop] User role: superadmin
   ```
2. Jika log menampilkan `User role: user` atau `User role: admin`, berarti ada masalah di database
3. Re-run query UPDATE di Step 1

#### Problem: Error saat fetch role

**Solusi:**
1. Pastikan RLS policies di tabel `profiles` mengizinkan user membaca data mereka sendiri
2. Jalankan query berikut untuk verifikasi policies:

```sql
-- Lihat semua RLS policies di tabel profiles
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Pastikan ada policy yang mengizinkan SELECT untuk authenticated users
```

### ✅ 6. RLS Policy untuk Profiles

Jika ada masalah dengan RLS, pastikan policy berikut ada:

```sql
-- Drop existing policies (hati-hati!)
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;

-- Create policy untuk read own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Create policy untuk read all profiles (untuk admin)
CREATE POLICY "Admins can read all profiles"
ON profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
    AND p.role IN ('admin', 'superadmin')
  )
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT ON profiles TO authenticated;
```

### ✅ 7. Test RPC Function

Jika menggunakan RPC function `get_role_by_user_id`, test dengan:

```sql
-- Test RPC function (ganti dengan user_id yang sebenarnya)
SELECT get_role_by_user_id('your-user-id-here');

-- Seharusnya return: 'superadmin'
```

---

## 📋 Quick Check Commands

```sql
-- 1. Cek user dengan role superadmin
SELECT email, role FROM profiles WHERE role = 'superadmin';

-- 2. Update user menjadi superadmin (ganti email)
UPDATE profiles SET role = 'superadmin' WHERE email = 'admin@example.com';

-- 3. Verifikasi RLS policies
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'profiles';

-- 4. Cek permission
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'profiles' AND grantee = 'authenticated';
```

---

## ✅ Expected Behavior

Setelah semua fix:

1. ✅ User dengan role `'superadmin'` di database bisa login
2. ✅ Setelah login, diarahkan ke admin dashboard
3. ✅ Sidebar menampilkan **8 menu** (termasuk 3 menu khusus superadmin)
4. ✅ Console log menampilkan:
   - `User role: superadmin`
   - `Is admin: true`
   - `Is superadmin: true`
5. ✅ Menu Analytics & Reports, Audit Logs, dan Staff Management bisa diakses

---

## 🐛 Debug Mode

Untuk debugging lebih detail, aktifkan debug mode dengan melihat log:

```bash
# Android
adb logcat | grep -i "AdminDashboard\|AuthGuard\|GetUserRole"

# iOS  
# Lihat di Xcode console

# Flutter
flutter run -d <device> --verbose
```

Look for these key log messages:
- `👤 [AdminDashboardDesktop] User role: superadmin`
- `✅ [AuthGuard] Admin detected`
- `✅ [GetUserRole] Parsed role: superadmin`

---

## 🎉 Success Indicators

Anda tahu superadmin berfungsi dengan benar jika:

1. Badge "Super Administrator" muncul di header/profile
2. Menu sidebar memiliki 8 items (bukan 5)
3. Tidak ada error di console terkait role
4. Semua menu bisa diklik dan berfungsi

---

Jika masih ada masalah, silakan:
1. Screenshot menu sidebar
2. Share log dari console
3. Share hasil query `SELECT email, role FROM profiles WHERE email = 'your-email'`
