# Debug Admin Dashboard - Booking Tidak Muncul

## Masalah
Booking terbaru tidak muncul di admin dashboard setelah user melakukan konfirmasi pembayaran.

## Solusi yang Telah Diimplementasikan

### 1. Optimisasi Query Performance
- ✅ Menghilangkan N+1 query problem
- ✅ Fetch semua payment proofs dalam 1 query
- ✅ Menggunakan Set lookup untuk filtering

### 2. Debouncing Real-time Updates
- ✅ Menambahkan debounce 500ms
- ✅ Mencegah multiple simultaneous refresh

### 3. Enhanced Logging
- ✅ Detailed logging di setiap tahap
- ✅ Error tracking yang lebih baik
- ✅ Debug button untuk manual check

## Cara Debug

### Step 1: Check Console Logs

Jalankan aplikasi dan perhatikan console logs. Cari logs berikut:

```
✅ [Realtime] ✓ Bookings subscription ACTIVE and LISTENING
✅ [Realtime] ✓ Payment proofs subscription ACTIVE and LISTENING
```

Jika tidak muncul, berarti real-time subscription gagal.

### Step 2: Upload Payment Proof

Ketika user upload payment proof, perhatikan logs:

```
📡 [Realtime] PAYMENT PROOFS TABLE CHANGED
📡 [Realtime] Event Type: INSERT
📡 [Realtime] Booking ID: <uuid>
⏱️  [Realtime] Debounce timer set (500ms)
🔄 [Realtime] DEBOUNCED REFRESH EXECUTING
```

### Step 3: Check Fetch Results

Setelah refresh, perhatikan logs:

```
📝 [FetchAllBookings] Fetching bookings with payment proofs
✅ [FetchAllBookings] Fetched X payment proofs
📝 [FetchAllBookings] Y unique bookings have payment proofs
✅ [FetchAllBookings] Successfully fetched Z bookings
```

### Step 4: Gunakan Debug Button

Di admin dashboard (mode debug), klik icon 🐛 (bug report) untuk check database secara langsung:

```
📊 [DEBUG] Total bookings in database: X
📊 [DEBUG] Total payment proofs: Y
```

## Kemungkinan Masalah

### 1. RLS (Row Level Security) Policy Issue

**Gejala:**
```
❌ [FetchAllBookings] Error fetching payment proofs: ...
⚠️  [FetchAllBookings] This might be an RLS policy issue
```

**Solusi:**
Pastikan admin role memiliki SELECT permission pada:
- `bookings` table
- `payment_proofs` table

SQL untuk check RLS policy:
```sql
-- Check payment_proofs policies
SELECT * FROM pg_policies WHERE tablename = 'payment_proofs';

-- Check bookings policies
SELECT * FROM pg_policies WHERE tablename = 'bookings';
```

### 2. Real-time Subscription Tidak Aktif

**Gejala:**
- Red indicator (🔴) pada dashboard
- Logs menunjukkan: `❌ [Realtime] ✗ ... subscription CLOSED`

**Solusi:**
1. Check Supabase project settings → API → Realtime enabled
2. Restart aplikasi
3. Check network connection

### 3. Payment Proof Tidak Tersimpan

**Gejala:**
```
📝 [FetchAllBookings] 0 unique bookings have payment proofs
```

**Solusi:**
Check upload payment proof flow:
1. File berhasil upload ke storage?
2. Record tersimpan di `payment_proofs` table?
3. `bookings.payment_status` update ke 'pending'?

### 4. Booking Status Filter

**Gejala:**
Booking ada di database tapi tidak muncul di list.

**Check:**
- Apakah booking memiliki payment proof?
- Status payment proof: pending/verified/rejected?
- Apakah ada filter yang aktif?

## SQL Queries untuk Manual Check

```sql
-- Check total bookings
SELECT COUNT(*) FROM bookings;

-- Check total payment proofs
SELECT COUNT(*) FROM payment_proofs;

-- Check bookings dengan payment proofs
SELECT 
  b.booking_id,
  b.status,
  b.payment_status,
  b.created_at,
  pp.id as proof_id,
  pp.status as proof_status,
  pp.created_at as proof_created_at
FROM bookings b
LEFT JOIN payment_proofs pp ON b.id = pp.booking_id
ORDER BY b.created_at DESC
LIMIT 10;

-- Check bookings tanpa payment proofs
SELECT 
  booking_id,
  status,
  payment_status,
  created_at
FROM bookings
WHERE id NOT IN (SELECT booking_id FROM payment_proofs)
ORDER BY created_at DESC;
```

## Recommended RLS Policies

### Payment Proofs Table

```sql
-- Admin can see all payment proofs
CREATE POLICY "Admins can view all payment proofs"
ON payment_proofs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'superadmin')
  )
);
```

### Bookings Table

```sql
-- Admin can see all bookings
CREATE POLICY "Admins can view all bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'superadmin')
  )
);
```

## Checklist Troubleshooting

- [ ] Real-time subscription aktif (green indicator)
- [ ] Console logs menunjukkan subscription listening
- [ ] Debug button menunjukkan data exists di database
- [ ] RLS policies configured untuk admin role
- [ ] Payment proof berhasil upload
- [ ] Booking payment_status = 'pending'
- [ ] Network connection stable
- [ ] No error logs di console

## Contact Support

Jika masalah masih berlanjut setelah mengikuti panduan ini, sertakan:
1. Screenshot console logs
2. Screenshot debug button results
3. SQL query results dari manual check
4. Supabase RLS policy configuration
