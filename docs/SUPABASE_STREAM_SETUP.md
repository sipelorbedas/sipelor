# Setup Supabase Stream untuk Reviews

## 1. Jalankan SQL Commands di Supabase SQL Editor

### A. Set REPLICA IDENTITY FULL (WAJIB untuk Stream)
```sql
-- Ini WAJIB untuk membuat Stream berfungsi dengan baik
ALTER TABLE reviews REPLICA IDENTITY FULL;
```

**Penjelasan**: Tanpa ini, Supabase stream tidak akan mengirim update real-time dengan benar.

### B. Hapus dan Buat Ulang Policy SELECT (Untuk Testing)
```sql
-- Hapus policy lama
DROP POLICY IF EXISTS "Allow_Read_Reviews" ON reviews;

-- Buat policy baru yang mengizinkan SEMUA orang membaca reviews
-- (untuk testing - nanti bisa diperkuat lagi)
CREATE POLICY "Allow_Read_Reviews" 
ON reviews 
FOR SELECT 
USING (true);
```

**Penjelasan**: Policy yang terlalu ketat bisa memblokir stream. Ini versi paling longgar untuk testing.

### C. Cek Policy INSERT (Pastikan User Bisa Menulis Review)
```sql
-- Lihat policy INSERT yang ada
SELECT * FROM pg_policies WHERE tablename = 'reviews' AND cmd = 'INSERT';

-- Jika tidak ada, buat policy INSERT
CREATE POLICY "Allow_Insert_Reviews" 
ON reviews 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);
```

## 2. Cek Data di Table Editor

Buka Table Editor di Supabase Dashboard:

1. **Cek tabel `reviews`**:
   - Apakah ada data review dari User A?
   - Catat `id`, `booking_id`, `venue_id` (jika ada kolom ini)
   
2. **Cek tabel `bookings`**:
   - Apakah ada booking dengan `venue_id` yang sama?
   - Catat `id` dan `venue_id`
   - **PENTING**: Cek tipe data `venue_id` - apakah UUID (text) atau Integer?

3. **Cross-check**:
   - Apakah `booking_id` di `reviews` cocok dengan `id` di `bookings`?
   - Apakah `venue_id` di `bookings` cocok dengan venue yang sedang dilihat?

## 3. Debug Mode di Flutter

### A. Aktivkan Debug Mode (Lihat SEMUA Review)

Di file `lib/screens/venue_detail_screen.dart`, ubah baris ini:

```dart
// SEBELUM (Normal Mode - dengan filter)
const bool debugMode = false;

// SESUDAH (Debug Mode - tanpa filter)
const bool debugMode = true;
```

**Apa yang terjadi?**
- Debug Mode akan menampilkan SEMUA review tanpa filter `venue_id`
- Jika data muncul di Debug Mode, berarti masalahnya ada di filter `.eq()`
- Jika data TIDAK muncul di Debug Mode, berarti masalahnya di:
  - Policy Supabase (cek step 1B)
  - REPLICA IDENTITY (cek step 1A)
  - Data belum ada di database

### B. Lihat Log Console

Saat app berjalan, perhatikan log di console:

```
🔍 [StreamReviewsByVenueId] ===== START STREAM =====
📡 [StreamReviewsByVenueId] Received X total reviews from database
📋 [StreamReviewsByVenueId] Filtered to Y reviews for venue
🎨 [VenueDetail] StreamBuilder state: active
🎨 [VenueDetail] Data received: Y reviews
```

**Yang harus dicek:**
- Apakah `Received X total reviews` menunjukkan ada data?
- Apakah `Filtered to Y reviews` = 0? (berarti filter gagal)
- Apakah `StreamBuilder state: active`? (berarti stream berjalan)

## 4. Troubleshooting Checklist

### ❌ Problem: Stream tidak menerima data sama sekali
**Solusi:**
1. ✅ Jalankan `ALTER TABLE reviews REPLICA IDENTITY FULL;`
2. ✅ Cek Policy SELECT di Supabase (harus allow `true`)
3. ✅ Pastikan ada data di tabel `reviews` (cek Table Editor)

