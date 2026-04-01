# Troubleshooting: Reviews Tidak Terlihat Oleh Semua User

## Problem
Reviews pada venue card dan detail venue tidak terlihat oleh user lain. Reviews hanya bisa dilihat oleh user yang membuat review tersebut.

## Quick Diagnosis

### Test 1: Cek di Supabase Dashboard
1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Buka **Table Editor** → pilih table `reviews`
3. Apakah Anda bisa melihat reviews yang dibuat oleh user lain?
   - ✅ **Ya**: Berarti data ada, masalah di RLS policy
   - ❌ **Tidak**: Berarti masalah di data atau permissions

### Test 2: Cek RLS Status
1. Buka **SQL Editor** di Supabase
2. Run query ini:
```sql
SELECT tablename, rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'reviews';
```
3. Hasil:
   - `rls_enabled = true`: RLS aktif (perlu check policies)
   - `rls_enabled = false`: RLS mati (bukan best practice, tapi reviews akan terlihat semua)

### Test 3: Cek Current Policies
Run di SQL Editor:
```sql
SELECT policyname, cmd, pg_get_expr(qual, 'reviews'::regclass) as using_clause
FROM pg_policies
WHERE tablename = 'reviews';
```

Cari policy untuk SELECT yang restrictive, contoh:
- ❌ BAD: `auth.uid() = user_id` (hanya bisa baca review sendiri)
- ✅ GOOD: `true` (semua user bisa baca)

## Solution Methods

### Method 1: Automatic Fix (RECOMMENDED) ⭐
1. Buka **Supabase SQL Editor**
2. Copy seluruh isi file **`supabase_fix_reviews_final.sql`** ⭐
3. Paste dan run
4. Script akan:
   - Check status RLS dan policies
   - Drop semua policies lama
   - Create policies baru yang benar (dengan proper type casting)
   - Verify hasilnya

**Important**: Gunakan `supabase_fix_reviews_final.sql` yang sudah fix type casting issues.

### Method 2: Manual Fix
Jika Method 1 gagal, coba manual:

```sql
-- 1. Drop policy yang bermasalah
DROP POLICY IF EXISTS "Users can read own reviews" ON reviews;
DROP POLICY IF EXISTS "Enable read access for all users" ON reviews;

-- 2. Create policy baru
CREATE POLICY "reviews_select_all"
ON reviews FOR SELECT
TO authenticated
USING (true);

-- 3. Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
```

### Method 3: Temporary Disable RLS (TESTING ONLY)
⚠️ **WARNING**: Hanya untuk testing, jangan di production!

```sql
-- Disable RLS untuk test
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- Test app sekarang - jika reviews terlihat, confirm masalah di RLS

-- Enable kembali setelah testing
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
```

## Verification Steps

### 1. Check di Supabase
```sql
-- Should return all reviews
SELECT id, user_id, rating, comment, created_at 
FROM reviews 
ORDER BY created_at DESC 
LIMIT 10;
```

### 2. Check di Flutter App
1. Login sebagai User A
2. Buat booking dan complete, lalu beri review
3. Logout
4. Login sebagai User B
5. Buka venue yang sama
6. ✅ Review dari User A harus terlihat

### 3. Check Logs
Di Flutter app, check debug console untuk log:
```
📝 [FetchReviewsByVenueId] Fetched X reviews for venue ...
```

Jika X = 0 tapi ada reviews di database, masalah di RLS.

## Common Issues & Solutions

### Issue 1: "Permission denied for table reviews"
**Cause**: RLS policy terlalu ketat
**Solution**: Gunakan Method 1 atau 2 di atas

### Issue 2: Reviews terlihat di Supabase tapi tidak di app
**Cause**: 
- RLS policy membatasi SELECT
- atau Supabase client di app tidak authenticated

**Solution**: 
1. Check user login status di app
2. Run Method 1 untuk fix policies
3. Restart Flutter app

### Issue 3: Reviews masih tidak terlihat setelah fix
**Cause**: Cache atau stale data
**Solution**:
1. Hot restart Flutter app (bukan hot reload)
2. Clear app data dan reinstall
3. Check network logs untuk error

### Issue 4: Error "Policy violation"
**Cause**: Trying to insert/update/delete review milik user lain
**Solution**: Normal behavior - user hanya boleh edit review sendiri

## Understanding RLS Policies

### What Should Work:
```sql
-- ✅ GOOD: Everyone can read
CREATE POLICY "reviews_select_all"
ON reviews FOR SELECT
USING (true);

-- ✅ GOOD: Only owner can write
CREATE POLICY "reviews_update_own"
ON reviews FOR UPDATE
USING (auth.uid() = user_id);
```

### What Causes Problems:
```sql
-- ❌ BAD: Only owner can read (causes our issue!)
CREATE POLICY "reviews_select_own"
ON reviews FOR SELECT
USING (auth.uid() = user_id);
```

## Files Reference
- **SQL Fix Script (FINAL)**: `/supabase_fix_reviews_final.sql` ⭐⭐ **USE THIS**
- SQL Fix Script (Simple): `/supabase_fix_reviews_simple.sql` (has type casting issues)
- SQL Fix Script (Advanced): `/supabase_check_and_fix_reviews.sql` (has pg_get_expr issues)
- Initial Fix: `/supabase_fix_reviews_rls_policy.sql`
- Documentation: `/docs/FIX_REVIEWS_VISIBILITY.md`

## Technical Background

### Why Reviews Should Be Public
- Reviews adalah social proof untuk venue
- User perlu lihat review orang lain sebelum booking
- Tidak ada data sensitif di reviews
- Standard practice: public read, restricted write

### Security Considerations
✅ **Safe**: All authenticated users dapat read reviews
✅ **Secure**: Write operations tetap restricted ke owner
✅ **Validated**: INSERT policy check booking ownership dan status
❌ **Not Safe**: Membatasi read reviews (tidak ada manfaatnya)

## Contact Developer
Jika masalah persist setelah mengikuti semua steps:
1. Capture screenshot error di debug console
2. Run verification queries dan share output
3. Check apakah ada custom RLS functions di database
4. Pastikan tidak ada middleware yang filter data

## Quick Checklist
- [ ] Run `supabase_check_and_fix_reviews.sql`
- [ ] Verify policies dengan query check
- [ ] Restart Flutter app (hot restart)
- [ ] Test dengan 2 user accounts
- [ ] Check debug logs untuk error
- [ ] Confirm reviews terlihat di Supabase dashboard
- [ ] Clear app cache if needed
