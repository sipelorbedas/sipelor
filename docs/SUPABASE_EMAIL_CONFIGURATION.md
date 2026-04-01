# 📧 Konfigurasi Email Supabase untuk SIPELOR

Panduan lengkap untuk mengkonfigurasi email verification dan password reset di Supabase agar tidak stuck di localhost.

## 🔴 Masalah Umum

Ketika membuka email verification atau reset password, button mengarah ke `localhost` bukan ke aplikasi mobile Anda.

**Penyebab:**
- Site URL di Supabase masih diset ke `http://localhost:3000`
- Redirect URLs tidak include deep link scheme aplikasi

## ✅ Solusi: Konfigurasi Supabase Project

### 1. Login ke Supabase Dashboard

Buka: https://app.supabase.com/

### 2. Pilih Project SIPELOR

Pilih project Anda dari dashboard.

### 3. Konfigurasi Authentication Settings

Masuk ke: **Authentication** → **URL Configuration**

#### A. Site URL

**PENTING:** Ubah dari localhost ke deep link scheme aplikasi

```
SEBELUM (❌ Salah):
http://localhost:3000

SESUDAH (✅ Benar):
sipelor://callback
```

**Catatan:** Site URL adalah URL default yang digunakan jika redirect URL tidak dispesifikasikan.

#### B. Redirect URLs

Tambahkan semua URL berikut ke daftar **Redirect URLs** (pisahkan dengan enter/newline):

```
sipelor://callback
sipelor://reset-password
sipelor://auth/callback
io.supabase.sipelor://login-callback
```

**Penjelasan:**
- `sipelor://callback` - Email verification
- `sipelor://reset-password` - Password reset
- `sipelor://auth/callback` - Authentication callback (magic link, OAuth)
- `io.supabase.sipelor://login-callback` - Legacy Supabase callback

#### Screenshot Contoh

```
┌─────────────────────────────────────────────────────┐
│ Authentication > URL Configuration                   │
├─────────────────────────────────────────────────────┤
│                                                      │
│ Site URL                                            │
│ ┌─────────────────────────────────────────────────┐ │
│ │ sipelor://callback                              │ │
│ └─────────────────────────────────────────────────┘ │
│                                                      │
│ Redirect URLs                                        │
│ ┌─────────────────────────────────────────────────┐ │
│ │ sipelor://callback                              │ │
│ │ sipelor://reset-password                        │ │
│ │ sipelor://auth/callback                         │ │
│ │ io.supabase.sipelor://login-callback            │ │
│ └─────────────────────────────────────────────────┘ │
│                                                      │
│ [Save] button                                        │
└─────────────────────────────────────────────────────┘
```

### 4. Email Template Configuration (Opsional)

Jika ingin customize email template lebih lanjut:

**Authentication** → **Email Templates**

#### A. Confirm Signup Template

Default template sudah bagus, tapi Anda bisa customize:

```html
<h2>Konfirmasi Email Anda</h2>

<p>Terima kasih sudah mendaftar di SIPELOR!</p>

<p>Klik tombol di bawah untuk verifikasi email Anda:</p>

<a href="{{ .ConfirmationURL }}">Verifikasi Email</a>

<p>Link ini akan expired dalam 24 jam.</p>

<p>Jika Anda tidak mendaftar, abaikan email ini.</p>
```

**PENTING:** Jangan hapus `{{ .ConfirmationURL }}` - ini adalah variable yang akan diganti otomatis oleh Supabase.

#### B. Reset Password Template

```html
<h2>Reset Password</h2>

<p>Anda menerima email ini karena ada permintaan reset password untuk akun SIPELOR Anda.</p>

<p>Klik tombol di bawah untuk reset password:</p>

<a href="{{ .ConfirmationURL }}">Reset Password</a>

<p>Link ini akan expired dalam 1 jam.</p>

<p>Jika Anda tidak meminta reset password, abaikan email ini.</p>
```

**PENTING:** Jangan hapus `{{ .ConfirmationURL }}` - ini akan otomatis berisi URL dengan scheme `sipelor://reset-password`.

### 5. Save Configuration

Klik **Save** untuk menyimpan perubahan.

## 🧪 Testing

### Test Email Verification

1. Buat akun baru di aplikasi
2. Cek email
3. Klik button "Verify Email"
4. Aplikasi akan terbuka otomatis (bukan browser dengan localhost)
5. Anda akan diarahkan ke halaman home setelah verifikasi berhasil

### Test Password Reset

1. Klik "Lupa Password" di aplikasi
2. Masukkan email
3. Cek email
4. Klik button "Reset Password"
5. Aplikasi akan terbuka otomatis
6. Anda akan diarahkan ke form reset password

## ❓ Troubleshooting

### Problem: Email masih mengarah ke localhost

**Solusi:**
1. Pastikan Site URL sudah diubah ke `sipelor://callback`
2. Pastikan Anda sudah klik **Save** di Supabase dashboard
3. Clear cache email (hapus email lama, kirim ulang)
4. Tunggu 1-2 menit untuk propagasi perubahan

### Problem: "Invalid redirect URL" error

**Solusi:**
1. Pastikan semua URL sudah ditambahkan ke **Redirect URLs**
2. Tidak boleh ada spasi atau karakter tambahan
3. Format harus persis: `sipelor://callback` (lowercase)

### Problem: Link expired

**Solusi:**
- Email verification: Link valid 24 jam
- Password reset: Link valid 1 jam
- Minta kirim ulang email jika sudah expired

### Problem: App tidak terbuka saat klik link

**Solusi:**

**Android:**
1. Pastikan deep link sudah terkonfigurasi di `android/app/src/main/AndroidManifest.xml`
2. Reinstall aplikasi
3. Test dengan command: `adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"`

**iOS:**
1. Pastikan URL scheme sudah terkonfigurasi di `ios/Runner/Info.plist`
2. Reinstall aplikasi

## 📱 Deep Link Configuration

Deep link sudah dikonfigurasi di:

### Android
File: `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    
    <data android:scheme="sipelor" android:host="callback" />
    <data android:scheme="sipelor" android:host="reset-password" />
    <data android:scheme="sipelor" android:host="auth" android:pathPrefix="/callback" />
</intent-filter>
```

### iOS
File: `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>sipelor</string>
        </array>
    </dict>
</array>
```

## 🔐 Security Notes

1. **NEVER** set redirect URL ke domain yang tidak Anda kontrol
2. **ALWAYS** validate deep link di aplikasi sebelum navigate
3. **USE** HTTPS untuk production web deployments
4. **LIMIT** redirect URLs hanya ke yang benar-benar dibutuhkan

## 📋 Checklist

Setup selesai jika semua ini sudah ✅:

- [ ] Site URL diubah dari localhost ke `sipelor://callback`
- [ ] Semua redirect URLs ditambahkan
- [ ] Configuration di-save di Supabase dashboard
- [ ] Test email verification berhasil buka app
- [ ] Test password reset berhasil buka app
- [ ] Deep link handler berjalan dengan baik
- [ ] User experience lancar tanpa stuck di browser

## 📞 Support

Jika masih ada masalah:

1. Check Supabase logs: **Authentication** → **Logs**
2. Check Flutter console untuk deep link errors
3. Test dengan `adb logcat` (Android) atau Xcode console (iOS)
4. Verify AndroidManifest.xml dan Info.plist configuration

---

**Last Updated:** 2026-01-28
**Version:** 1.0.0
