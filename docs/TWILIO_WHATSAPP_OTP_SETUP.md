# 📱 Twilio WhatsApp OTP — Setup & Template Guide
## SIPELOR BEDAS

---

## 1. Template Pesan WhatsApp (Untuk Disubmit ke Meta via Twilio)

Twilio mengirim OTP via WhatsApp **wajib menggunakan approved template** dari Meta.
Berikut template yang perlu disubmit:

---

### 📄 Template 1 — OTP Verifikasi (Disarankan)

**Template Name:** `sipelor_otp_verification`
**Category:** `AUTHENTICATION`
**Language:** `Indonesian (id)`

**Template Body:**
```
Kode verifikasi SIPELOR BEDAS Anda adalah: *{{1}}*

Kode ini berlaku selama 10 menit. Jangan bagikan kode ini kepada siapapun.

Jika Anda tidak melakukan pendaftaran, abaikan pesan ini.
```

**Variable:**
| No | Variable | Keterangan         | Contoh  |
|----|----------|--------------------|---------|
| 1  | `{{1}}`  | 6-digit OTP code   | `483921` |

---

### 📄 Template 2 — OTP Singkat (Alternatif)

**Template Name:** `sipelor_otp_short`
**Category:** `AUTHENTICATION`
**Language:** `Indonesian (id)`

**Template Body:**
```
{{1}} adalah kode OTP SIPELOR BEDAS Anda. Berlaku 10 menit. Jangan bagikan kode ini.
```

**Variable:**
| No | Variable | Keterangan         | Contoh  |
|----|----------|--------------------|---------|
| 1  | `{{1}}`  | 6-digit OTP code   | `483921` |

---

## 2. Cara Submit Template ke Twilio Console

1. Login ke [Twilio Console](https://console.twilio.com/)
2. Navigasi ke **Messaging → Content Template Builder**
3. Klik **Create new content template**
4. Isi form:
   - **Friendly Name:** `sipelor_otp_verification`
   - **Content Type:** `WhatsApp`
   - **Template Body:** *(copy dari template di atas)*
5. Klik **Save and Submit for WhatsApp Approval**
6. Tunggu approval dari Meta (biasanya **1–3 hari kerja**)

> ⚠️ Selama menunggu approval, gunakan **Twilio Sandbox** untuk testing.

---

## 3. Setup Twilio Sandbox (untuk Development/Testing)

### Langkah-langkah:

1. Buka [Twilio Console → Messaging → Try it out → Send a WhatsApp message](https://console.twilio.com/us1/develop/sms/try-it-out/whatsapp-learn)
2. Ikuti instruksi untuk join sandbox:
   - Kirim WhatsApp ke `+1 415 523 8886`
   - Dengan pesan: `join [kata-sandbox-anda]`
3. Catat **Sandbox Number** dan **Sandbox Keyword**

---

## 4. Konfigurasi Supabase untuk Menggunakan Twilio

### Di Supabase Dashboard:

1. Buka **Authentication → Providers → Phone**
2. Aktifkan **Enable Phone Provider**
3. Pilih **SMS Provider:** `Twilio`
4. Isi konfigurasi:

```
Account SID   : ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  ← dari Twilio Console
Auth Token    : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       ← dari Twilio Console
Message Service SID : MGxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  ← dari Messaging Service
Twilio Verify Service SID : (kosongkan jika pakai SMS langsung)
```

5. **Phone OTP Expiry:** `600` (10 menit)
6. **OTP Length:** `6`
7. Klik **Save**

---

## 5. Konfigurasi Twilio Messaging Service

1. Di Twilio Console → **Messaging → Services**
2. Klik **Create Messaging Service**
3. Isi:
   - **Name:** `SIPELOR BEDAS OTP`
   - **Use Case:** `Verify users with OTP`
4. Di tab **Sender Pool** → tambahkan **WhatsApp Sender**
5. Di tab **Integration** → aktifkan **Delivery Status Callbacks** (opsional)
6. Catat **Messaging Service SID** (`MGxxx...`)

---

## 6. Format Nomor Telepon

Pastikan nomor sudah dalam format **E.164** sebelum dikirim ke Supabase:

| Input User    | Format E.164    |
|---------------|-----------------|
| `081234567890` | `+6281234567890` |
| `6281234567890` | `+6281234567890` |
| `+6281234567890` | `+6281234567890` |

> ✅ Method `_formatPhone()` di `sign_up_screen.dart` sudah menangani konversi ini otomatis.

---

## 7. Checklist Konfigurasi

- [ ] Template WhatsApp submitted dan **approved** di Twilio Console
- [ ] Twilio Account SID & Auth Token tersedia
- [ ] Messaging Service dibuat dengan WhatsApp sender
- [ ] Phone Provider diaktifkan di Supabase Dashboard
- [ ] Twilio credentials diisi di Supabase Authentication settings
- [ ] **Email confirmation dinonaktifkan** di Supabase *(opsional, untuk flow OTP-only)*
- [ ] Test OTP berhasil diterima di WhatsApp

---

## 8. Test di Sandbox (Sebelum Production)

Kirim test manual via `curl`:

```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/ACxxx/Messages.json" \
  --data-urlencode "From=whatsapp:+14155238886" \
  --data-urlencode "To=whatsapp:+628xxxxxxxxxx" \
  --data-urlencode "Body=Kode verifikasi SIPELOR BEDAS Anda adalah: *123456*. Berlaku 10 menit." \
  -u ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:your_auth_token
```

---

## 9. Referensi

- [Twilio WhatsApp API Docs](https://www.twilio.com/docs/whatsapp)
- [Supabase Phone Auth with Twilio](https://supabase.com/docs/guides/auth/phone-login/twilio)
- [Twilio Content Template Builder](https://www.twilio.com/docs/content)
- [Meta WhatsApp Business Policy](https://www.whatsapp.com/legal/business-policy/)
