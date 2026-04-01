# Cara Memperbaiki Database - NULL venue_id

## Masalah
Semua record di tabel `fields` memiliki `venue_id = NULL`, sehingga booking gagal dengan error:
```
insert or update on table "bookings" violates foreign key constraint "bookings_venue_id_fkey"
```

## Solusi

### Langkah 1: Buka Supabase SQL Editor
1. Login ke [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project Anda
3. Klik **SQL Editor** di menu kiri
4. Klik tombol **New Query**

### Langkah 2: Cek Apakah Venue Sudah Ada
Jalankan query ini untuk melihat venue yang sudah ada:

```sql
SELECT id, name, type, address, description 
FROM venues 
WHERE LOWER(name) LIKE '%jalak harupat%';
```

### Langkah 3A: Jika Venue Belum Ada (Hasil Query Kosong)

Buat venue baru:

```sql
INSERT INTO venues (
  name,
  type,
  address,
  description,
  created_at,
  updated_at
) VALUES (
  'STADION JALAK HARUPAT',
  'Stadion',
  'Jalak Harupat, Kabupaten Bandung',
  'Stadion olahraga untuk berbagai pertandingan liga',
  NOW(),
  NOW()
)
RETURNING id, name;
```

**PENTING:** Catat `id` yang dikembalikan dari query ini!

Lalu update semua fields dengan venue_id tersebut:

```sql
-- Ganti <venue_id_dari_langkah_sebelumnya> dengan ID yang baru dibuat
UPDATE fields 
SET 
  venue_id = '<venue_id_dari_langkah_sebelumnya>',
  updated_at = NOW()
WHERE venue_name = 'STADION JALAK HARUPAT'
  AND venue_id IS NULL;
```

### Langkah 3B: Jika Venue Sudah Ada

Cari semua venue yang ada:

```sql
SELECT id, name, type FROM venues ORDER BY name;
```

Update fields dengan venue_id yang sesuai:

```sql
-- Ganti <venue_id_yang_sesuai> dengan ID venue yang benar
UPDATE fields 
SET 
  venue_id = '<venue_id_yang_sesuai>',
  updated_at = NOW()
WHERE venue_name = 'STADION JALAK HARUPAT'
  AND venue_id IS NULL;
```

### Langkah 4: Verifikasi Perbaikan

Cek apakah semua fields sudah punya venue_id:

```sql
SELECT 
  f.id,
  f.area,
  f.venue_name,
  f.venue_id,
  v.name as actual_venue_name
FROM fields f
LEFT JOIN venues v ON f.venue_id = v.id
WHERE f.venue_name = 'STADION JALAK HARUPAT';
```

Semua baris seharusnya menampilkan `venue_id` dan `actual_venue_name` yang tidak NULL.

### Langkah 5: Cek Field Lain yang Masih NULL

```sql
SELECT 
  id,
  area,
  venue_name,
  venue_id
FROM fields
WHERE venue_id IS NULL;
```

Jika masih ada yang NULL, ulangi langkah 3 untuk venue tersebut.

## Verifikasi Final

Setelah selesai, jalankan query ini untuk memastikan semua OK:

```sql
-- Hitung status venue_id
SELECT 
  CASE 
    WHEN venue_id IS NULL THEN 'NULL venue_id (PERLU DIPERBAIKI)'
    ELSE 'Punya venue_id (OK)'
  END as status,
  COUNT(*) as jumlah
FROM fields
GROUP BY 
  CASE 
    WHEN venue_id IS NULL THEN 'NULL venue_id (PERLU DIPERBAIKI)'
    ELSE 'Punya venue_id (OK)'
  END;
```

Hasil yang diharapkan:
```
status                          | jumlah
-------------------------------|-------
Punya venue_id (OK)           | 5
```

## Setelah Perbaikan Database

Setelah database diperbaiki:
1. Restart aplikasi Flutter Anda
2. Coba melakukan booking lagi
3. Booking seharusnya berhasil tanpa error

## Catatan Penting

- **Jangan hapus venue** yang sudah digunakan oleh fields
- **Backup database** sebelum melakukan perubahan besar
- Jika ada field dengan venue yang berbeda, buat venue terpisah untuk masing-masing
- Field `venue_name` di tabel `fields` hanya untuk display, yang penting adalah `venue_id` harus valid

## Troubleshooting

### Error: "duplicate key value violates unique constraint"
Venue dengan nama tersebut sudah ada. Gunakan Langkah 3B.

### Error: "permission denied"
User Anda tidak punya akses untuk mengubah data. Login sebagai admin atau minta bantuan DBA.

### Booking masih error setelah fix
1. Cek kembali bahwa venue_id sudah terisi
2. Pastikan venue_id yang diisi benar-benar ada di tabel venues
3. Restart aplikasi Flutter
4. Bersihkan cache browser (jika web) atau reinstall app (jika mobile)
