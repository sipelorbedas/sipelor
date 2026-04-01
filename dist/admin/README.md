# SIPELOR BEDAS — Web Admin Dashboard

Panel administrasi berbasis web untuk **SIPELOR BEDAS** (Sistem Pemesanan Lapangan Olahraga DISPORA Kabupaten Bandung).

---

## 🚀 Cara Membuka

### Opsi 1 — Langsung di Browser (Paling Mudah)

Buka file `index.html` langsung di browser. Tidak perlu server!

```
website/admin/index.html
```

> **Demo Mode**: Login dengan `admin@demo.com` / `demo123`  
> (Tidak perlu Supabase — data menggunakan mock data)

### Opsi 2 — Via Laravel (Sudah Dikonfigurasi)

```bash
cd website/laravel-app
php artisan serve
# Buka: http://localhost:8000/admin
```

### Opsi 3 — Static Hosting

Deploy folder `website/admin/` ke Netlify, Vercel, atau server web mana pun.

---

## 🔑 Konfigurasi Supabase

Edit file `js/config.js`:

```js
const SIPELOR_ADMIN_CONFIG = {
  SUPABASE_URL:      'https://xxxx.supabase.co',
  SUPABASE_ANON_KEY: 'your-anon-key',
};
```

Kredensial dapat ditemukan di:  
**Supabase Dashboard → Project Settings → API**

---

## 📋 Fitur

| Halaman | Fitur |
|---------|-------|
| 📊 **Dashboard** | Statistik real-time, grafik pendapatan, pemesanan terbaru |
| 📋 **Pemesanan** | Approve/reject booking, verifikasi pembayaran, export CSV |
| 🏟️ **Lapangan** | CRUD lapangan, kelola fasilitas, ubah status |
| 👥 **Pengguna** | Daftar pengguna terdaftar |
| ⚙️ **Staff** | Manajemen tim dengan RBAC (Admin/Manager/Operator) |
| 📈 **Analitik** | Revenue 12 bulan, tren pemesanan, distribusi status |
| ⭐ **Review** | Moderasi ulasan pengguna |
| 📝 **Audit Log** | Rekam jejak semua aktivitas admin |

---

## 🏗️ Struktur File

```
admin/
├── index.html          ← SPA utama (entry point)
├── login.html          ← Halaman login admin
├── css/
│   └── admin.css       ← Semua styling dashboard
├── js/
│   ├── config.js       ← Konfigurasi Supabase
│   ├── api.js          ← Layer API (semua query Supabase)
│   ├── app.js          ← Router, Auth Guard, Shell, Utilities
│   └── views/
│       ├── dashboard.js
│       ├── bookings.js
│       ├── fields.js
│       ├── staff.js
│       ├── analytics.js
│       ├── reviews.js
│       ├── audit.js
│       └── users.js
└── README.md
```

---

## 🔒 Keamanan

- Login diperiksa terhadap tabel `profiles` di Supabase
- Hanya role `admin`, `superadmin`, `manager`, `operator` yang diizinkan
- Semua data diproteksi oleh **Row Level Security (RLS)** Supabase
- anon key aman diekspos di frontend — tidak memiliki akses bypass RLS

---

## 📦 Dependencies (via CDN — tidak perlu npm)

| Library | Versi | Kegunaan |
|---------|-------|----------|
| `@supabase/supabase-js` | v2 | Backend API |
| `chart.js` | v4 | Grafik & analitik |
| Google Fonts (Mulish) | — | Typography |
