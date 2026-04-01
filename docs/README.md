# 📚 Documentation

Dokumentasi untuk SIPELOR BEDAS (Sistem Pemesanan Lapangan Olahraga Balai Diklat Aparatur Sipil Negara)

## 🔧 Database & Backend

### Chat Feature RLS Policy Fix
**File:** [SUPABASE_RLS_POLICY_FIX.md](./SUPABASE_RLS_POLICY_FIX.md)

**Masalah yang diperbaiki:**
- ❌ Chat admin dengan user tidak berfungsi
- ❌ Tidak bisa membuat booking (error saat submit)
- ❌ Profile screen: username dan email tidak tampil
- ❌ Error "infinite recursion detected in policy for relation 'profiles'"
- ❌ Daftar chat user tidak muncul di admin panel

**Cara memperbaiki:**
1. Baca file [SUPABASE_RLS_POLICY_FIX.md](./SUPABASE_RLS_POLICY_FIX.md) atau [QUICK_FIX_GUIDE.md](./QUICK_FIX_GUIDE.md)
2. Jalankan SQL script:
   - **First time:** [SUPABASE_SQL_SCRIPTS.sql](./SUPABASE_SQL_SCRIPTS.sql)
   - **If error "policy exists":** [SUPABASE_SQL_SCRIPTS_SAFE.sql](./SUPABASE_SQL_SCRIPTS_SAFE.sql) ⭐
3. Restart aplikasi

**Waktu:** ~10-15 menit

---

## 📖 Quick Links

| Dokumentasi | Deskripsi | Priority |
|------------|-----------|----------|
| [QUICK_FIX_GUIDE.md](./QUICK_FIX_GUIDE.md) | ⚡ **START HERE** - 5 minute fix | 🔴 URGENT |
| [SUPABASE_SQL_SCRIPTS_SAFE.sql](./SUPABASE_SQL_SCRIPTS_SAFE.sql) | ⭐ **RECOMMENDED** SQL script (idempotent) | 🔴 URGENT |
| [SUPABASE_SQL_SCRIPTS.sql](./SUPABASE_SQL_SCRIPTS.sql) | Alternative SQL script | 🟡 Optional |
| [SUPABASE_RLS_POLICY_FIX.md](./SUPABASE_RLS_POLICY_FIX.md) | Detailed fix guide | 🟢 Reference |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | Common errors & solutions | 🟢 Reference |

---

## 🚨 Known Issues & Fixes

### Issue: Database RLS Policy Errors (Chat, Booking, Profile)
**Status:** 🔴 Requires immediate fix  
**Error Message:**
```
PostgrestException: infinite recursion detected in policy for relation "profiles"
```

**Affected Features:**
- 🔴 Chat feature (tidak bisa kirim pesan)
- 🔴 Booking feature (tidak bisa create booking)
- 🔴 Profile screen (data tidak tampil lengkap)

**Solution:** Apply RLS policy fixes menggunakan [SUPABASE_RLS_POLICY_FIX.md](./SUPABASE_RLS_POLICY_FIX.md)

---

## 📋 SOP & Proses Bisnis

| Dokumen | Deskripsi | Priority |
|---------|-----------|----------|
| [SOP_SIPELOR_BEDAS.md](./SOP_SIPELOR_BEDAS.md) | 📋 **Standar Operasional Prosedur** — 17 SOP mencakup seluruh proses operasional | 🔵 Wajib Baca |
| [PROBIS_SIPELOR_BEDAS.md](./PROBIS_SIPELOR_BEDAS.md) | 🔄 **Proses Bisnis** — Alur bisnis end-to-end, swimlane, arsitektur keamanan, KPI & risiko | 🔵 Wajib Baca |
| [PROBIS_SIPELOR_BEDAS.drawio](./PROBIS_SIPELOR_BEDAS.drawio) | 🖼️ **Diagram Visio** — 7 halaman diagram visual (draw.io format, buka di diagrams.net) | 🔵 Wajib Baca |

---

## 📞 Support

Jika ada pertanyaan atau masalah:
1. Cek dokumentasi di folder `docs/`
2. Hubungi tim developer
3. Buat issue di repository

---

Last updated: 2026-03-03
