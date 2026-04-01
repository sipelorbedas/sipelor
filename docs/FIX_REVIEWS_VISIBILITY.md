# Fix Reviews Visibility Issue

## Problem
Reviews pada venue card di Home Screen dan detail venue tidak terlihat oleh user lain. Reviews hanya bisa dilihat oleh user yang membuat booking dan memberikan review tersebut.

## Root Cause
Masalah terjadi karena Row Level Security (RLS) policy pada tabel `reviews` di Supabase yang membatasi operasi SELECT hanya untuk user yang membuat review (WHERE `user_id = auth.uid()`).

## Solution
Mengubah RLS policy pada tabel `reviews` untuk:
- ✅ **SELECT (READ)**: Semua authenticated users dapat membaca semua reviews
- ✅ **INSERT**: User hanya bisa membuat review untuk booking mereka sendiri yang sudah completed
- ✅ **UPDATE**: User hanya bisa mengupdate review mereka sendiri
- ✅ **DELETE**: User hanya bisa menghapus review mereka sendiri

## Implementation Steps

### 1. Buka Supabase Dashboard
1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Pilih project Anda
3. Buka **SQL Editor** dari sidebar kiri

### 2. Jalankan SQL Script
1. Copy seluruh isi file `supabase_fix_reviews_rls_policy.sql`
2. Paste ke SQL Editor
3. Klik **Run** atau tekan `Ctrl+Enter`

### 3. Verify Changes
Setelah menjalankan script, verify bahwa policies sudah benar dengan query berikut:

```sql
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'reviews'
ORDER BY cmd, policyname;
```

Expected output:
- `All authenticated users can read reviews` (SELECT)
- `Admin can read all reviews` (SELECT)
- `Users can insert reviews for own bookings` (INSERT)
- `Users can update own reviews` (UPDATE)
- `Users can delete own reviews` (DELETE)

### 4. Test di App
1. Login sebagai User A
2. Buat booking dan complete-kan booking tersebut
3. Berikan review untuk venue
4. Logout dan login sebagai User B
5. Buka Home Screen atau Venue Detail untuk venue yang sama
6. ✅ Review dari User A sekarang harus terlihat oleh User B

## Technical Details

### Before Fix
```sql
-- Old policy (example):
CREATE POLICY "Users can read own reviews"
ON reviews FOR SELECT
USING (auth.uid() = user_id);  -- ❌ Hanya bisa baca review sendiri
```

### After Fix
```sql
-- New policy:
CREATE POLICY "All authenticated users can read reviews"
ON reviews FOR SELECT
TO authenticated
USING (true);  -- ✅ Semua authenticated users bisa baca semua review
```

## Code Impact
Tidak ada perubahan code di Flutter app karena code sudah benar. Methods berikut sudah fetch semua reviews dengan benar:
- `SupabaseService.fetchReviewsByVenueId()` ✅
- `SupabaseService.fetchReviewsByVenueName()` ✅
- `SupabaseService.fetchAllReviewsWithBookings()` ✅

Masalah hanya di database RLS policy level.

## Security Considerations
✅ **Safe**: Reviews adalah data public yang memang seharusnya bisa dibaca semua user
✅ **Secure**: Write operations (INSERT, UPDATE, DELETE) tetap protected
✅ **Validated**: INSERT policy memvalidasi bahwa user hanya bisa review booking mereka sendiri yang sudah completed

## Related Files
- SQL Script: `/supabase_fix_reviews_rls_policy.sql`
- Flutter Code:
  - `/lib/services/supabase_service.dart` (methods: `fetchReviewsByVenueId`, `fetchReviewsByVenueName`)
  - `/lib/screens/home_screen.dart` (venue cards with reviews)
  - `/lib/screens/venue_detail_screen.dart` (venue detail with reviews)
  - `/lib/screens/venue_list_screen.dart` (venue list with reviews)

## Rollback (if needed)
Jika ada masalah setelah apply fix ini, Anda bisa disable RLS sementara:

```sql
-- Temporary disable RLS (for testing only!)
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS when ready
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
```

⚠️ **Warning**: Jangan disable RLS di production untuk waktu yang lama!

## FAQ

**Q: Apakah semua user bisa edit/delete review orang lain?**
A: ❌ Tidak. UPDATE dan DELETE policies tetap dibatasi hanya untuk review owner.

**Q: Apakah user bisa membuat review untuk booking orang lain?**
A: ❌ Tidak. INSERT policy memvalidasi bahwa user hanya bisa review booking mereka sendiri.

**Q: Apakah user bisa review booking yang belum completed?**
A: ❌ Tidak. INSERT policy memvalidasi bahwa booking harus berstatus 'completed'.

**Q: Apakah admin bisa baca semua review?**
A: ✅ Ya. Ada policy khusus untuk admin role.

## Testing Checklist
- [ ] Reviews terlihat di Home Screen venue cards untuk semua user
- [ ] Reviews terlihat di Venue Detail screen untuk semua user
- [ ] Reviews terlihat di Venue List screen untuk semua user
- [ ] User bisa membuat review untuk booking mereka sendiri yang completed
- [ ] User TIDAK bisa membuat review untuk booking orang lain
- [ ] User TIDAK bisa membuat review untuk booking yang belum completed
- [ ] User bisa update/delete review mereka sendiri
- [ ] User TIDAK bisa update/delete review orang lain
- [ ] Admin bisa melihat semua reviews di Admin Dashboard

## Status
⏳ **Waiting for implementation**: SQL script perlu dijalankan di Supabase Dashboard

## Contact
Jika ada pertanyaan atau masalah setelah apply fix ini, hubungi developer.
