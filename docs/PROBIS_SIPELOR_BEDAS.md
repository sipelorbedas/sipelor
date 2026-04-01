# 🔄 PROBIS — SIPELOR BEDAS
## Proses Bisnis (Business Process)

<div align="center">

```
╔══════════════════════════════════════════════════════════════════════════╗
║         PROBIS — SIPELOR BEDAS                                           ║
║         Proses Bisnis Sistem Pemesanan Lapangan Olahraga BEDAS           ║
║         DISPORA Kabupaten Bandung                                        ║
╚══════════════════════════════════════════════════════════════════════════╝
```

**Nomor Dokumen** : PROBIS-SIPELOR-2026-001  
**Versi**         : 1.0  
**Tanggal Terbit**: 3 Maret 2026  
**Metodologi**    : Business Process Model & Notation (BPMN) — Tekstual  
**Status**        : 🟢 Berlaku

</div>

---

## 📑 Daftar Isi

1. [Gambaran Umum Proses Bisnis](#1-gambaran-umum-proses-bisnis)
2. [Peta Proses Bisnis (Process Map)](#2-peta-proses-bisnis-process-map)
3. [PROBIS-01 — Registrasi & Onboarding Pengguna](#3-probis-01--registrasi--onboarding-pengguna)
4. [PROBIS-02 — Pemesanan Lapangan End-to-End](#4-probis-02--pemesanan-lapangan-end-to-end)
5. [PROBIS-03 — Pembayaran & Verifikasi](#5-probis-03--pembayaran--verifikasi)
6. [PROBIS-04 — Penggunaan Lapangan & E-Ticket](#6-probis-04--penggunaan-lapangan--e-ticket)
7. [PROBIS-05 — Booking OPD / Pimpinan Dinas](#7-probis-05--booking-opd--pimpinan-dinas)
8. [PROBIS-06 — Manajemen Operasional Admin](#8-probis-06--manajemen-operasional-admin)
9. [PROBIS-07 — Penanganan Keluhan & Chat](#9-probis-07--penanganan-keluhan--chat)
10. [PROBIS-08 — Pemeliharaan Lapangan](#10-probis-08--pemeliharaan-lapangan)
11. [PROBIS-09 — Pelaporan & Analitik Bisnis](#11-probis-09--pelaporan--analitik-bisnis)
12. [PROBIS-10 — Keamanan & Respons Insiden](#12-probis-10--keamanan--respons-insiden)
13. [Indikator Kinerja Utama (KPI)](#13-indikator-kinerja-utama-kpi)
14. [Matriks Risiko Proses Bisnis](#14-matriks-risiko-proses-bisnis)

---

## 1. Gambaran Umum Proses Bisnis

### 1.1 Konteks Bisnis

SIPELOR BEDAS adalah sistem digital yang mentransformasi proses pemesanan lapangan olahraga di SOR Jalak Harupat dari manual (tatap muka/telepon) menjadi sepenuhnya digital, transparan, dan dapat diakses kapan saja.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    KONTEKS SISTEM SIPELOR BEDAS                     │
├──────────────────┬──────────────────────────────────────────────────┤
│  SEBELUM (Manual)│  SESUDAH (Digital – SIPELOR BEDAS)               │
├──────────────────┼──────────────────────────────────────────────────┤
│ Antri di loket   │ Booking kapan saja via smartphone/web            │
│ Cek via telepon  │ Real-time availability & slot                    │
│ Bayar tunai      │ Transfer bank + upload bukti otomatis            │
│ Tiket kertas     │ E-ticket PDF + QR Code                           │
│ Rekap manual     │ Analytics & laporan otomatis                     │
│ Komunikasi telp  │ Real-time chat dalam aplikasi                    │
│ Arsip fisik      │ Database terenkripsi & terpusat                  │
└──────────────────┴──────────────────────────────────────────────────┘
```

### 1.2 Pemangku Kepentingan (Stakeholders)

```
                        ┌─────────────────┐
                        │   DISPORA KAB.  │
                        │    BANDUNG      │
                        │  (Pemilik/Owner)│
                        └────────┬────────┘
                                 │ mengelola
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │   SUPER ADMIN   │ │  ADMIN/MANAGER  │ │    OPERATOR     │
    │ (Tim Teknis)    │ │ (Staff DISPORA) │ │ (Petugas SOR)   │
    └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
             │                   │                   │
             └───────────────────┼───────────────────┘
                                 │ melayani
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │  MASYARAKAT     │ │  INSTANSI OPD   │ │   PIMPINAN      │
    │  UMUM (User)    │ │  (Booking Dinas)│ │   DINAS         │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
```

### 1.3 Ekosistem Teknologi Pendukung

```
┌───────────────────────────────────────────────────────────────────┐
│                    EKOSISTEM TEKNOLOGI                            │
├──────────────────┬────────────────────────────────────────────────┤
│  FRONTEND        │  Flutter (Android · iOS)                       │
│  BACKEND         │  Supabase (PostgreSQL + Realtime + Storage)    │
│  AUTH            │  Supabase Auth (PKCE Flow + Biometrik)         │
│  NOTIFIKASI      │  Push Notification                             │
│  MONITORING      │  Sentry (Error Tracking)                       │
│  ADMIN PANEL     │  Web (HTML/JS) → website/admin/                │
│  KEAMANAN        │  RASP + SSL Pinning + AES-256 + Rate Limiting  │
└──────────────────┴────────────────────────────────────────────────┘
```

---

## 2. Peta Proses Bisnis (Process Map)

### 2.1 Level 0 — Proses Utama

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        PETA PROSES BISNIS LEVEL 0                          │
│                         SIPELOR BEDAS — DISPORA                            │
├──────────┬─────────────┬──────────────┬──────────────┬─────────────────────┤
│  P1      │  P2         │  P3          │  P4          │  P5                 │
│REGISTRASI│ PEMESANAN   │ PEMBAYARAN   │ PENGGUNAAN   │ PELAPORAN           │
│ & AKUN   │ LAPANGAN    │ & VERIFIKASI │ LAPANGAN     │ & ANALITIK          │
└──────────┴─────────────┴──────────────┴──────────────┴─────────────────────┘
│  P6      │  P7         │  P8          │  P9          │  P10                │
│MANAJEMEN │ PEMELIHARAAN│ PENANGANAN   │ MANAJEMEN    │ KEAMANAN &          │
│ OPERASI  │ LAPANGAN    │ KELUHAN      │ KONTEN       │ COMPLIANCE          │
└──────────┴─────────────┴──────────────┴──────────────┴─────────────────────┘
```

### 2.2 Level 1 — Swimlane Proses Utama Booking

```
SWIMLANE — PROSES PEMESANAN LAPANGAN END-TO-END
═══════════════════════════════════════════════════════════════════════════
USER         │  SISTEM             │  ADMIN              │  DATABASE
─────────────┼─────────────────────┼─────────────────────┼────────────────
  [Login]    │                     │                     │
     │        │                     │                     │
     ▼        │                     │                     │
 [Browse      │                     │                     │
  Lapangan]──►│ Tampil daftar       │                     │◄─ Query fields
              │ lapangan & slot     │                     │
     ◄────────┤                     │                     │
     │        │                     │                     │
     ▼        │                     │                     │
 [Pilih Slot]─►│ Validasi           │                     │
              │ ketersediaan ───────┼─────────────────────┼──► RPC check
     ◄────────┤ Slot tersedia?      │                     │
     │        │                     │                     │
     ▼        │                     │                     │
 [Submit     │                     │                     │
  Booking]──►│ Buat booking ───────┼─────────────────────┼──► INSERT booking
              │ (status: pending)   │                     │
     ◄────────┤ Notif: "Booking     │◄── Notif: "Ada      │
              │ berhasil dibuat"    │    booking baru"    │
     │        │                     │                     │
     ▼        │                     │                     │
 [Upload     │                     │                     │
  Bukti     ─►│ Enkripsi & upload──┼─────────────────────┼──► Storage bucket
  Bayar]      │                     │                     │    payment-proofs
     ◄────────┤                     │◄── Notif: "Verifikasi│
              │                     │    pembayaran baru" │
              │                     │          │          │
              │                     ▼          │          │
              │                  [Verifikasi   │          │
              │                   Bukti Bayar] │          │
              │                     │          │          │
              │                     ▼          │          │
              │                 Valid?──────►[Tolak]──────┼──► UPDATE status
              │                   │           │           │
              │                   ▼           │           │
              │               [Konfirmasi]    │           │
              │                   │           ▼           │
              │                   ├──────► UPDATE booking ►─── Confirmed
              │◄──────────────────┤           status       │
  [Terima    │ Generate E-ticket  │                        │
   E-Ticket  │ + Push Notif       │                        │
   & Notif]  │ "Booking dikonfirm"│                        │
═══════════════════════════════════════════════════════════════════════════
```

---

## 3. PROBIS-01 — Registrasi & Onboarding Pengguna

### 3.1 Deskripsi Proses

**Tujuan**: Mengonboarding pengguna baru sehingga dapat menggunakan sistem secara sah dan aman.  
**Trigger**: Pengguna membuka aplikasi pertama kali dan memilih "Daftar".  
**Hasil**: Akun terverifikasi dan pengguna dapat login dan memesan lapangan.

### 3.2 Diagram Alir

```
[MULAI]
   │
   ▼
[User buka aplikasi] ──► Tampil Onboarding Slider (3 slide)
   │
   ▼
[User tap "Daftar"]
   │
   ▼
[Isi Formulir: Nama, Email, Password]
   │
   ▼
[Centang Persetujuan ToS & Privacy Policy]
   │
   ├──► [Tidak dicentang] ──► Tombol Daftar nonaktif ──► [Kembali isi]
   │
   ▼
[Validasi Input oleh Sistem]
   │
   ├──► [Email sudah terdaftar] ──► Tampil error ──► [User perbaiki]
   ├──► [Password terlalu lemah] ──► Tampil error ──► [User perbaiki]
   │
   ▼
[Sistem buat akun di Supabase Auth]
   │
   ▼
[Sistem kirim email verifikasi]
   │
   ▼
[User buka email & klik link verifikasi]
   │
   ├──► [Link kadaluarsa (>24 jam)] ──► Halaman "Minta kirim ulang" ──► [Kirim ulang]
   │
   ▼
[Akun aktif & terverifikasi]
   │
   ▼
[User dapat login & gunakan aplikasi]
   │
   ▼
[SELESAI]
```

### 3.3 Aturan Bisnis

| ID | Aturan |
|---|---|
| RB-REG-01 | Satu email hanya dapat digunakan untuk satu akun |
| RB-REG-02 | Password harus memenuhi kriteria kekuatan minimal |
| RB-REG-03 | Persetujuan ToS wajib sebelum akun dibuat |
| RB-REG-04 | Akun tidak dapat digunakan sebelum email diverifikasi |
| RB-REG-05 | Link verifikasi email berlaku selama 24 jam |

---

## 4. PROBIS-02 — Pemesanan Lapangan End-to-End

### 4.1 Deskripsi Proses

**Tujuan**: Memberikan pengalaman pemesanan lapangan yang mudah, real-time, dan bebas konflik jadwal.  
**Trigger**: User login dan memilih lapangan yang ingin dipesan.  
**Hasil**: Booking tercatat di sistem dengan ID unik dan status Pending.

### 4.2 Diagram Alir Detail

```
[MULAI — User Login]
   │
   ▼
[Tampil Home Screen]
   │   ┌─ Filter: Jenis Olahraga
   │   ├─ Browse kategori lapangan
   │   └─ Cari lapangan (search)
   ▼
[User pilih lapangan]
   │
   ▼
[Tampil Detail Lapangan]
   │   ┌─ Foto lapangan (carousel)
   │   ├─ Fasilitas & kapasitas
   │   ├─ Harga per jam/slot
   │   ├─ Rating & ulasan
   │   └─ Tombol "Pesan"
   ▼
[User tap "Pesan"]
   │
   ├──► [Belum login] ──► Redirect ke halaman Login ──► [Login dulu]
   │
   ▼
[Tampil Kalender Ketersediaan]
   │
   ▼
[User pilih tanggal]
   │
   ▼
[Tampil Slot Waktu]
   │   ┌─ Slot hijau = Tersedia
   │   ├─ Slot abu-abu = Sudah dipesan
   │   └─ Slot merah = Maintenance
   │
   ▼
[User pilih slot waktu]
   │
   ▼
[Tampil Ringkasan Booking]
   │   ┌─ Nama lapangan
   │   ├─ Tanggal & jam
   │   ├─ Durasi & harga
   │   └─ Tipe booking: Umum / OPD / Pimpinan
   │
   ▼
[User pilih tipe booking]
   │
   ├──► [OPD/Pimpinan] ──► [Proses Khusus OPD → PROBIS-05]
   │
   ▼ (Booking Umum)
[User tap "Pesan Sekarang"]
   │
   ▼
[Sistem: Real-time Cek Ketersediaan via RPC]
   │
   ├──► [Slot sudah terisi (race condition)] ──► Tampil notif "Slot sudah dipesan"
   │                                              ──► User pilih slot lain
   ▼
[Sistem: Buat Booking]
   │   ┌─ Generate ID: SJH-YYYYMMDD-XXXX
   │   ├─ Status: PENDING
   │   ├─ Timestamp deadline bayar: +24 jam
   │   └─ INSERT ke tabel bookings
   │
   ▼
[Notifikasi ke User: "Booking berhasil dibuat!"]
   │
   ▼
[Redirect ke Halaman Konfirmasi Pembayaran]
   │
   ▼
[LANJUT ke PROBIS-03 — Pembayaran]
```

### 4.3 Aturan Bisnis

| ID | Aturan |
|---|---|
| RB-BKG-01 | User harus login untuk melakukan booking |
| RB-BKG-02 | Tidak ada double-booking pada slot yang sama (dijamin via RPC + DB constraint) |
| RB-BKG-03 | Booking yang tidak dibayar dalam 24 jam otomatis dibatalkan |
| RB-BKG-04 | Satu user tidak dapat memiliki lebih dari 3 booking aktif bersamaan |
| RB-BKG-05 | Lapangan dengan status Maintenance/Nonaktif tidak dapat dipesan |

### 4.4 Exception & Penanganan Error

| Kondisi | Penanganan |
|---|---|
| Slot habis saat user submit | Tampil notif, arahkan ke slot/tanggal lain |
| Koneksi internet terputus | Data di-cache; tampil mode offline, sync saat online |
| Sistem error (500) | Tampil pesan ramah, log ke Sentry, tidak double-charge |
| Session expired saat booking | Redirect login, data booking sementara tersimpan |

---

## 5. PROBIS-03 — Pembayaran & Verifikasi

### 5.1 Deskripsi Proses

**Tujuan**: Memastikan setiap pembayaran tercatat, terverifikasi, dan aman.  
**Trigger**: Booking berhasil dibuat (status: Pending).  
**Hasil**: Booking berstatus Confirmed dan e-ticket diterbitkan.

### 5.2 Diagram Alir (Swimlane)

```
USER                    SISTEM                  ADMIN
──────────────────────────────────────────────────────────────
Terima detail          Hitung total            
pembayaran             + kode unik         
     │                      │                      │
     ▼                      │                      │
Transfer bank               │                      │
ke rek. DISPORA             │                      │
     │                      │                      │
     ▼                      │                      │
Upload foto                 │                      │
bukti transfer ────────────►│                      │
                        Enkripsi AES-256           │
                        Simpan ke Storage          │
                        (payment-proofs) ──────────►│
                             │               Terima notif
                             │               "Bukti baru"
                             │                      │
                             │                      ▼
                             │              Buka bukti bayar
                             │              (download & decrypt)
                             │                      │
                             │                      ▼
                             │              Periksa:
                             │              - Nama pemesan ✓
                             │              - Nominal ✓
                             │              - Rek. tujuan ✓
                             │              - Kode unik ✓
                             │              - Tanggal ✓
                             │                      │
                             │               ┌──────┴──────┐
                             │               ▼             ▼
                             │            [VALID]      [TIDAK VALID]
                             │               │             │
                             │               ▼             ▼
                        UPDATE booking   UPDATE booking  Notif user
                        status:          status:         "Bukti ditolak"
                        CONFIRMED        PENDING (tolak) + alasan
                             │               │
                             ▼               │
                        Generate           User upload
                        E-Ticket           ulang bukti
                        (PDF+QR)
                             │
                             ▼
                        Push Notif ─────►User
                        "Booking         terima e-ticket
                        Dikonfirmasi"    & notifikasi
──────────────────────────────────────────────────────────────
```

### 5.3 Keamanan Proses Pembayaran

```
FLOW KEAMANAN UPLOAD BUKTI PEMBAYARAN:
════════════════════════════════════════════════════════
[File di perangkat user]
        │
        ▼
[FileEncryptionService.encrypt(file)]
  ↳ AES-256 encryption
  ↳ Hash SHA-256 dihitung
        │
        ▼
[Upload ke Supabase Storage]
  ↳ Bucket: payment-proofs (PRIVATE)
  ↳ Hanya admin yang dapat akses
  ↳ Metadata disimpan di tabel payment_proofs
        │
        ▼
[Admin request akses file]
  ↳ Signed URL dengan expiry (1 jam)
  ↳ FileEncryptionService.decrypt(file)
  ↳ Verifikasi hash untuk integritas
════════════════════════════════════════════════════════
```

### 5.4 Aturan Bisnis

| ID | Aturan |
|---|---|
| RB-PAY-01 | Semua bukti pembayaran dienkripsi sebelum disimpan |
| RB-PAY-02 | Hanya admin yang dapat mengakses file bukti pembayaran |
| RB-PAY-03 | Admin wajib konfirmasi dalam target waktu yang ditetapkan |
| RB-PAY-04 | Booking otomatis dibatalkan jika tidak ada bukti dalam 24 jam |
| RB-PAY-05 | Setiap tindakan verifikasi dicatat di audit log |

---

## 6. PROBIS-04 — Penggunaan Lapangan & E-Ticket

### 6.1 Deskripsi Proses

**Tujuan**: Memastikan hanya pemesan sah yang dapat menggunakan lapangan.  
**Trigger**: User datang ke SOR pada jadwal yang telah dipesan.  
**Hasil**: Penggunaan lapangan terverifikasi dan status booking berubah Completed.

### 6.2 Diagram Alir

```
[User tiba di SOR Jalak Harupat]
   │
   ▼
[User buka aplikasi → menu "Riwayat Booking"]
   │
   ▼
[User pilih booking aktif (status: Confirmed)]
   │
   ▼
[Tampil E-Ticket dengan QR Code]
   │
   ▼
[Operator scan QR Code dengan perangkat]
   │
   ▼
[Sistem verifikasi QR]
   │
   ├──► [QR tidak valid / palsu] ──► Tampil "QR Code tidak valid"
   │                                  ──► Operator hubungi admin
   │
   ├──► [Booking sudah Cancelled] ──► Tampil "Booking telah dibatalkan"
   │
   ├──► [Tanggal/jam tidak sesuai] ──► Tampil "Tidak sesuai jadwal"
   │
   ▼
[QR Valid — Booking Confirmed]
   │
   ▼
[Operator izinkan akses lapangan]
   │
   ▼
[User gunakan lapangan sesuai jadwal]
   │
   ▼
[Setelah waktu selesai — Sistem otomatis update status]
   │
   ▼
[Status booking: COMPLETED]
   │
   ▼
[Sistem kirim notif: "Bagaimana pengalaman Anda?"]
   │
   ▼
[User dapat memberikan ulasan & rating]
   │
   ▼
[SELESAI]
```

### 6.3 Format & Konten E-Ticket

```
╔═══════════════════════════════════════════════╗
║   🏟️  SIPELOR BEDAS — TIKET ELEKTRONIK        ║
║   DISPORA Kabupaten Bandung                   ║
╠═══════════════════════════════════════════════╣
║  ID Booking  : SJH-20260303-0001              ║
║  Nama        : [Nama Pemesan]                 ║
║  Lapangan    : [Nama Lapangan & Venue]        ║
║  Tanggal     : Selasa, 3 Maret 2026           ║
║  Waktu       : 08:00 – 10:00 WIB             ║
║  Tipe        : Booking Umum                  ║
║  Status      : ✅ CONFIRMED                   ║
╠═══════════════════════════════════════════════╣
║                                               ║
║         ████████████████████                 ║
║         █  [QR CODE untuk  █                 ║
║         █   verifikasi     █                 ║
║         █   petugas SOR]   █                 ║
║         ████████████████████                 ║
║                                               ║
║  ⚠️ Tunjukkan tiket ini kepada petugas        ║
║  sebelum memasuki lapangan                   ║
╚═══════════════════════════════════════════════╝
```

---

## 7. PROBIS-05 — Booking OPD / Pimpinan Dinas

### 7.1 Deskripsi Proses

**Tujuan**: Mengakomodasi kebutuhan booking untuk kegiatan resmi pemerintahan dengan jalur prioritas.  
**Trigger**: Staff OPD atau Pimpinan Dinas memerlukan lapangan untuk kegiatan resmi.  
**Hasil**: Lapangan teralokasi untuk kegiatan dinas tanpa hambatan birokrasi.

### 7.2 Diagram Alir

```
[MULAI]
   │
   ▼
[Pejabat/Staff OPD identifikasi kebutuhan lapangan]
   │
   ▼
[Login dengan akun OPD yang sudah terdaftar]
   │
   ├──► [Akun OPD belum terdaftar] ──► Hubungi Admin DISPORA
   │                                    untuk registrasi OPD
   ▼
[Pilih lapangan, tanggal, slot]
   │
   ▼
[Pilih tipe booking: OPD / Pimpinan]
   │
   ▼
[Isi data tambahan:]
   │   ┌─ Nama instansi OPD
   │   ├─ Nama kegiatan/acara
   │   ├─ Nomor surat undangan/tugas
   │   ├─ Jumlah peserta
   │   └─ Upload surat resmi (PDF)
   │
   ▼
[Submit permohonan booking]
   │
   ▼
[Sistem notifikasi ke Admin DISPORA]
   │
   ▼
[Admin review permohonan]
   │
   ▼
[Cek kelengkapan dokumen & ketersediaan lapangan]
   │
   ├──► [Dokumen tidak lengkap] ──► Notif ke OPD: "Lengkapi dokumen"
   │                                 ──► OPD lengkapi & submit ulang
   │
   ├──► [Konflik jadwal] ──► Admin koordinasi dengan pemohon
   │                          untuk reschedule
   │
   ▼
[Dokumen lengkap & jadwal tersedia]
   │
   ▼
[Admin konfirmasi booking]
   │
   ▼
[Booking status: CONFIRMED]
   │
   ▼
[E-ticket diterbitkan]
   │
   ▼
[Notifikasi ke OPD: "Booking dikonfirmasi"]
   │
   ▼
[SELESAI]
```

### 7.3 Perbedaan Booking Umum vs OPD

| Aspek | Booking Umum | Booking OPD | Booking Pimpinan |
|---|---|---|---|
| Tipe akun | Masyarakat umum | Staff OPD terdaftar | Pimpinan dinas |
| Dokumen | Bukti transfer | Surat tugas/undangan | Disposisi pimpinan |
| Pembayaran | Transfer bank | Invoice/SPJ dinas | Sesuai kebijakan |
| Prioritas slot | Normal | Tinggi | Tertinggi |
| Verifikasi | Admin keuangan | Admin + verifikasi OPD | Admin + persetujuan Manager |
| Waktu konfirmasi | Sesuai SOP-06 | Maks. 1 hari kerja | Prioritas (maks. 4 jam) |

---

## 8. PROBIS-06 — Manajemen Operasional Admin

### 8.1 Deskripsi Proses

**Tujuan**: Memastikan operasional harian layanan berjalan lancar dan terdokumentasi.  
**Trigger**: Admin login ke Admin Panel setiap hari kerja.  
**Ruang Lingkup**: Seluruh aktivitas admin dalam mengelola sistem.

### 8.2 Alur Operasional Harian Admin

```
PAGI (08.00 WIB)
════════════════
[Admin login ke Admin Panel Web]
   │
   ▼
[Cek Dashboard]
   │   ┌─ Total booking pending hari ini
   │   ├─ Pembayaran menunggu verifikasi
   │   ├─ Chat belum direspons
   │   └─ Alert/notifikasi penting
   │
   ▼
[Proses Antrian Verifikasi Pembayaran]
   │   ──► PROBIS-03 (Pembayaran & Verifikasi)
   │
   ▼
[Respons Chat Pengguna yang Pending]
   │   ──► PROBIS-07 (Penanganan Keluhan & Chat)
   │
   ▼
[Cek Jadwal Maintenance Hari Ini]
   │   ──► Update status lapangan jika ada maintenance

SIANG (12.00 WIB)
════════════════════
   │
   ▼
[Monitoring dashboard — laporan real-time]
   │
   ▼
[Handle booking baru & verifikasi yang masuk]

SORE (15.00 WIB)
════════════════
   │
   ▼
[Rekapitulasi aktivitas hari ini]
   │
   ▼
[Cek & respons keluhan yang belum selesai]
   │
   ▼
[Pastikan tidak ada booking pending tanpa tindakan]
   │
   ▼
[Logout — sistem auto-logout jika inactivity 15 menit]
```

### 8.3 Diagram Alir Persetujuan/Penolakan Booking

```
[Admin terima notif booking baru]
   │
   ▼
[Buka detail booking di Admin Panel]
   │
   ▼
[Review data booking:]
   │   - Nama, email, nomor HP user
   │   - Lapangan, tanggal, slot
   │   - Tipe booking
   │   - Bukti pembayaran (jika sudah diupload)
   │
   ▼
   ┌──────────────────────────────────┐
   │ Sudah ada bukti pembayaran?      │
   └──────────────────────────────────┘
         │ YA              │ TIDAK
         ▼                 ▼
   [Verifikasi         [Kirim reminder
    bukti bayar]        ke user via notif]
         │                 │
         ▼                 │
   [Bukti valid?]          │
    │ YA    │ TIDAK        │
    ▼       ▼              │
[Konfirmasi] [Tolak +   [Tunggu hingga
             alasan]     deadline 24 jam]
    │                       │
    ▼                       ▼
[Status: CONFIRMED]  [Batas waktu lewat]
[Generate E-ticket]         │
[Notif user]                ▼
                    [Sistem auto-cancel]
                    [Notif user]
```

---

## 9. PROBIS-07 — Penanganan Keluhan & Chat

### 9.1 Deskripsi Proses

**Tujuan**: Memberikan respons cepat dan solusi efektif atas pertanyaan dan keluhan pengguna.  
**Trigger**: User mengirim pesan melalui fitur chat dalam aplikasi.  
**Hasil**: Masalah user terselesaikan dalam target waktu yang ditetapkan.

### 9.2 Diagram Alir

```
USER                          OPERATOR/ADMIN
──────────────────────────────────────────────────────
[User tap "Chat" di aplikasi]
   │
   ▼
[Tulis pesan & kirim]──────────────────────►[Terima notif chat baru]
   │                                                │
   ▼                                                ▼
[Menunggu respons]                        [Buka percakapan]
   │                                                │
   │                                         [Kategorikan masalah:]
   │                                          ┌─ Pertanyaan umum
   │                                          ├─ Masalah booking
   │                                          ├─ Masalah pembayaran
   │                                          └─ Keluhan teknis
   │                                                │
   │                                                ▼
   │                                        [Dapat selesaikan sendiri?]
   │                                         │ YA          │ TIDAK
   │                                         ▼             ▼
   │                                     [Balas       [Eskalasi ke
   │                                      langsung]    Admin/Manager]
   │                                         │             │
   │◄────────────────────────────────────────┤             │
[Terima jawaban]                             │        [Manager/Admin
   │                                         │         selesaikan]
   ▼                                         │             │
[Masalah selesai?]                           │◄────────────┘
 │ YA    │ TIDAK                             │
 ▼       ▼                                  ▼
[Selesai] [Chat lanjut]             [Tandai "Selesai"]
                                    [Catat di sistem]
──────────────────────────────────────────────────────
```

### 9.3 Kategorisasi Keluhan & Eskalasi

```
LEVEL 1 — Operator (Selesai dalam 2 jam):
  - Pertanyaan harga & jadwal lapangan
  - Pertanyaan cara penggunaan aplikasi
  - Informasi umum SIPELOR BEDAS

LEVEL 2 — Admin (Selesai dalam 4 jam):
  - Masalah verifikasi pembayaran
  - Pembatalan dan refund
  - Masalah e-ticket
  - Keluhan lapangan (kondisi, fasilitas)

LEVEL 3 — Manager (Selesai dalam 1 hari kerja):
  - Komplain serius dari pengguna
  - Dugaan kecurangan atau pelanggaran
  - Isu yang melibatkan kebijakan DISPORA

LEVEL 4 — Super Admin / Tim Teknis (ASAP):
  - Bug kritis aplikasi
  - Masalah keamanan
  - Gangguan layanan skala besar
```

### 9.4 Aturan Bisnis Chat

| ID | Aturan |
|---|---|
| RB-CHAT-01 | Semua pesan otomatis dihapus setelah 24 jam (privasi & storage) |
| RB-CHAT-02 | Target respons maks. 2 jam di jam kerja |
| RB-CHAT-03 | Admin tidak diperbolehkan meminta data sensitif via chat |
| RB-CHAT-04 | Semua percakapan tersimpan dan dapat diaudit selama masa retensi |

---

## 10. PROBIS-08 — Pemeliharaan Lapangan

### 10.1 Deskripsi Proses

**Tujuan**: Memastikan lapangan selalu dalam kondisi prima untuk pengguna.  
**Trigger**: Jadwal maintenance reguler atau kerusakan mendadak terdeteksi.  
**Hasil**: Lapangan diperbaiki dan kembali beroperasi dengan status Aktif.

### 10.2 Diagram Alir

```
┌──────────────────────────────────────────────┐
│             TRIGGER MAINTENANCE              │
├─────────────────┬────────────────────────────┤
│   TERJADWAL     │   INSIDENTAL/DARURAT        │
│ (Rutin/Berkala) │  (Kerusakan Mendadak)       │
└────────┬────────┴────────────────┬───────────┘
         │                         │
         ▼                         ▼
[Admin buat jadwal         [Operator/User laporkan
 maintenance di sistem]     kerusakan via chat/laporan]
         │                         │
         ▼                         ▼
[Sistem cek konflik        [Admin verifikasi
 dengan booking aktif]      laporan kerusakan]
         │                         │
[Ada booking?]──YES──►[Batalkan booking &    │
  │                    notif user]            │
  │ NO                      │                │
  ▼                         └────────────────┘
[Blokir slot maintenance]           │
         │                          ▼
         ▼                  [Buat jadwal maintenance
[Update status              insidental]
 lapangan: MAINTENANCE]
         │
         ▼
[Petugas lakukan pekerjaan maintenance]
         │
         ▼
[Petugas selesai → lapor ke Admin]
         │
         ▼
[Admin verifikasi hasil maintenance]
         │
   [Sesuai?]──NO──►[Maintenance ulang]
         │
         │ YES
         ▼
[Update status lapangan: AKTIF]
         │
         ▼
[Catat di laporan maintenance]
         │
         ▼
[SELESAI]
```

### 10.3 Jadwal Maintenance Reguler

| Jenis | Frekuensi | Estimasi Durasi | Pelaksana |
|---|---|---|---|
| Kebersihan & pengecekan | Harian (sebelum buka) | 1 jam | Cleaning service |
| Perawatan rumput/lantai | Mingguan (Senin) | 3–4 jam | Tim perawatan |
| Perbaikan net & marking | Bulanan | 4–6 jam | Tim teknis |
| Pengecatan & renovasi minor | Per semester | 1–2 hari | Kontraktor |
| Audit kondisi menyeluruh | Tahunan | 1–3 hari | Tim + Manajemen |

---

## 11. PROBIS-09 — Pelaporan & Analitik Bisnis

### 11.1 Deskripsi Proses

**Tujuan**: Menyediakan data dan insight untuk pengambilan keputusan manajemen DISPORA.  
**Trigger**: Otomatis (terjadwal) atau permintaan manual dari Manager/Kepala DISPORA.  
**Hasil**: Laporan akurat dan actionable tersedia di Admin Panel.

### 11.2 Alur Pelaporan Otomatis

```
[SISTEM — Setiap Hari Pukul 00.00 WIB]
   │
   ▼
[Query database: semua transaksi hari kemarin]
   │
   ▼
[Hitung metrik:]
   │   ┌─ Total booking (per lapangan, per jenis olahraga)
   │   ├─ Total pendapatan
   │   ├─ Booking confirmed vs. cancelled
   │   ├─ User baru terdaftar
   │   └─ Rata-rata rating
   │
   ▼
[Generate laporan harian]
   │
   ▼
[Kirim email laporan ke Admin & Manager]
   │
   ▼
[Data tersedia di dashboard Analytics Admin Panel]

[SISTEM — Setiap Senin Pukul 07.00 WIB]
   │
   ▼
[Proses yang sama untuk data 7 hari terakhir]
   │
   ▼
[Generate laporan mingguan dengan tren & komparasi]

[SISTEM — Setiap Tanggal 1, Pukul 07.00 WIB]
   │
   ▼
[Generate laporan bulanan dengan analisis mendalam]
   │
   ▼
[Kirim ke Kepala DISPORA]
```

### 11.3 Dashboard Analytics Real-time

```
┌────────────────────────────────────────────────────────┐
│              DASHBOARD ADMIN — REAL-TIME               │
├──────────────┬─────────────────────────────────────────┤
│ HARI INI     │  Booking: 24  │  Revenue: Rp 4.800.000  │
├──────────────┼─────────────────────────────────────────┤
│ LAPANGAN     │  Tersibuk: Lapangan Badminton A (8 sesi)│
│ TERPOPULER   │  Terendah: Lapangan Tenis (2 sesi)      │
├──────────────┼─────────────────────────────────────────┤
│ PEAK HOURS   │  ████████░░  08.00–10.00 (PUNCAK)       │
│              │  ██████████  16.00–18.00 (PUNCAK)       │
│              │  ████░░░░░░  12.00–14.00                │
├──────────────┼─────────────────────────────────────────┤
│ GRAFIK       │  Chart harian/mingguan/bulanan           │
│ REVENUE      │  (fl_chart — interaktif)                │
├──────────────┼─────────────────────────────────────────┤
│ PENDING      │  Verifikasi bayar: 3 antrian             │
│ ACTIONS      │  Chat belum respons: 2 percakapan        │
└──────────────┴─────────────────────────────────────────┘
```

---

## 12. PROBIS-10 — Keamanan & Respons Insiden

### 12.1 Deskripsi Proses

**Tujuan**: Melindungi sistem, data pengguna, dan integritas layanan dari ancaman keamanan.  
**Trigger**: Alert dari sistem monitoring atau laporan insiden.  
**Hasil**: Ancaman dinetralisir, layanan pulih, dan lessons learned terdokumentasi.

### 12.2 Arsitektur Keamanan Berlapis

```
═══════════════════════════════════════════════════════════════
              SECURITY ARCHITECTURE — SIPELOR BEDAS
═══════════════════════════════════════════════════════════════

  REQUEST/AKSES MASUK
         │
         ▼
  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 1: RASP (Runtime Application Self-Protection)    │
  │  • Root/Jailbreak detection                             │
  │  • Emulator detection                                   │
  │  • Frida/Xposed injection detection                     │
  │  • Anti-tamper guard                                    │
  │  → BLOK jika ancaman kritis di production               │
  └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 2: NETWORK SECURITY                              │
  │  • SSL Certificate Pinning (SHA-256, 2 pins)            │
  │  • HTTPS-only — HTTP ditolak                            │
  │  • Request Signing                                      │
  │  • Security Headers Validation                          │
  │  → BLOK jika sertifikat tidak cocok                     │
  └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 3: AUTHENTICATION & SESSION                      │
  │  • Email verification wajib                             │
  │  • Rate limiting (3 gagal = 1 jam lockout)              │
  │  • Biometric auth                                       │
  │  • Auto-logout (15 menit inactivity)                    │
  │  • Session timeout (30 menit)                           │
  │  • PKCE OAuth flow                                      │
  └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 4: DATA PROTECTION                               │
  │  • AES-256 encryption (data at rest)                    │
  │  • File encryption (payment proofs)                     │
  │  • flutter_secure_storage (credentials)                 │
  │  • Input sanitization                                   │
  │  • No sensitive data in logs (SecureLogger)             │
  └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 5: DATABASE SECURITY (Supabase)                  │
  │  • Row Level Security (RLS) di semua tabel              │
  │  • RBAC via Supabase policies                           │
  │  • RPC SECURITY DEFINER untuk operasi privilege         │
  │  • Audit logs semua aksi admin                          │
  └───────────────────────────┬─────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 6: MONITORING & INCIDENT RESPONSE                │
  │  • Sentry error tracking (real-time)                    │
  │  • Security event notifications                         │
  │  • OWASP mobile security checks                         │
  │  • Comprehensive audit logging                          │
  └─────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
```

### 12.3 Alur Respons Insiden

```
[DETEKSI INSIDEN]
   │   ┌─ Sentry alert otomatis
   │   ├─ Monitoring dashboard anomali
   │   └─ Laporan dari pengguna/admin
   │
   ▼
[Klasifikasi Level Insiden]
   │
   ├──► KRITIS (Data breach, akses ilegal)
   │       │
   │       ▼
   │   [T+0]  Alert Super Admin & Manager
   │   [T+15] Isolasi sistem jika perlu
   │   [T+30] Laporan ke Kepala DISPORA
   │   [T+1h] Investigasi & mitigasi darurat
   │   [T+2h] Notif pengguna terdampak
   │   [T+24h] Perbaikan permanen
   │   [T+48h] Laporan insiden lengkap
   │
   ├──► TINGGI (Gangguan layanan)
   │       ▼
   │   [T+0] Alert Admin & Tim Teknis
   │   [T+4h] Identifikasi & perbaikan
   │   [T+8h] Laporan & pemulihan
   │
   └──► SEDANG/RENDAH
           ▼
       [Tangani dalam 24–72 jam kerja]
       [Dokumentasikan & improve]
```

---

## 13. Indikator Kinerja Utama (KPI)

### 13.1 KPI Operasional

| Kategori | Indikator | Target | Pengukuran |
|---|---|---|---|
| **Layanan** | Booking confirmation time | < 4 jam kerja | Per booking |
| **Layanan** | Chat response time | < 2 jam | Per percakapan |
| **Layanan** | Keluhan terselesaikan | > 95% dalam 1 hari | Bulanan |
| **Teknis** | Uptime sistem | > 99.5% | Bulanan |
| **Teknis** | App crash rate | < 0.5% | Mingguan |
| **Teknis** | Response time API | < 500ms | Real-time |
| **Bisnis** | Tingkat konversi (browse→booking) | > 30% | Bulanan |
| **Bisnis** | Booking cancellation rate | < 10% | Bulanan |
| **Bisnis** | User retention (aktif kembali) | > 60% | Bulanan |
| **Keamanan** | Security incident | 0 kritis | Bulanan |
| **Kualitas** | Rata-rata rating lapangan | > 4.0/5.0 | Bulanan |

### 13.2 KPI Keuangan

| Indikator | Formula | Target |
|---|---|---|
| Total pendapatan bulanan | Σ(harga × booking confirmed) | Sesuai target DISPORA |
| Rata-rata nilai booking | Total pendapatan / total booking | Naik 5% per kuartal |
| Lapangan dengan utilisasi tertinggi | Booking count per lapangan | > 70% kapasitas |
| Lapangan dengan utilisasi terendah | Booking count per lapangan | Evaluasi jika < 30% |

---

## 14. Matriks Risiko Proses Bisnis

### 14.1 Identifikasi & Mitigasi Risiko

| ID | Risiko | Kemungkinan | Dampak | Level | Mitigasi |
|---|---|---|---|---|---|
| R-01 | Double-booking lapangan | Rendah | Tinggi | 🟡 Sedang | RPC real-time + DB constraint UNIQUE |
| R-02 | Pembayaran palsu/fraud | Sedang | Tinggi | 🔴 Tinggi | Verifikasi manual admin + enkripsi bukti |
| R-03 | Kebocoran data pengguna | Rendah | Kritis | 🔴 Tinggi | AES-256, RLS, SSL Pinning, Sentry |
| R-04 | Sistem tidak tersedia (downtime) | Rendah | Tinggi | 🟡 Sedang | Supabase SLA + offline cache mode |
| R-05 | Pemesanan tidak dikonfirmasi tepat waktu | Sedang | Sedang | 🟡 Sedang | SOP target waktu + notif reminder |
| R-06 | User tidak bisa login (akun terkunci) | Sedang | Sedang | 🟡 Sedang | SOP reset password + admin override |
| R-07 | E-ticket dipalsukan | Rendah | Tinggi | 🟡 Sedang | QR Code dengan enkripsi + verifikasi sistem |
| R-08 | Data analytics tidak akurat | Rendah | Sedang | 🟢 Rendah | Validasi query + automated testing |
| R-09 | Staf tidak mengikuti SOP | Sedang | Sedang | 🟡 Sedang | Pelatihan + audit log + RBAC |
| R-10 | Aplikasi disusupi (MITM attack) | Rendah | Kritis | 🔴 Tinggi | SSL Pinning + RASP + Request Signing |
| R-11 | Kehilangan data (data loss) | Sangat Rendah | Kritis | 🟡 Sedang | Supabase auto-backup harian (30 hari) |
| R-12 | Slot maintenance konflik dengan booking | Sedang | Sedang | 🟡 Sedang | Cek otomatis saat input jadwal maintenance |

### 14.2 Risk Heat Map

```
        │  DAMPAK
        │  Rendah    Sedang    Tinggi    Kritis
────────┼──────────────────────────────────────
Tinggi  │            R-09      R-02      
        │                      R-05      
────────┼──────────────────────────────────────
Sedang  │            R-08      R-01      R-10
        │            R-12      R-06      R-03
────────┼──────────────────────────────────────
Rendah  │                      R-04      
        │                      R-07      R-11
────────┼──────────────────────────────────────

🔴 = Tinggi / Kritis  🟡 = Sedang  🟢 = Rendah
```

---

<div align="center">

---

**Nomor Dokumen** : PROBIS-SIPELOR-2026-001  
**Versi**         : 1.0  
**Tanggal Terbit**: 3 Maret 2026  
**Berlaku s.d.**  : 3 Maret 2027 (atau sampai ada revisi)  
**Review Berikutnya**: Setelah soft launch (Est. April 2026)  

| Disusun | Diperiksa | Disetujui |
|---|---|---|
| Tim Developer SIPELOR BEDAS | Kepala Bidang IT DISPORA | Kepala DISPORA Kab. Bandung |
| 3 Maret 2026 | — | — |

*© 2026 DISPORA Kabupaten Bandung — Dokumen Internal*  
*Dilarang memperbanyak atau menyebarluaskan tanpa izin tertulis.*

---

</div>
