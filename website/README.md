## 📁 Struktur Proyek

```
website/
├── app/Http/Controllers/
│   ├── HomeController.php
│   ├── BookingController.php
│   ├── AuthController.php
│   └── PaymentController.php
├── config/
│   └── supabase.php
├── public/
│   ├── css/style.css          ← Semua style
│   └── js/
│       ├── helpers.js         ← Supabase init, toast, format util
│       ├── auth.js            ← Login & Register via Supabase
│       ├── booking.js         ← Wizard booking 4 langkah (bug fixed)
│       └── payment.js         ← Upload bukti bayar & countdown
├── resources/views/
│   ├── layouts/base.blade.php ← Master layout + inject config
│   ├── home.blade.php
│   ├── booking.blade.php
│   ├── auth/login.blade.php
│   └── payment.blade.php
├── routes/web.php
├── .env.example
└── composer.json
```