### ❌ Problem: Data muncul di Debug Mode, tapi tidak di Normal Mode
**Solusi:**
1. ✅ Cek tipe data `venue_id` di database (UUID atau Integer?)
2. ✅ Pastikan `venue_id` di Flutter adalah String jika database UUID
3. ✅ Cek apakah `booking_id` di `reviews` cocok dengan `id` di `bookings`
4. ✅ Cek apakah `venue_id` di `bookings` cocok dengan venue yang ditampilkan

### ❌ Problem: User A post review tapi User B tidak lihat
**Solusi:**
1. ✅ Cek di Table Editor: Apakah review User A benar-benar masuk?
2. ✅ Jika YA tapi User B tidak lihat: Masalah di Policy SELECT atau filter
3. ✅ Jika TIDAK: Masalah di Policy INSERT atau kode create review

### ❌ Problem: StreamBuilder stuck di "waiting" state
**Solusi:**
1. ✅ Restart app
2. ✅ Cek koneksi internet
3. ✅ Cek Supabase API status
4. ✅ Pastikan `primaryKey: ['id']` sesuai dengan primary key tabel

## 5. Verifikasi Tipe Data venue_id

### Cek di SQL Editor:
```sql
-- Cek tipe data kolom venue_id di tabel bookings
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'bookings' AND column_name = 'venue_id';

-- Cek tipe data kolom venue_id di tabel fields
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'fields' AND column_name = 'venue_id';
```

**Hasil yang diharapkan:**
- Jika `data_type = 'uuid'` atau `udt_name = 'uuid'` → venue_id adalah UUID (String di Flutter)
- Jika `data_type = 'integer'` → venue_id adalah Integer (harus diubah di Flutter)

## 6. Testing Flow

1. **Test Basic Stream (No Filter)**
   ```dart
   const bool debugMode = true; // Set ini
   ```
   - Jalankan app
   - Buka halaman venue detail
   - Lihat console log
   - **Expected**: Semua review muncul

2. **Test Filtered Stream**
   ```dart
   const bool debugMode = false; // Set ini
   ```
   - Jalankan app
   - Buka halaman venue detail
   - Lihat console log
   - **Expected**: Hanya review dari venue ini yang muncul

3. **Test Real-time Update**
   - Buka app di 2 device/emulator
   - Device A: Buat review baru
   - Device B: Lihat apakah review langsung muncul tanpa refresh
   - **Expected**: Review muncul otomatis di Device B

## 7. SQL untuk Debugging

```sql
-- Lihat semua reviews dengan info booking dan venue
SELECT 
  r.id as review_id,
  r.rating,
  r.comment,
  r.booking_id,
  b.venue_id,
  b.booking_id as booking_code,
  r.created_at
FROM reviews r
LEFT JOIN bookings b ON r.booking_id = b.id
ORDER BY r.created_at DESC
LIMIT 10;

-- Hitung jumlah review per venue
SELECT 
  b.venue_id,
  COUNT(r.id) as total_reviews
FROM reviews r
JOIN bookings b ON r.booking_id = b.id
GROUP BY b.venue_id;

-- Lihat semua bookings untuk venue tertentu
-- (ganti 'YOUR_VENUE_ID' dengan venue_id yang sedang dites)
SELECT id, booking_id, venue_id, user_id, status
FROM bookings
WHERE venue_id = 'YOUR_VENUE_ID'
ORDER BY created_at DESC;
```

## 8. Kembalikan ke Production Mode

Setelah testing selesai:

1. **Matikan Debug Mode**:
   ```dart
   const bool debugMode = false; // Kembali ke false
   ```

2. **Perketat Policy** (opsional):
   ```sql
   DROP POLICY IF EXISTS "Allow_Read_Reviews" ON reviews;
   
   -- Policy yang lebih aman: hanya authenticated users
   CREATE POLICY "Allow_Read_Reviews" 
   ON reviews 
   FOR SELECT 
   TO authenticated
   USING (true);
   ```

## Kontak

Jika masih ada masalah, cek log lengkap dan share:
1. Log dari console Flutter
2. Screenshot Table Editor (reviews & bookings)
3. Hasil query SQL di step 7
