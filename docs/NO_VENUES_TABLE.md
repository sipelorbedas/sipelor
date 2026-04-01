# Tidak Ada Tabel Venues

## Penjelasan

Aplikasi ini **tidak menggunakan tabel venues terpisah**. Semua data venue diambil dari tabel `fields`.

## Struktur Data

### Tabel `fields` berisi:
- `id` - UUID field
- `venue_name` - Nama venue (misal: "STADION JALAK HARUPAT")
- `venue_type` - Tipe venue (misal: "Liga 1", "Liga 2", dll)
- `area` - Area lapangan (misal: "Jalak Harupat")
- `description` - Deskripsi lapangan
- `image_urls` - Array gambar lapangan
- `price_per_hour` - Harga per jam
- `status` - Status lapangan (available, booked, maintenance)
- `venue_id` - **Nullable** - ID venue (untuk foreign key di bookings)
- Dan field lainnya...

## Fungsi yang Dimodifikasi

### 1. `fetchVenues()`
**Sebelum:** Query ke `venues` table
```dart
final response = await _client.from('venues').select();
```

**Sekarang:** Query ke `fields` table dan group by venue
```dart
final response = await _client.from('fields').select();
// Lalu di-group berdasarkan venue_name + venue_type
```

### 2. `fetchVenueById()`
**Sebelum:** Query ke `venues` table by ID
```dart
final response = await _client.from('venues').select().eq('id', venueId).single();
```

**Sekarang:** Query ke `fields` table (venueId = fieldId)
```dart
final response = await _client.from('fields').select().eq('id', venueId).single();
```

### 3. `_updateVenueRating()`
**Sebelum:** Update rating di `venues` table
```dart
await _client.from('venues').update({'rating': averageRating});
```

**Sekarang:** Skip update (no-op), hanya logging
```dart
print('Skipping venue rating update (no venues table)');
```

### 4. `createBooking()`
**Sebelum:** Validasi venue_id harus ada di `venues` table
```dart
final venueCheck = await _client.from('venues').select().eq('id', venueId).single();
if (venueCheck == null) throw Exception('Venue not found');
```

**Sekarang:** Skip validasi, venue_id bisa null
```dart
final actualVenueId = fieldData['venue_id'] as String? ?? venueId;
// No validation needed
```

## Implikasi

### ✅ Kelebihan:
- Tidak perlu maintain 2 tabel terpisah
- Data venue selalu konsisten dengan fields
- Lebih sederhana untuk setup database

### ⚠️ Keterbatasan:
- Rating venue tidak ter-persist di database (hitung on-demand)
- Satu venue bisa muncul berkali-kali jika punya banyak field dengan tipe berbeda
- Tidak ada satu tempat terpusat untuk data venue

## Rekomendasi ke Depan

Jika ingin menambahkan tabel `venues` di kemudian hari:
1. Buat tabel `venues` dengan kolom: id, name, type, address, city, rating, total_reviews
2. Migrate data unik dari `fields` ke `venues`
3. Update `fields.venue_id` untuk menunjuk ke `venues.id` yang sesuai
4. Restore fungsi-fungsi yang dimodifikasi ke versi original
5. Enable foreign key constraint: `bookings.venue_id` → `venues.id`

## Testing

Setelah perubahan ini:
1. ✅ Home screen bisa load venue list dari fields
2. ✅ Venue detail bisa ditampilkan
3. ✅ Booking bisa dibuat (venue_id nullable/field ID)
4. ✅ Review bisa dibuat (rating tidak ter-persist di venue)
5. ✅ Admin field management bisa load venues

## Catatan Penting

**venue_id di tabel bookings dan fields bisa NULL!**

Jika `venue_id` NULL, aplikasi akan menggunakan `field.id` sebagai fallback untuk:
- Identifier venue di booking
- Reference di review
- Display purposes

Ini aman karena tidak ada foreign key constraint ke tabel venues yang tidak ada.
