# 📋 SOP — SIPELOR BEDAS
## Standar Operasional Prosedur

<div align="center">

```
╔══════════════════════════════════════════════════════════════════════════╗
║         SOP — SIPELOR BEDAS                                              ║
║         Sistem Pemesanan Lapangan Olahraga BEDAS                         ║
║         DISPORA Kabupaten Bandung                                        ║
╚══════════════════════════════════════════════════════════════════════════╝
```

**Nomor Dokumen** : SOP-SIPELOR-2026-001  
**Versi**         : 1.0  
**Tanggal Terbit**: 3 Maret 2026  
**Disusun oleh** : Tim Pengembang SIPELOR BEDAS  
**Disetujui oleh**: Kepala DISPORA Kabupaten Bandung  
**Status**        : 🟢 Berlaku

</div>

---

## 📑 Daftar Isi

1. [Tujuan & Ruang Lingkup](#1-tujuan--ruang-lingkup)
2. [Definisi & Istilah](#2-definisi--istilah)
3. [Peran & Tanggung Jawab](#3-peran--tanggung-jawab)
4. [SOP-01 — Registrasi & Verifikasi Akun](#4-sop-01--registrasi--verifikasi-akun)
5. [SOP-02 — Login & Autentikasi](#5-sop-02--login--autentikasi)
6. [SOP-03 — Pemesanan Lapangan (Booking)](#6-sop-03--pemesanan-lapangan-booking)
7. [SOP-04 — Pembayaran & Konfirmasi](#7-sop-04--pembayaran--konfirmasi)
8. [SOP-05 — Pembatalan Booking](#8-sop-05--pembatalan-booking)
9. [SOP-06 — Verifikasi & Persetujuan Admin](#9-sop-06--verifikasi--persetujuan-admin)
10. [SOP-07 — Booking OPD / Pimpinan Dinas](#10-sop-07--booking-opd--pimpinan-dinas)
11. [SOP-08 — Real-time Chat User–Admin](#11-sop-08--real-time-chat-useradmin)
12. [SOP-09 — Ulasan & Penilaian Lapangan](#12-sop-09--ulasan--penilaian-lapangan)
13. [SOP-10 — Manajemen Lapangan (Admin)](#13-sop-10--manajemen-lapangan-admin)
14. [SOP-11 — Jadwal Pemeliharaan Lapangan](#14-sop-11--jadwal-pemeliharaan-lapangan)
15. [SOP-12 — Manajemen Staff & Hak Akses](#15-sop-12--manajemen-staff--hak-akses)
16. [SOP-13 — Penanganan Insiden Keamanan](#16-sop-13--penanganan-insiden-keamanan)
17. [SOP-14 — Backup & Pemulihan Data](#17-sop-14--backup--pemulihan-data)
18. [SOP-15 — Pelaporan & Analitik](#18-sop-15--pelaporan--analitik)
19. [SOP-16 — Penanganan Keluhan Pengguna](#19-sop-16--penanganan-keluhan-pengguna)
20. [SOP-17 — Deployment & Rilis Aplikasi](#20-sop-17--deployment--rilis-aplikasi)
21. [Lampiran](#21-lampiran)

---

## 1. Tujuan & Ruang Lingkup

### 1.1 Tujuan

Dokumen SOP ini bertujuan untuk:
1. Memberikan panduan baku operasional sistem SIPELOR BEDAS bagi seluruh pemangku kepentingan.
2. Menjamin konsistensi, keamanan, dan kualitas layanan pemesanan lapangan olahraga SOR Jalak Harupat.
3. Meminimalkan kesalahan operasional dan mempercepat penyelesaian masalah.
4. Menjadi acuan pelatihan bagi staf baru DISPORA Kabupaten Bandung.

### 1.2 Ruang Lingkup

SOP ini berlaku untuk:

| Cakupan | Keterangan |
|---|---|
| **Pengguna** | Masyarakat umum yang menggunakan aplikasi mobile SIPELOR BEDAS |
| **Admin** | Admin, Manager, dan Operator DISPORA Kab. Bandung |
| **Super Admin** | Pengelola teknis tertinggi sistem |
| **Platform** | Aplikasi Android, iOS, Web, dan Windows |
| **Lokasi** | SOR Jalak Harupat, Kabupaten Bandung |

### 1.3 Referensi

- Peraturan Daerah tentang Pengelolaan Sarana Olahraga Kabupaten Bandung
- Kebijakan Keamanan Informasi DISPORA Kabupaten Bandung
- Terms of Service & Privacy Policy SIPELOR BEDAS v1.0

---

## 2. Definisi & Istilah

| Istilah | Definisi |
|---|---|
| **SIPELOR BEDAS** | Sistem Pemesanan Lapangan Olahraga BEDAS — aplikasi digital resmi DISPORA Kab. Bandung |
| **SOR** | Sarana Olahraga, merujuk pada SOR Jalak Harupat |
| **Booking** | Pemesanan slot waktu penggunaan lapangan olahraga |
| **Slot** | Satu satuan waktu penggunaan lapangan (misal: 08.00–10.00) |
| **E-Ticket** | Tiket elektronik berformat PDF+QR Code sebagai bukti pemesanan |
| **OPD** | Organisasi Perangkat Daerah — instansi pemerintah yang berhak booking via jalur khusus |
| **RASP** | Runtime Application Self-Protection — lapisan keamanan otomatis di dalam aplikasi |
| **RLS** | Row Level Security — keamanan akses data di level database |
| **RBAC** | Role-Based Access Control — kontrol akses berdasarkan peran pengguna |
| **Supabase** | Platform backend (database, autentikasi, penyimpanan) yang digunakan sistem |
| **QR Code** | Kode dua dimensi pada e-ticket untuk verifikasi kehadiran di lapangan |
| **Rate Limiting** | Pembatasan percobaan login maks. 3 kali sebelum akun dikunci 1 jam |
| **Auto-logout** | Logout otomatis setelah 15 menit tidak aktif |
| **Pending** | Status booking menunggu konfirmasi/pembayaran |
| **Confirmed** | Status booking yang telah diverifikasi dan dikonfirmasi admin |
| **Cancelled** | Status booking yang dibatalkan |
| **Completed** | Status booking yang sudah selesai digunakan |
| **ID Booking** | Format unik: `SJH-YYYYMMDD-XXXX` (misal: SJH-20260303-0001) |

---

## 3. Peran & Tanggung Jawab

### 3.1 Hierarki Peran

```
┌────────────────────────────────────────────┐
│              SUPER ADMIN                   │
│  Akses penuh sistem, konfigurasi, audit    │
├────────────────────────────────────────────┤
│                  ADMIN                     │
│  Kelola booking, verifikasi pembayaran,    │
│  manajemen lapangan, laporan               │
├────────────────────────────────────────────┤
│                 MANAGER                    │
│  Analitik, laporan, pengaturan operasional │
├────────────────────────────────────────────┤
│                OPERATOR                    │
│  Verifikasi e-ticket, chat, data entry     │
├────────────────────────────────────────────┤
│                  USER                      │
│  Browse, booking, pembayaran, ulasan       │
└────────────────────────────────────────────┘
```

### 3.2 Matriks Tanggung Jawab (RACI)

| Proses | User | Operator | Admin | Manager | Super Admin |
|---|:---:|:---:|:---:|:---:|:---:|
| Registrasi akun | **R** | — | I | — | — |
| Booking lapangan | **R** | I | C | — | — |
| Upload bukti pembayaran | **R** | — | — | — | — |
| Verifikasi pembayaran | — | C | **R** | I | — |
| Konfirmasi booking | — | — | **R** | I | — |
| Pembatalan booking | **R** / C | — | **R** | — | — |
| Manajemen lapangan | — | — | **R** | C | A |
| Jadwal maintenance | — | C | **R** | A | — |
| Manajemen staff | — | — | C | **R** | A |
| Laporan & analitik | — | — | C | **R** | A |
| Insiden keamanan | I | I | C | C | **R** |
| Deployment aplikasi | — | — | — | C | **R** |
| Moderasi konten | — | C | **R** | A | — |

> **R** = Responsible (pelaksana) · **A** = Accountable (penanggung jawab) · **C** = Consulted · **I** = Informed

---

## 4. SOP-01 — Registrasi & Verifikasi Akun

**Nomor SOP** : SOP-01  
**Judul**     : Registrasi dan Verifikasi Akun Pengguna  
**Pelaksana** : Pengguna (User)  
**Waktu**     : ±5 menit  

### 4.1 Tujuan
Memastikan setiap pengguna terdaftar secara sah dengan identitas yang terverifikasi melalui email.

### 4.2 Prasyarat
- Perangkat dengan koneksi internet aktif
- Alamat email yang valid dan dapat diakses
- Aplikasi SIPELOR BEDAS telah terinstall

### 4.3 Langkah-langkah

| # | Langkah | Pelaksana | Keterangan |
|---|---|---|---|
| 1 | Buka aplikasi SIPELOR BEDAS | User | Muncul layar onboarding (pertama kali) |
| 2 | Tap **"Daftar"** / **"Buat Akun"** | User | — |
| 3 | Isi formulir: Nama Lengkap, Email, Password | User | Password min. 8 karakter, kombinasi huruf besar, kecil, angka, simbol |
| 4 | Baca & centang persetujuan **Terms of Service** dan **Privacy Policy** | User | Wajib disetujui, tidak bisa lanjut jika belum dicentang |
| 5 | Tap **"Daftar"** | User | Sistem kirim email verifikasi otomatis |
| 6 | Buka email, klik link verifikasi | User | Link berlaku 24 jam |
| 7 | Aplikasi redirect ke halaman sukses verifikasi | Sistem | Akun aktif, user dapat login |

### 4.4 Ketentuan Password
```
✅ Minimal 8 karakter
✅ Minimal 1 huruf besar (A–Z)
✅ Minimal 1 huruf kecil (a–z)
✅ Minimal 1 angka (0–9)
✅ Minimal 1 karakter khusus (!@#$%^&*)
❌ Tidak boleh sama dengan email
❌ Tidak boleh password umum (password, 12345678, dll.)
```

### 4.5 Penanganan Error

| Kondisi Error | Pesan | Tindakan |
|---|---|---|
| Email sudah terdaftar | "Email sudah digunakan" | Gunakan fitur "Lupa Password" |
| Link verifikasi kadaluarsa | "Link tidak valid" | Minta kirim ulang dari halaman login |
| Password tidak memenuhi syarat | "Password terlalu lemah" | Perkuat password sesuai ketentuan |
| Koneksi internet mati | "Gagal terhubung" | Periksa koneksi dan coba lagi |

---

## 5. SOP-02 — Login & Autentikasi

**Nomor SOP** : SOP-02  
**Judul**     : Login dan Autentikasi Pengguna  
**Pelaksana** : Semua peran  
**Waktu**     : ±1 menit  

### 5.1 Tujuan
Memastikan hanya pengguna yang sah dan terverifikasi yang dapat mengakses sistem.

### 5.2 Metode Login

| Metode | Status | Keterangan |
|---|---|---|
| Email + Password | ✅ Aktif | Metode utama |
| Biometrik (Sidik Jari / Face ID) | ✅ Aktif | Setelah login pertama kali |
| Google OAuth | ⚠️ Dalam pengembangan | Belum diaktifkan untuk produksi |

### 5.3 Langkah Login Email & Password

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka aplikasi → layar Login | — |
| 2 | Masukkan Email dan Password | — |
| 3 | Tap **"Login"** | Sistem memvalidasi kredensial |
| 4 | Jika berhasil → redirect ke Home | Berdasarkan role: User → Home, Admin → Admin Panel |
| 5 | Jika gagal 3 kali → akun dikunci 1 jam | Rate limiting aktif |

### 5.4 Login dengan Biometrik

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka aplikasi — muncul prompt biometrik (jika sudah diaktifkan) | — |
| 2 | Autentikasi dengan sidik jari atau Face ID | — |
| 3 | Berhasil → langsung masuk tanpa input password | Sesi dipulihkan dari secure storage |

### 5.5 Kebijakan Sesi

| Kebijakan | Nilai |
|---|---|
| Auto-logout inactivity | 15 menit |
| Session timeout total | 30 menit |
| Percobaan login gagal maks. | 3 kali |
| Durasi lockout setelah maks. gagal | 1 jam |

### 5.6 Reset Password

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Tap **"Lupa Password"** di halaman login | — |
| 2 | Masukkan email terdaftar | — |
| 3 | Sistem kirim link reset ke email | Link berlaku 1 jam |
| 4 | Klik link → masukkan password baru | Harus memenuhi ketentuan password |
| 5 | Login ulang dengan password baru | — |

---

## 6. SOP-03 — Pemesanan Lapangan (Booking)

**Nomor SOP** : SOP-03  
**Judul**     : Proses Pemesanan Lapangan Olahraga  
**Pelaksana** : User (Pengguna)  
**Waktu**     : ±10 menit  

### 6.1 Tujuan
Mengatur proses pemesanan lapangan secara tertib, transparan, dan bebas dari double-booking.

### 6.2 Prasyarat
- Akun terverifikasi dan status login aktif
- Lapangan tersedia pada tanggal dan jam yang dipilih
- Saldo/metode pembayaran tersedia

### 6.3 Langkah Pemesanan

| # | Langkah | Pelaksana | Keterangan |
|---|---|---|---|
| 1 | Dari Home, pilih kategori olahraga atau cari lapangan | User | Filter: jenis olahraga, tanggal, jam |
| 2 | Pilih lapangan yang diinginkan | User | Lihat detail: foto, fasilitas, harga, ulasan |
| 3 | Pilih **tanggal** booking | User | Kalender menampilkan hari yang tersedia |
| 4 | Pilih **slot waktu** yang tersedia | User | Slot yang sudah dipesan ditampilkan abu-abu (tidak bisa dipilih) |
| 5 | Periksa ringkasan booking: lapangan, tanggal, jam, harga | User | — |
| 6 | Pilih **tipe booking**: Umum / OPD / Pimpinan | User | OPD/Pimpinan memerlukan dokumen tambahan |
| 7 | Tap **"Pesan Sekarang"** | User | Sistem cek ketersediaan via RPC (real-time lock) |
| 8 | Jika slot masih tersedia → booking dibuat dengan status **Pending** | Sistem | ID Booking dibuat: `SJH-YYYYMMDD-XXXX` |
| 9 | Pengguna diarahkan ke halaman **Konfirmasi Pembayaran** | Sistem | — |

### 6.4 Pencegahan Double-Booking

Sistem menggunakan mekanisme berlapis:
```
Layer 1: RPC get_blocked_slots — cek real-time sebelum booking dibuat
Layer 2: Database constraint UNIQUE pada (field_id, date, slot)
Layer 3: Optimistic locking — transaksi ditolak jika slot sudah terisi
```

### 6.5 Status Booking

```
  PENDING ──► CONFIRMED ──► COMPLETED
     │              │
     └──► CANCELLED ◄┘
```

| Status | Keterangan |
|---|---|
| **Pending** | Booking dibuat, menunggu pembayaran & verifikasi admin |
| **Confirmed** | Admin sudah verifikasi pembayaran, booking aktif |
| **Completed** | Sesi penggunaan lapangan selesai |
| **Cancelled** | Booking dibatalkan oleh user atau admin |

### 6.6 Batas Waktu Pembayaran

> ⚠️ **Booking yang tidak dibayar dalam 24 jam akan otomatis dibatalkan oleh sistem.**  
> Notifikasi pengingat dikirim ke pengguna 2 jam sebelum batas waktu.

---

## 7. SOP-04 — Pembayaran & Konfirmasi

**Nomor SOP** : SOP-04  
**Judul**     : Proses Pembayaran dan Konfirmasi Booking  
**Pelaksana** : User & Admin  
**Waktu**     : User ±5 menit · Admin ±10 menit  

### 7.1 Tujuan
Memastikan proses pembayaran terdokumentasi dengan aman dan booking dikonfirmasi setelah verifikasi.

### 7.2 Metode Pembayaran

| Metode | Keterangan |
|---|---|
| Transfer Bank | Transfer ke rekening resmi DISPORA Kab. Bandung |
| Upload Bukti | Foto/screenshot bukti transfer diunggah via aplikasi |

### 7.3 Langkah Pembayaran (User)

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Setelah booking dibuat, lihat **detail pembayaran** | Tampil nomor rekening, nominal, kode unik |
| 2 | Lakukan transfer ke rekening yang tertera | Sertakan kode unik booking pada keterangan transfer |
| 3 | Kembali ke aplikasi → tap **"Upload Bukti Pembayaran"** | — |
| 4 | Pilih foto bukti transfer dari galeri / kamera | Format: JPG, PNG, PDF — maks. 5 MB |
| 5 | Tap **"Kirim"** | File dienkripsi (AES-256) sebelum diunggah ke server |
| 6 | Status booking berubah menjadi **"Menunggu Verifikasi"** | Notifikasi dikirim ke admin |

### 7.4 Keamanan Upload Bukti Pembayaran
```
1. File dipilih user dari perangkat
2. Sistem enkripsi file dengan AES-256 (FileEncryptionService)
3. File terenkripsi diunggah ke Supabase Storage bucket "payment-proofs"
4. Bucket bersifat PRIVATE — hanya admin yang dapat mengaksesnya
5. Metadata (ukuran, hash, timestamp) disimpan di tabel payment_proofs
```

### 7.5 Langkah Verifikasi Admin (lihat SOP-06)

Setelah user upload bukti, admin melakukan verifikasi. Lihat [SOP-06](#9-sop-06--verifikasi--persetujuan-admin).

### 7.6 Penerbitan E-Ticket

Setelah admin konfirmasi pembayaran:

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Sistem otomatis generate e-ticket (PDF + QR Code) | — |
| 2 | Push notification dikirim ke user: "Booking dikonfirmasi!" | — |
| 3 | User buka menu **"Riwayat Booking"** → pilih booking | — |
| 4 | Tap **"Lihat E-Ticket"** | — |
| 5 | E-ticket dapat diunduh (PDF) atau dibagikan | — |

### 7.7 Format E-Ticket
```
┌─────────────────────────────────────────┐
│  🏟️  SIPELOR BEDAS — E-TICKET           │
│  DISPORA Kabupaten Bandung               │
├─────────────────────────────────────────┤
│  ID Booking   : SJH-20260303-0001       │
│  Nama         : [Nama Pemesan]          │
│  Lapangan     : [Nama Lapangan]         │
│  Tanggal      : [Tanggal]               │
│  Waktu        : [Jam Mulai – Jam Selesai]│
│  Status       : CONFIRMED ✅            │
├─────────────────────────────────────────┤
│           [QR CODE untuk scan]          │
└─────────────────────────────────────────┘
```

---

## 8. SOP-05 — Pembatalan Booking

**Nomor SOP** : SOP-05  
**Judul**     : Prosedur Pembatalan Booking  
**Pelaksana** : User / Admin  
**Waktu**     : ±5 menit  

### 8.1 Tujuan
Mengatur mekanisme pembatalan booking secara adil dan terdokumentasi.

### 8.2 Pembatalan oleh User

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **"Riwayat Booking"** | — |
| 2 | Pilih booking yang ingin dibatalkan | Hanya booking berstatus Pending atau Confirmed yang bisa dibatalkan |
| 3 | Tap **"Batalkan Booking"** | — |
| 4 | Konfirmasi pembatalan dengan tap **"Ya, Batalkan"** | — |
| 5 | Status booking berubah menjadi **Cancelled** | Notifikasi dikirim ke user dan admin |
| 6 | Proses refund (jika berlaku) diproses secara manual oleh admin | — |

### 8.3 Pembatalan oleh Admin

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **Admin Panel** (web) → menu Booking Management | — |
| 2 | Cari booking berdasarkan ID atau nama pemesan | — |
| 3 | Buka detail booking → tap **"Batalkan"** | — |
| 4 | Isi alasan pembatalan | Wajib diisi untuk keperluan audit |
| 5 | Konfirmasi pembatalan | — |
| 6 | Sistem kirim notifikasi ke user dengan alasan pembatalan | — |

### 8.4 Kebijakan Pembatalan

| Waktu Pembatalan | Ketentuan |
|---|---|
| > 24 jam sebelum jadwal | Dapat dibatalkan, refund diproses sesuai kebijakan |
| < 24 jam sebelum jadwal | Pembatalan tetap bisa dilakukan, namun refund tidak dijamin |
| Setelah jadwal selesai | Tidak dapat dibatalkan |

> ⚠️ **Kebijakan refund ditetapkan oleh DISPORA Kabupaten Bandung dan dapat berubah sewaktu-waktu.**

---

## 9. SOP-06 — Verifikasi & Persetujuan Admin

**Nomor SOP** : SOP-06  
**Judul**     : Verifikasi Pembayaran dan Persetujuan Booking oleh Admin  
**Pelaksana** : Admin / Operator  
**Waktu**     : ±10 menit per booking  

### 9.1 Tujuan
Memastikan setiap pembayaran diverifikasi dengan benar sebelum booking dikonfirmasi.

### 9.2 Langkah Verifikasi

| # | Langkah | Pelaksana | Keterangan |
|---|---|---|---|
| 1 | Terima notifikasi: "Ada pembayaran baru menunggu verifikasi" | Admin | Via push notification / dashboard web |
| 2 | Buka **Admin Panel** (web) → **Booking Management** | Admin | — |
| 3 | Filter booking berstatus **"Menunggu Verifikasi"** | Admin | — |
| 4 | Pilih booking → lihat detail dan bukti pembayaran | Admin | File diakses dari Supabase private storage |
| 5 | Periksa kesesuaian: nama, nominal, nomor rekening tujuan, kode unik | Admin | Cocokkan dengan bukti mutasi rekening DISPORA |
| 6a | Jika valid → tap **"Konfirmasi Pembayaran"** | Admin | Status berubah ke **Confirmed** |
| 6b | Jika tidak valid / mencurigakan → tap **"Tolak"** + isi alasan | Admin | Status tetap Pending, notifikasi dikirim ke user |
| 7 | Sistem otomatis terbitkan e-ticket (jika dikonfirmasi) | Sistem | — |
| 8 | Notifikasi otomatis dikirim ke user | Sistem | "Booking Anda telah dikonfirmasi" |

### 9.3 Checklist Verifikasi

```
[ ] Nama pemesan sesuai dengan nama di akun
[ ] Nominal transfer sesuai dengan harga booking
[ ] Rekening tujuan transfer adalah rekening resmi DISPORA
[ ] Kode unik booking tertera pada keterangan transfer
[ ] Tanggal transfer tidak melebihi batas waktu pembayaran
[ ] Bukti pembayaran jelas, tidak blur, dan tidak terlihat diedit
```

### 9.4 Target Waktu Verifikasi

| Prioritas | Target |
|---|---|
| Booking hari yang sama | Maks. 2 jam setelah upload |
| Booking hari berikutnya | Maks. 4 jam kerja |
| Booking > 2 hari ke depan | Maks. 1 hari kerja |

---

## 10. SOP-07 — Booking OPD / Pimpinan Dinas

**Nomor SOP** : SOP-07  
**Judul**     : Pemesanan Lapangan untuk OPD dan Pimpinan Dinas  
**Pelaksana** : Staff OPD / Pimpinan / Admin  
**Waktu**     : ±1–2 hari kerja  

### 10.1 Tujuan
Mengatur mekanisme khusus booking lapangan untuk kegiatan dinas pemerintah.

### 10.2 Ketentuan Booking OPD/Pimpinan

- Booking OPD diprioritaskan atas booking umum pada waktu yang sama.
- Dokumen surat tugas/undangan resmi wajib dilampirkan.
- Pembayaran menggunakan mekanisme keuangan daerah (invoice/SPJ).

### 10.3 Langkah Booking OPD

| # | Langkah | Pelaksana | Keterangan |
|---|---|---|---|
| 1 | Login dengan akun yang telah didaftarkan sebagai OPD | Staff OPD | Akun OPD harus diverifikasi terlebih dahulu oleh Admin |
| 2 | Pilih lapangan → pilih tanggal dan slot | Staff OPD | — |
| 3 | Pada tipe booking, pilih **"OPD"** atau **"Pimpinan"** | Staff OPD | — |
| 4 | Isi nama instansi, nama kegiatan, nomor surat | Staff OPD | — |
| 5 | Upload surat tugas / undangan (PDF) | Staff OPD | — |
| 6 | Submit booking | Staff OPD | Status: Pending — menunggu verifikasi admin |
| 7 | Admin verifikasi kelengkapan dokumen | Admin | Maks. 1 hari kerja |
| 8 | Jika disetujui → booking Confirmed | Admin | Tidak memerlukan bukti transfer untuk OPD resmi |
| 9 | E-ticket diterbitkan | Sistem | — |

### 10.4 Daftar OPD Terdaftar

Daftar OPD yang berhak menggunakan jalur booking khusus dikelola oleh Admin melalui tabel `opd_organizations` di database. Admin dapat menambah, mengubah, atau menonaktifkan OPD terdaftar melalui Admin Panel.

---

## 11. SOP-08 — Real-time Chat User–Admin

**Nomor SOP** : SOP-08  
**Judul**     : Layanan Chat Real-time antara Pengguna dan Admin  
**Pelaksana** : User & Admin/Operator  
**Waktu**     : Respons maks. 2 jam di jam kerja  

### 11.1 Tujuan
Menyediakan saluran komunikasi langsung dan cepat antara pengguna dan admin untuk pertanyaan atau kendala.

### 11.2 Ketentuan Chat

| Ketentuan | Keterangan |
|---|---|
| Jam layanan | Senin–Jumat 08.00–16.00 WIB |
| Target respons | Maks. 2 jam di jam kerja |
| Retensi pesan | Pesan otomatis dihapus setelah 24 jam (menjaga privasi & storage) |
| Bahasa | Indonesia |

### 11.3 Langkah Memulai Chat (User)

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka aplikasi → tap ikon **"Chat"** di bottom navigation | — |
| 2 | Tap **"Mulai Chat Baru"** atau pilih percakapan yang ada | — |
| 3 | Ketik pesan dan tap **"Kirim"** | — |
| 4 | Tunggu balasan dari admin | Notifikasi push saat ada balasan |

### 11.4 Panduan Admin Merespons Chat

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Terima notifikasi chat masuk | — |
| 2 | Buka **Admin Chat List** di aplikasi Flutter atau web admin panel | — |
| 3 | Pilih percakapan pengguna | Tampil nama user, waktu pesan, preview pesan |
| 4 | Ketik dan kirim balasan | — |
| 5 | Tandai percakapan sebagai **Selesai** jika masalah terselesaikan | — |

### 11.5 Konten yang Dilarang di Chat

```
❌ Informasi pribadi yang tidak relevan (nomor KTP, dll.)
❌ Bahasa kasar atau tidak sopan
❌ Link mencurigakan atau phishing
❌ Pertanyaan/topik di luar layanan SIPELOR BEDAS
```

---

## 12. SOP-09 — Ulasan & Penilaian Lapangan

**Nomor SOP** : SOP-09  
**Judul**     : Pemberian Ulasan dan Penilaian Lapangan oleh Pengguna  
**Pelaksana** : User  
**Waktu**     : ±3 menit  

### 12.1 Tujuan
Memastikan ulasan yang masuk adalah valid, berasal dari pengguna yang benar-benar menggunakan lapangan.

### 12.2 Syarat Memberikan Ulasan

> ✅ **Hanya pengguna yang memiliki booking berstatus COMPLETED yang dapat memberikan ulasan.**

### 12.3 Langkah Memberikan Ulasan

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **"Riwayat Booking"** | — |
| 2 | Pilih booking berstatus **Completed** | — |
| 3 | Tap **"Beri Ulasan"** | — |
| 4 | Beri bintang (1–5) | — |
| 5 | Tulis komentar (opsional) | Maks. 500 karakter |
| 6 | Tap **"Kirim Ulasan"** | — |

### 12.4 Moderasi Ulasan

Ulasan ditampilkan secara publik di halaman detail lapangan. Admin dapat menghapus ulasan yang:
- Mengandung konten tidak pantas (SARA, kata kasar, dll.)
- Tidak relevan dengan layanan
- Terindikasi spam atau palsu

---

## 13. SOP-10 — Manajemen Lapangan (Admin)

**Nomor SOP** : SOP-10  
**Judul**     : Pengelolaan Data Lapangan Olahraga  
**Pelaksana** : Admin  
**Waktu**     : ±15 menit per lapangan  

### 13.1 Tujuan
Memastikan data lapangan selalu akurat, terkini, dan tersaji dengan baik di aplikasi pengguna.

### 13.2 Langkah Menambah Lapangan Baru

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **Admin Panel Web** → menu **Manajemen Lapangan** | — |
| 2 | Tap **"Tambah Lapangan"** | — |
| 3 | Isi data: Nama, Venue, Jenis Olahraga, Kapasitas, Harga/Jam | — |
| 4 | Upload foto lapangan (min. 3 foto, maks. 10 foto) | Format: JPG/PNG, maks. 5 MB per foto |
| 5 | Atur status: **Aktif** / **Nonaktif** / **Maintenance** | — |
| 6 | Atur jam operasional dan hari buka | — |
| 7 | Simpan | Data langsung tampil di aplikasi pengguna |

### 13.3 Langkah Update Data Lapangan

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Pilih lapangan yang akan diupdate | — |
| 2 | Ubah field yang diperlukan | — |
| 3 | Simpan perubahan | Perubahan real-time tampil di aplikasi |

### 13.4 Status Lapangan

| Status | Keterangan | Dampak di Aplikasi |
|---|---|---|
| **Aktif** | Lapangan beroperasi normal | Dapat di-booking oleh user |
| **Nonaktif** | Lapangan tidak beroperasi | Tidak tampil di daftar booking |
| **Maintenance** | Sedang dalam perawatan | Tampil dengan label "Sedang dalam Perawatan" |

---

## 14. SOP-11 — Jadwal Pemeliharaan Lapangan

**Nomor SOP** : SOP-11  
**Judul**     : Penjadwalan dan Pelaksanaan Pemeliharaan Lapangan  
**Pelaksana** : Admin / Operator  
**Waktu**     : Perencanaan ±15 menit  

### 14.1 Tujuan
Memastikan lapangan dipelihara secara berkala tanpa mengganggu jadwal booking yang sudah ada.

### 14.2 Langkah Penjadwalan Maintenance

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **Admin Panel** → **Jadwal Maintenance** | — |
| 2 | Pilih lapangan yang akan dirawat | — |
| 3 | Tentukan tanggal dan jam maintenance | Sistem cek apakah ada booking aktif pada waktu tersebut |
| 4 | Jika ada booking → sistem beri peringatan | Admin harus batalkan booking terlebih dahulu dan notifikasi user |
| 5 | Isi deskripsi pekerjaan maintenance | — |
| 6 | Simpan jadwal | Slot otomatis diblokir, tidak dapat di-booking |
| 7 | Status lapangan otomatis berubah ke **Maintenance** pada waktu yang dijadwalkan | — |
| 8 | Setelah selesai → ubah status kembali ke **Aktif** | — |

### 14.3 Jenis Pemeliharaan

| Jenis | Frekuensi | Keterangan |
|---|---|---|
| Rutin harian | Setiap hari | Kebersihan, pengecekan fasilitas |
| Mingguan | Setiap minggu | Perawatan rumput, net, garis lapangan |
| Bulanan | Setiap bulan | Pengecatan, perbaikan minor |
| Insidental | Sesuai kebutuhan | Kerusakan mendadak, bencana, dll. |

---

## 15. SOP-12 — Manajemen Staff & Hak Akses

**Nomor SOP** : SOP-12  
**Judul**     : Pengelolaan Akun Staff dan Hak Akses Sistem  
**Pelaksana** : Manager / Super Admin  
**Waktu**     : ±10 menit per staff  

### 15.1 Tujuan
Memastikan kontrol akses sistem yang ketat sesuai prinsip least privilege (akses minimal yang diperlukan).

### 15.2 Langkah Menambah Staff Baru

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **Admin Panel Web** → **Manajemen Staff** | Hanya Manager/Super Admin |
| 2 | Tap **"Tambah Staff"** | — |
| 3 | Isi: Nama, Email, Jabatan, Nomor HP | — |
| 4 | Pilih peran: **Admin** / **Manager** / **Operator** | — |
| 5 | Sistem kirim email undangan ke staff | Berisi link untuk aktivasi akun |
| 6 | Staff aktivasi akun dan set password | — |

### 15.3 Matriks Hak Akses Detail

| Fitur | Operator | Admin | Manager | Super Admin |
|---|:---:|:---:|:---:|:---:|
| Lihat daftar booking | ✅ | ✅ | ✅ | ✅ |
| Verifikasi pembayaran | ❌ | ✅ | ✅ | ✅ |
| Konfirmasi/tolak booking | ❌ | ✅ | ✅ | ✅ |
| Kelola lapangan (CRUD) | ❌ | ✅ | ✅ | ✅ |
| Jadwal maintenance | ✅ | ✅ | ✅ | ✅ |
| Kelola staff | ❌ | ❌ | ✅ | ✅ |
| Lihat analytics & laporan | ❌ | ✅ | ✅ | ✅ |
| Export laporan | ❌ | ✅ | ✅ | ✅ |
| Moderasi ulasan | ✅ | ✅ | ✅ | ✅ |
| Kelola banner/promo | ❌ | ✅ | ✅ | ✅ |
| Lihat audit log | ❌ | ✅ | ✅ | ✅ |
| Konfigurasi sistem | ❌ | ❌ | ❌ | ✅ |
| Debug menu | ❌ | ❌ | ❌ | ✅ |

### 15.4 Prosedur Nonaktifkan Staff

Jika staff berhenti bekerja atau pindah jabatan:

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka detail akun staff di Admin Panel | — |
| 2 | Tap **"Nonaktifkan Akun"** | — |
| 3 | Konfirmasi tindakan | Akun langsung tidak bisa login |
| 4 | Catat alasan penonaktifan di sistem | Untuk keperluan audit |

---

## 16. SOP-13 — Penanganan Insiden Keamanan

**Nomor SOP** : SOP-13  
**Judul**     : Prosedur Respons terhadap Insiden Keamanan Sistem  
**Pelaksana** : Super Admin / Tim Teknis  
**Prioritas** : 🔴 KRITIS  

### 16.1 Tujuan
Memastikan insiden keamanan ditangani dengan cepat, terdokumentasi, dan dampaknya diminimalkan.

### 16.2 Klasifikasi Insiden

| Level | Deskripsi | Contoh | Respons Maks. |
|---|---|---|---|
| 🔴 **Kritis** | Kompromi data, pelanggaran akses besar | Kebocoran data user, akses ilegal DB | 1 jam |
| 🟠 **Tinggi** | Gangguan layanan signifikan | Sistem tidak bisa diakses, serangan DDoS | 4 jam |
| 🟡 **Sedang** | Anomali keamanan | Login mencurigakan berulang, abuse rate limit | 24 jam |
| 🟢 **Rendah** | Potensi risiko minor | Vulnerability kecil, peringatan konfigurasi | 72 jam |

### 16.3 Langkah Respons Insiden Kritis

| # | Langkah | Pelaksana | Waktu |
|---|---|---|---|
| 1 | Terima alert dari Sentry / sistem monitoring | Super Admin | T+0 |
| 2 | Identifikasi scope dan dampak insiden | Tim Teknis | T+15 menit |
| 3 | Isolasi sistem yang terdampak (jika perlu) | Super Admin | T+30 menit |
| 4 | Laporkan ke Kepala DISPORA | Super Admin | T+30 menit |
| 5 | Investigasi akar masalah (root cause) | Tim Teknis | T+1 jam |
| 6 | Implementasi mitigasi darurat | Tim Teknis | T+2 jam |
| 7 | Notifikasi pengguna yang terdampak (jika perlu) | Admin | T+2 jam |
| 8 | Implementasi perbaikan permanen | Tim Teknis | T+24 jam |
| 9 | Buat laporan insiden lengkap | Super Admin | T+48 jam |
| 10 | Review dan perbaikan prosedur | Tim | T+7 hari |

### 16.4 Kontak Darurat

| Peran | Tugas |
|---|---|
| Super Admin Teknis | Penanganan teknis langsung |
| Kepala DISPORA | Keputusan eskalatif & komunikasi publik |
| Tim Developer | Perbaikan kode/infrastruktur |
| Supabase Support | Insiden di level infrastruktur database |

### 16.5 Trigger Otomatis Keamanan

Sistem secara otomatis:
```
✅ Memblokir akun setelah 3 kali login gagal (1 jam)
✅ Alert via Sentry jika ada exception tidak normal
✅ RASP menghentikan aplikasi jika deteksi root/jailbreak di production
✅ SSL pinning memblokir koneksi jika sertifikat tidak cocok
✅ Audit log mencatat semua aksi admin secara otomatis
```

---

## 17. SOP-14 — Backup & Pemulihan Data

**Nomor SOP** : SOP-14  
**Judul**     : Prosedur Backup dan Pemulihan Data Sistem  
**Pelaksana** : Super Admin / Tim Teknis  
**Frekuensi** : Backup otomatis harian  

### 17.1 Kebijakan Backup

| Jenis | Frekuensi | Retensi | Penyimpanan |
|---|---|---|---|
| **Database PostgreSQL** | Otomatis oleh Supabase | 30 hari | Supabase Cloud |
| **Storage Bucket** | Otomatis oleh Supabase | 30 hari | Supabase Cloud |
| **Konfigurasi Aplikasi** | Manual setiap rilis | Indefinite | Git Repository |
| **Audit Logs** | Otomatis | 90 hari | Database |

### 17.2 Prosedur Point-in-Time Recovery (PITR)

Supabase mendukung PITR (pemulihan ke titik waktu tertentu). Untuk melakukan restore:

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Login ke dashboard Supabase | — |
| 2 | Pilih project SIPELOR BEDAS | — |
| 3 | Settings → Database → Backups | — |
| 4 | Pilih titik waktu yang ingin dipulihkan | — |
| 5 | Konfirmasi restore | Proses berlangsung 10–30 menit |
| 6 | Verifikasi integritas data setelah restore | Cek jumlah record, status booking, dll. |
| 7 | Aktifkan kembali layanan | — |

> ⚠️ **Restore database akan menimpa data saat ini. Pastikan backup terbaru aman sebelum restore.**

---

## 18. SOP-15 — Pelaporan & Analitik

**Nomor SOP** : SOP-15  
**Judul**     : Pelaporan Data dan Analitik Operasional  
**Pelaksana** : Manager / Admin  
**Frekuensi** : Harian / Mingguan / Bulanan  

### 18.1 Tujuan
Menyediakan informasi operasional yang akurat untuk pengambilan keputusan manajemen DISPORA.

### 18.2 Jenis Laporan

| Laporan | Frekuensi | Isi | Penerima |
|---|---|---|---|
| **Laporan Harian** | Setiap hari (otomatis) | Total booking, pendapatan, booking baru | Admin, Manager |
| **Laporan Mingguan** | Setiap Senin (otomatis) | Tren mingguan, lapangan tersibuk, user aktif | Manager |
| **Laporan Bulanan** | Setiap tgl 1 (otomatis) | Analisis bulanan, komparasi, proyeksi | Manager, Kepala DISPORA |
| **Laporan Ad-hoc** | Sesuai kebutuhan | Custom berdasarkan filter | Admin, Manager |

### 18.3 Cara Mengakses Laporan

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka **Admin Panel Web** | — |
| 2 | Pilih menu **Analytics / Laporan** | — |
| 3 | Pilih jenis laporan dan rentang waktu | — |
| 4 | Lihat visualisasi chart (harian/mingguan/bulanan) | — |
| 5 | Tap **"Export"** untuk unduh laporan | Format: PDF atau CSV |

### 18.4 Metrik Utama yang Dipantau

```
📊 Total booking (per hari/minggu/bulan)
💰 Total pendapatan (per periode)
🏟️  Lapangan tersibuk / teramai
👥 Jumlah user aktif baru vs. returning
📈 Tingkat konversi (browse → booking → bayar)
⭐ Rata-rata rating lapangan
📉 Tingkat pembatalan booking
💬 Volume chat dan rata-rata waktu respons
```

---

## 19. SOP-16 — Penanganan Keluhan Pengguna

**Nomor SOP** : SOP-16  
**Judul**     : Prosedur Penanganan Keluhan dan Pengaduan Pengguna  
**Pelaksana** : Operator / Admin  
**Target**    : Selesai dalam 1 hari kerja  

### 19.1 Tujuan
Memastikan setiap keluhan pengguna ditangani secara profesional, cepat, dan memberikan kepuasan.

### 19.2 Saluran Keluhan

| Saluran | Cara | Waktu Respons |
|---|---|---|
| **In-App Chat** | Fitur chat di aplikasi | Maks. 2 jam (jam kerja) |
| **Email** | Email resmi DISPORA | Maks. 1 hari kerja |
| **Langsung** | Datang ke kantor DISPORA | Segera |

### 19.3 Langkah Penanganan Keluhan

| # | Langkah | Pelaksana | Keterangan |
|---|---|---|---|
| 1 | Terima keluhan dari user via chat/email | Operator | Catat: nama, ID booking, deskripsi masalah |
| 2 | Konfirmasi penerimaan keluhan kepada user | Operator | Berikan estimasi waktu penyelesaian |
| 3 | Investigasi masalah | Operator/Admin | Cek data booking, log sistem, bukti |
| 4 | Identifikasi solusi | Admin | — |
| 5a | Jika dapat diselesaikan → laksanakan solusi | Admin | — |
| 5b | Jika perlu eskalasi → teruskan ke Manager/Super Admin | Admin | — |
| 6 | Informasikan solusi kepada user | Operator | — |
| 7 | Dokumentasikan keluhan dan resolusi | Admin | Untuk perbaikan ke depan |

### 19.4 Jenis Keluhan Umum & Solusi

| Keluhan | Solusi Cepat |
|---|---|
| Tidak bisa login | Cek status akun, reset password, cek rate limit |
| Pembayaran tidak dikonfirmasi | Verifikasi manual oleh admin, cek bukti ulang |
| E-ticket tidak muncul | Cek status booking, generate ulang e-ticket |
| Slot yang sudah dipesan tidak tersedia | Investigasi double-booking, kompensasi jika terbukti kesalahan sistem |
| Aplikasi error/crash | Minta screenshot error, laporkan ke tim teknis via Sentry |
| Data profil tidak tersimpan | Cek koneksi internet, coba lagi, eskalasi ke teknis jika berulang |

---

## 20. SOP-17 — Deployment & Rilis Aplikasi

**Nomor SOP** : SOP-17  
**Judul**     : Prosedur Deployment dan Rilis Versi Aplikasi Baru  
**Pelaksana** : Super Admin / Tim Developer  
**Waktu**     : ±2–4 jam  

### 20.1 Tujuan
Memastikan setiap rilis aplikasi melewati proses quality assurance yang ketat sebelum sampai ke pengguna.

### 20.2 Checklist Pre-Deployment

```
[ ] Semua fitur baru telah melewati unit testing (target coverage 70%+)
[ ] flutter analyze — tidak ada error di folder lib/
[ ] Manual testing checklist selesai (400+ test cases)
[ ] Security audit checklist selesai
[ ] Versi pubspec.yaml diperbarui
[ ] CHANGELOG diperbarui
[ ] Dokumen SOP/PROBIS diperbarui jika ada perubahan proses
[ ] Supabase RLS policy diverifikasi
[ ] Sentry DSN dikonfigurasi untuk lingkungan produksi
[ ] SSL certificate pins diperbarui (jika perlu)
[ ] Tanda tangan APK/IPA menggunakan keystore resmi
```

### 20.3 Langkah Build & Release (Android APK)

| # | Perintah / Langkah | Keterangan |
|---|---|---|
| 1 | `flutter clean` | Bersihkan build cache |
| 2 | `flutter pub get` | Update dependencies |
| 3 | `flutter analyze` | Pastikan 0 error |
| 4 | `flutter test` | Jalankan semua unit test |
| 5 | `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` | Build APK produksi |
| 6 | Test APK di perangkat fisik Android | Minimal 2 perangkat berbeda |
| 7 | Upload ke Google Play / distribusi internal | — |

### 20.4 Rollback Plan

Jika rilis baru menyebabkan masalah kritis:

| # | Langkah | Waktu |
|---|---|---|
| 1 | Identifikasi masalah dan dampak | T+0 |
| 2 | Keputusan rollback oleh Super Admin | T+15 menit |
| 3 | Publikasikan kembali versi sebelumnya | T+30 menit |
| 4 | Notifikasi pengguna via push notification | T+30 menit |
| 5 | Investigasi dan perbaikan | T+24 jam |

---

## 21. Lampiran

### Lampiran A — Kode Status Booking

| Kode | Status | Keterangan |
|---|---|---|
| `pending` | Menunggu | Booking dibuat, menunggu pembayaran |
| `confirmed` | Dikonfirmasi | Pembayaran diverifikasi, booking aktif |
| `completed` | Selesai | Sesi penggunaan lapangan selesai |
| `cancelled` | Dibatalkan | Booking dibatalkan |

### Lampiran B — Format ID Booking

```
SJH - YYYYMMDD - XXXX
│       │          │
│       │          └─ Nomor urut 4 digit (0001, 0002, ...)
│       └─ Tanggal booking (20260303 = 3 Maret 2026)
└─ Kode venue Jalak Harupat
```

### Lampiran C — Jam Operasional Layanan

| Layanan | Jam | Hari |
|---|---|---|
| Pemesanan lapangan | 06.00 – 22.00 WIB | Setiap hari |
| Customer service (chat) | 08.00 – 16.00 WIB | Senin – Jumat |
| Verifikasi pembayaran | 08.00 – 16.00 WIB | Senin – Jumat |
| Lapangan (operasional) | 06.00 – 22.00 WIB | Setiap hari |

### Lampiran D — Dokumen Terkait

| Dokumen | Lokasi |
|---|---| 
| PROBIS SIPELOR BEDAS | `docs/PROBIS_SIPELOR_BEDAS.md` |
| Manual Testing Checklist | `docs/MANUAL_TESTING_CHECKLIST.md` |
| Security Audit Checklist | `docs/SECURITY_AUDIT_CHECKLIST.md` |
| User Manual | `docs/USER_MANUAL.md` |
| Troubleshooting Guide | `docs/TROUBLESHOOTING.md` |
| Analisis Project Komprehensif | `docs/ANALISIS_PROJECT_KOMPREHENSIF_2026-03-03.md` |

---

<div align="center">

---

**Nomor Dokumen** : SOP-SIPELOR-2026-001  
**Versi**         : 1.0  
**Tanggal Terbit**: 3 Maret 2026  
**Berlaku s.d.**  : 3 Maret 2027 (atau sampai ada revisi)  

*© 2026 DISPORA Kabupaten Bandung — Dokumen Internal*  
*Dilarang memperbanyak atau menyebarluaskan tanpa izin tertulis.*

---

</div>
