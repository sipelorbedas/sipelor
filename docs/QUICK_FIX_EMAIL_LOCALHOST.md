# 🚨 QUICK FIX: Email Membuka Browser (Bukan Aplikasi)

## 📸 Masalah yang Anda Alami
Button "Reset Password" atau "Verify Email" di email membuka **browser dengan layar blank hitam** (bukan membuka aplikasi).

Screenshot yang Anda lihat:
- Browser terbuka (google.com atau localhost)
- Layar hitam/blank
- Aplikasi tidak terbuka

## Solusi Cepat (5 Menit)

### 1. Buka Supabase Dashboard
https://app.supabase.com/

### 2. Pilih Project SIPELOR

### 3. Masuk ke Authentication Settings
**Authentication** → **URL Configuration**

### 4. Ubah Site URL
```
UBAH DARI:
http://localhost:3000

MENJADI:
sipelor://callback
```

### 5. Tambahkan Redirect URLs
Paste semua URL ini (satu per baris):
```
sipelor://callback
sipelor://reset-password
sipelor://auth/callback
io.supabase.sipelor://login-callback
```

### 6. SAVE! 
Klik tombol **Save** di bagian bawah halaman.

### 7. Test
1. Hapus email lama di inbox
2. Kirim ulang forgot password dari aplikasi
3. Buka email baru
4. Klik button reset password
5. ✅ Aplikasi akan terbuka!

## Screenshot

```
┌────────────────────────────────────────┐
│ Supabase Dashboard                      │
├────────────────────────────────────────┤
│ Project: SIPELOR                        │
│                                         │
│ Authentication > URL Configuration      │
│                                         │
│ Site URL:                              │
│ ┌────────────────────────────────────┐ │
│ │ sipelor://callback          [✓]   │ │
│ └────────────────────────────────────┘ │
│                                         │
│ Redirect URLs:                          │
│ ┌────────────────────────────────────┐ │
│ │ sipelor://callback                 │ │
│ │ sipelor://reset-password           │ │
│ │ sipelor://auth/callback            │ │
│ │ io.supabase.sipelor://login-...    │ │
│ └────────────────────────────────────┘ │
│                                         │
│              [SAVE]                     │
└────────────────────────────────────────┘
```

## Masih Error?

Jika masih ke localhost:
1. Pastikan sudah klik **SAVE**
2. Tunggu 1-2 menit
3. Kirim ulang email (email lama masih pakai config lama)
4. Pastikan tidak ada typo di URL

## Detail Lengkap
Baca: [SUPABASE_EMAIL_CONFIGURATION.md](SUPABASE_EMAIL_CONFIGURATION.md)

---
✅ Done! Email sekarang akan membuka aplikasi, bukan browser.
