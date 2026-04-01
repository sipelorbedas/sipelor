# 📧 Email Templates - SIPELOR BEDAS

> **Professional email templates untuk Supabase Auth dan automated notifications**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026

---

## 🎯 Overview

Dokumen ini berisi templates untuk semua email yang dikirim oleh sistem SIPELOR BEDAS, termasuk:
- Email verification
- Password reset
- Magic link (passwordless login)
- Booking notifications
- Automated reports
- Security alerts

---

## 🔧 Setup Supabase Email Templates

### Step 1: Access Email Templates

1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Authentication** → **Email Templates**

### Step 2: Configure SMTP (Optional but Recommended)

**Default**: Supabase uses built-in email service (limited)
**Production**: Setup custom SMTP for better delivery rates

**Recommended SMTP Providers:**
- **Resend** - Modern, developer-friendly
- **SendGrid** - Reliable, scalable
- **Amazon SES** - Cost-effective
- **Mailgun** - Feature-rich

**Configure in**: Settings → Project Settings → SMTP Settings

---

## 📨 Template 1: Email Verification (Confirm Email)

### Supabase Template Name: `Confirm signup`

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verifikasi Email - SIPELOR BEDAS</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
        }
        .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            color: #ffffff;
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .header p {
            color: #e0e7ff;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .content {
            padding: 40px 30px;
        }
        .content h2 {
            color: #1a202c;
            font-size: 22px;
            margin: 0 0 20px 0;
        }
        .content p {
            color: #4a5568;
            font-size: 16px;
            line-height: 1.6;
            margin: 0 0 20px 0;
        }
        .button {
            display: inline-block;
            padding: 14px 32px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff !important;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            transition: transform 0.2s;
        }
        .button:hover {
            transform: translateY(-2px);
        }
        .button-container {
            text-align: center;
            margin: 30px 0;
        }
        .divider {
            height: 1px;
            background-color: #e2e8f0;
            margin: 30px 0;
        }
        .alternative-link {
            background-color: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .alternative-link p {
            margin: 0 0 10px 0;
            font-size: 14px;
            color: #718096;
        }
        .alternative-link code {
            display: block;
            background-color: #edf2f7;
            padding: 12px;
            border-radius: 6px;
            font-size: 12px;
            word-break: break-all;
            color: #2d3748;
            font-family: 'Courier New', monospace;
        }
        .footer {
            background-color: #f7fafc;
            padding: 30px;
            text-align: center;
        }
        .footer p {
            color: #718096;
            font-size: 14px;
            margin: 5px 0;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        .security-notice {
            background-color: #fef5e7;
            border-left: 4px solid #f39c12;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .security-notice p {
            margin: 0;
            font-size: 14px;
            color: #7d6608;
        }
        @media only screen and (max-width: 600px) {
            .email-container {
                margin: 0;
                border-radius: 0;
            }
            .header {
                padding: 30px 20px;
            }
            .content {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <h1>🏟️ SIPELOR BEDAS</h1>
            <p>Sistem Pemesanan Lapangan Olahraga</p>
        </div>

        <!-- Content -->
        <div class="content">
            <h2>Selamat Datang di SIPELOR BEDAS! 🎉</h2>
            <p>Terima kasih telah mendaftar. Untuk mengaktifkan akun Anda dan mulai booking lapangan olahraga, silakan verifikasi email Anda dengan mengklik tombol di bawah ini:</p>

            <div class="button-container">
                <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=sipelor://callback" class="button">
                    ✓ Verifikasi Email Saya
                </a>
            </div>

            <div class="alternative-link">
                <p>Atau salin dan paste link ini ke browser Anda:</p>
                <code>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=sipelor://callback</code>
            </div>

            <div class="divider"></div>

            <p><strong>Kenapa perlu verifikasi?</strong></p>
            <ul style="color: #4a5568; font-size: 15px; line-height: 1.6;">
                <li>Memastikan email Anda valid</li>
                <li>Keamanan akun Anda</li>
                <li>Menerima notifikasi booking</li>
                <li>Reset password jika lupa</li>
            </ul>

            <div class="security-notice">
                <p>
                    <strong>⚠️ Catatan Keamanan:</strong> Link verifikasi ini akan kadaluarsa dalam 24 jam. 
                    Jika Anda tidak mendaftar di SIPELOR BEDAS, abaikan email ini.
                </p>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>SIPELOR BEDAS</strong></p>
            <p>DISPORA Kabupaten Bandung</p>
            <p style="margin-top: 15px;">
                <a href="mailto:support@sipelor-bedas.com">Butuh bantuan?</a> | 
                <a href="https://sipelor-bedas.com/privacy">Privacy Policy</a>
            </p>
            <p style="margin-top: 15px; font-size: 12px; color: #a0aec0;">
                © 2026 DISPORA Kabupaten Bandung. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 🔐 Template 2: Password Reset (Magic Link)

### Supabase Template Name: `Reset Password`

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password - SIPELOR BEDAS</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
        }
        .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            color: #ffffff;
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .header p {
            color: #ffe5e9;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .content {
            padding: 40px 30px;
        }
        .content h2 {
            color: #1a202c;
            font-size: 22px;
            margin: 0 0 20px 0;
        }
        .content p {
            color: #4a5568;
            font-size: 16px;
            line-height: 1.6;
            margin: 0 0 20px 0;
        }
        .button {
            display: inline-block;
            padding: 14px 32px;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: #ffffff !important;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
        }
        .button-container {
            text-align: center;
            margin: 30px 0;
        }
        .divider {
            height: 1px;
            background-color: #e2e8f0;
            margin: 30px 0;
        }
        .warning-box {
            background-color: #fff5f5;
            border-left: 4px solid #f56565;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .warning-box p {
            margin: 0;
            color: #742a2a;
            font-size: 15px;
        }
        .info-box {
            background-color: #ebf8ff;
            border-left: 4px solid #4299e1;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .info-box p {
            margin: 0;
            color: #2c5282;
            font-size: 14px;
        }
        .alternative-link {
            background-color: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .alternative-link p {
            margin: 0 0 10px 0;
            font-size: 14px;
            color: #718096;
        }
        .alternative-link code {
            display: block;
            background-color: #edf2f7;
            padding: 12px;
            border-radius: 6px;
            font-size: 12px;
            word-break: break-all;
            color: #2d3748;
            font-family: 'Courier New', monospace;
        }
        .footer {
            background-color: #f7fafc;
            padding: 30px;
            text-align: center;
        }
        .footer p {
            color: #718096;
            font-size: 14px;
            margin: 5px 0;
        }
        .footer a {
            color: #f5576c;
            text-decoration: none;
        }
        @media only screen and (max-width: 600px) {
            .email-container {
                margin: 0;
                border-radius: 0;
            }
            .header, .content {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <h1>🔐 Reset Password</h1>
            <p>SIPELOR BEDAS</p>
        </div>

        <!-- Content -->
        <div class="content">
            <h2>Permintaan Reset Password</h2>
            <p>Kami menerima permintaan untuk mereset password akun Anda. Jika Anda yang melakukan permintaan ini, klik tombol di bawah untuk membuat password baru:</p>

            <div class="button-container">
                <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=sipelor://reset-password" class="button">
                    🔑 Reset Password Saya
                </a>
            </div>

            <div class="alternative-link">
                <p>Atau salin dan paste link ini ke browser Anda:</p>
                <code>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=recovery&redirect_to=sipelor://reset-password</code>
            </div>

            <div class="info-box">
                <p><strong>ℹ️ Link ini akan kadaluarsa dalam 1 jam</strong> untuk keamanan akun Anda.</p>
            </div>

            <div class="divider"></div>

            <div class="warning-box">
                <p><strong>⚠️ PENTING:</strong></p>
                <ul style="margin: 10px 0 0 0; padding-left: 20px;">
                    <li>Jika Anda TIDAK meminta reset password, <strong>abaikan email ini</strong></li>
                    <li>Password Anda tetap aman dan tidak berubah</li>
                    <li>Jangan bagikan link ini ke siapapun</li>
                    <li>Hubungi kami jika mencurigakan: <a href="mailto:security@sipelor-bedas.com" style="color: #f5576c;">security@sipelor-bedas.com</a></li>
                </ul>
            </div>

            <p style="margin-top: 30px; font-size: 14px; color: #718096;">
                <strong>Tips keamanan password:</strong><br>
                ✓ Minimal 8 karakter<br>
                ✓ Kombinasi huruf besar & kecil<br>
                ✓ Sertakan angka dan simbol<br>
                ✓ Jangan gunakan password yang sama dengan website lain
            </p>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>SIPELOR BEDAS</strong></p>
            <p>DISPORA Kabupaten Bandung</p>
            <p style="margin-top: 15px;">
                <a href="mailto:support@sipelor-bedas.com">Butuh bantuan?</a> | 
                <a href="https://sipelor-bedas.com/security">Security Center</a>
            </p>
            <p style="margin-top: 15px; font-size: 12px; color: #a0aec0;">
                © 2026 DISPORA Kabupaten Bandung. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 🪄 Template 2B: Magic Link (Passwordless Login)

### Supabase Template Name: `Magic Link`

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Magic Link - SIPELOR BEDAS</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
        }
        .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            color: #ffffff;
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .header p {
            color: #e0e7ff;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .content {
            padding: 40px 30px;
        }
        .content h2 {
            color: #1a202c;
            font-size: 22px;
            margin: 0 0 20px 0;
        }
        .content p {
            color: #4a5568;
            font-size: 16px;
            line-height: 1.6;
            margin: 0 0 20px 0;
        }
        .button {
            display: inline-block;
            padding: 14px 32px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff !important;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
        }
        .button-container {
            text-align: center;
            margin: 30px 0;
        }
        .divider {
            height: 1px;
            background-color: #e2e8f0;
            margin: 30px 0;
        }
        .info-box {
            background-color: #ebf8ff;
            border-left: 4px solid #4299e1;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .info-box p {
            margin: 0;
            color: #2c5282;
            font-size: 14px;
        }
        .alternative-link {
            background-color: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .alternative-link p {
            margin: 0 0 10px 0;
            font-size: 14px;
            color: #718096;
        }
        .alternative-link code {
            display: block;
            background-color: #edf2f7;
            padding: 12px;
            border-radius: 6px;
            font-size: 12px;
            word-break: break-all;
            color: #2d3748;
            font-family: 'Courier New', monospace;
        }
        .footer {
            background-color: #f7fafc;
            padding: 30px;
            text-align: center;
        }
        .footer p {
            color: #718096;
            font-size: 14px;
            margin: 5px 0;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        .security-note {
            background-color: #fffbeb;
            border-left: 4px solid #f59e0b;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .security-note p {
            margin: 0;
            color: #78350f;
            font-size: 14px;
        }
        @media only screen and (max-width: 600px) {
            .email-container {
                margin: 0;
                border-radius: 0;
            }
            .header, .content {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <h1>🪄 Magic Link Login</h1>
            <p>SIPELOR BEDAS</p>
        </div>

        <!-- Content -->
        <div class="content">
            <h2>Login Tanpa Password</h2>
            <p>Seseorang (semoga Anda!) meminta link login untuk akun SIPELOR BEDAS Anda. Klik tombol di bawah untuk login secara otomatis:</p>

            <div class="button-container">
                <a href="{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=magiclink&redirect_to=sipelor://callback" class="button">
                    🚀 Login ke SIPELOR BEDAS
                </a>
            </div>

            <div class="alternative-link">
                <p>Atau salin dan paste link ini ke browser Anda:</p>
                <code>{{ .SiteURL }}/auth/v1/verify?token={{ .TokenHash }}&type=magiclink&redirect_to=sipelor://callback</code>
            </div>

            <div class="info-box">
                <p><strong>ℹ️ Link ini akan kadaluarsa dalam 1 jam</strong> dan hanya bisa digunakan sekali untuk keamanan akun Anda.</p>
            </div>

            <div class="divider"></div>

            <div class="security-note">
                <p><strong>🔒 Catatan Keamanan:</strong></p>
                <ul style="margin: 10px 0 0 0; padding-left: 20px;">
                    <li>Jika Anda TIDAK meminta login, <strong>abaikan email ini</strong></li>
                    <li>Akun Anda tetap aman</li>
                    <li>Jangan bagikan link ini ke siapapun</li>
                    <li>Link ini hanya untuk sekali pakai</li>
                </ul>
            </div>

            <p style="margin-top: 30px; font-size: 14px; color: #718096;">
                <strong>💡 Tentang Magic Link:</strong><br>
                Magic Link adalah cara aman untuk login tanpa password. Anda hanya perlu klik link di email untuk masuk ke akun Anda.
            </p>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>SIPELOR BEDAS</strong></p>
            <p>DISPORA Kabupaten Bandung</p>
            <p style="margin-top: 15px;">
                <a href="mailto:support@sipelor-bedas.com">Butuh bantuan?</a> | 
                <a href="https://sipelor-bedas.com">Website</a>
            </p>
            <p style="margin-top: 15px; font-size: 12px; color: #a0aec0;">
                © 2026 DISPORA Kabupaten Bandung. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 🎫 Template 3: Booking Approved Notification

### For Automated Reports Service

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Disetujui - SIPELOR BEDAS</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
        }
        .email-container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            color: #ffffff;
            margin: 0;
            font-size: 32px;
            font-weight: 700;
        }
        .header p {
            color: #d4ffd9;
            margin: 10px 0 0 0;
            font-size: 18px;
        }
        .content {
            padding: 40px 30px;
        }
        .success-icon {
            text-align: center;
            font-size: 64px;
            margin: 20px 0;
        }
        .content h2 {
            color: #1a202c;
            font-size: 24px;
            margin: 0 0 20px 0;
            text-align: center;
        }
        .content p {
            color: #4a5568;
            font-size: 16px;
            line-height: 1.6;
            margin: 0 0 20px 0;
        }
        .booking-details {
            background-color: #f7fafc;
            padding: 25px;
            border-radius: 10px;
            margin: 30px 0;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            color: #718096;
            font-weight: 600;
            font-size: 14px;
        }
        .detail-value {
            color: #2d3748;
            font-weight: 700;
            font-size: 14px;
            text-align: right;
        }
        .price-total {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            font-size: 18px;
            font-weight: 700;
            margin: 20px 0;
        }
        .button {
            display: inline-block;
            padding: 16px 40px;
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            color: #ffffff !important;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 700;
            font-size: 18px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(17, 153, 142, 0.3);
        }
        .button-container {
            text-align: center;
            margin: 30px 0;
        }
        .info-box {
            background-color: #ebf8ff;
            border-left: 4px solid #4299e1;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .info-box p {
            margin: 0;
            color: #2c5282;
            font-size: 15px;
        }
        .footer {
            background-color: #f7fafc;
            padding: 30px;
            text-align: center;
        }
        .footer p {
            color: #718096;
            font-size: 14px;
            margin: 5px 0;
        }
        .footer a {
            color: #11998e;
            text-decoration: none;
        }
        @media only screen and (max-width: 600px) {
            .email-container {
                margin: 0;
                border-radius: 0;
            }
            .detail-row {
                flex-direction: column;
            }
            .detail-value {
                text-align: left;
                margin-top: 5px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <h1>✓ Booking Disetujui!</h1>
            <p>E-Ticket Sudah Siap</p>
        </div>

        <!-- Content -->
        <div class="content">
            <div class="success-icon">🎉</div>
            <h2>Selamat! Pembayaran Anda Diverifikasi</h2>
            <p>Halo <strong>{{user_name}}</strong>,</p>
            <p>Kami dengan senang hati memberitahukan bahwa pembayaran Anda telah diverifikasi dan booking Anda telah <strong>DISETUJUI</strong>!</p>

            <div class="booking-details">
                <div class="detail-row">
                    <span class="detail-label">🏟️ Venue</span>
                    <span class="detail-value">{{venue_name}}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">🎯 Lapangan</span>
                    <span class="detail-value">{{field_name}}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">📅 Tanggal</span>
                    <span class="detail-value">{{booking_date}}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">⏰ Waktu</span>
                    <span class="detail-value">{{start_time}} - {{end_time}}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">🎫 Booking ID</span>
                    <span class="detail-value">{{booking_id}}</span>
                </div>
            </div>

            <div class="price-total">
                💰 Total Dibayar: Rp {{total_price}}
            </div>

            <div class="button-container">
                <a href="{{eticket_url}}" class="button">
                    📲 Lihat E-Ticket Saya
                </a>
            </div>

            <div class="info-box">
                <p><strong>📱 Cara Menggunakan E-Ticket:</strong></p>
                <ol style="margin: 10px 0 0 0; padding-left: 20px; color: #2c5282;">
                    <li>Buka E-ticket melalui link di atas atau dari menu "Orders"</li>
                    <li>Tunjukkan QR code kepada petugas di venue</li>
                    <li>QR code akan di-scan untuk verifikasi</li>
                    <li>Selamat bermain! 🏀⚽🏸</li>
                </ol>
            </div>

            <p style="margin-top: 30px; font-size: 14px; color: #718096;">
                <strong>Catatan Penting:</strong><br>
                • Datang 15 menit sebelum waktu booking<br>
                • Bawa E-ticket (screenshot atau tampilkan di app)<br>
                • Hubungi kami jika ada pertanyaan
            </p>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>SIPELOR BEDAS</strong></p>
            <p>DISPORA Kabupaten Bandung</p>
            <p style="margin-top: 15px;">
                <a href="mailto:support@sipelor-bedas.com">Butuh bantuan?</a> | 
                <a href="https://sipelor-bedas.com/bookings">Lihat Booking Saya</a>
            </p>
            <p style="margin-top: 15px; font-size: 12px; color: #a0aec0;">
                © 2026 DISPORA Kabupaten Bandung. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 📊 Template 4: Revenue Report (Weekly/Monthly)

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laporan Pendapatan - SIPELOR BEDAS</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
        }
        .email-container {
            max-width: 700px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            color: #ffffff;
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }
        .header p {
            color: #d6eaf8;
            margin: 10px 0 0 0;
            font-size: 16px;
        }
        .content {
            padding: 40px 30px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
            margin: 30px 0;
        }
        .stat-card {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            border: 2px solid #e9ecef;
        }
        .stat-label {
            color: #6c757d;
            font-size: 13px;
            font-weight: 600;
            text-transform: uppercase;
            margin-bottom: 8px;
        }
        .stat-value {
            color: #212529;
            font-size: 28px;
            font-weight: 700;
        }
        .stat-value.highlight {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .table-container {
            overflow-x: auto;
            margin: 30px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background-color: white;
        }
        th {
            background-color: #2c3e50;
            color: white;
            padding: 12px;
            text-align: left;
            font-size: 13px;
            font-weight: 600;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
            font-size: 14px;
            color: #4a5568;
        }
        tr:hover {
            background-color: #f7fafc;
        }
        .footer {
            background-color: #f7fafc;
            padding: 30px;
            text-align: center;
        }
        .footer p {
            color: #718096;
            font-size: 14px;
            margin: 5px 0;
        }
        @media only screen and (max-width: 600px) {
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <h1>📊 Laporan Pendapatan</h1>
            <p>{{report_period}} - SIPELOR BEDAS</p>
        </div>

        <!-- Content -->
        <div class="content">
            <h2 style="color: #1a202c; margin: 0 0 10px 0;">Ringkasan Pendapatan</h2>
            <p style="color: #718096; margin: 0 0 30px 0;">Periode: {{start_date}} - {{end_date}}</p>

            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Total Pendapatan</div>
                    <div class="stat-value highlight">Rp {{total_revenue}}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Total Booking</div>
                    <div class="stat-value">{{total_bookings}}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Booking Confirmed</div>
                    <div class="stat-value">{{confirmed_bookings}}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Conversion Rate</div>
                    <div class="stat-value">{{conversion_rate}}%</div>
                </div>
            </div>

            <h3 style="color: #1a202c; margin: 40px 0 20px 0;">Pendapatan per Jenis Lapangan</h3>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Jenis Lapangan</th>
                            <th>Total Booking</th>
                            <th>Pendapatan</th>
                            <th>Kontribusi</th>
                        </tr>
                    </thead>
                    <tbody>
                        {{#each venue_types}}
                        <tr>
                            <td><strong>{{this.name}}</strong></td>
                            <td>{{this.bookings}}</td>
                            <td><strong>Rp {{this.revenue}}</strong></td>
                            <td>{{this.percentage}}%</td>
                        </tr>
                        {{/each}}
                    </tbody>
                </table>
            </div>

            <p style="margin-top: 40px; font-size: 14px; color: #718096;">
                Laporan lengkap dapat diakses melalui dashboard admin: <a href="{{dashboard_url}}" style="color: #3498db;">Admin Dashboard</a>
            </p>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>SIPELOR BEDAS - Admin Reports</strong></p>
            <p>DISPORA Kabupaten Bandung</p>
            <p style="margin-top: 15px; font-size: 12px; color: #a0aec0;">
                Email ini dikirim secara otomatis. © 2026 DISPORA Kabupaten Bandung.
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 🔧 Implementation Steps

### Step 1: Update Supabase Templates

1. Go to Supabase Dashboard → Authentication → Email Templates
2. Select each template and replace with corresponding template:
   - `Confirm signup` → Copy **Template 1** (Email Verification)
   - `Reset Password` → Copy **Template 2** (Password Reset)
   - `Magic Link` → Copy **Template 2B** (Magic Link - optional)
3. Save each template

### Step 2: Test Email Templates

```sql
-- Test verification email
SELECT auth.send_confirmation_email('test@example.com');

-- Test password reset
SELECT auth.send_password_reset_email('test@example.com');
```

### Step 3: Customize Variables

Replace these variables dengan data actual:
- `{{user_name}}` - User's full name
- `{{venue_name}}` - Venue name
- `{{booking_date}}` - Formatted date
- `{{total_price}}` - Formatted price
- `{{eticket_url}}` - Deep link to E-ticket

---

## 📱 Deep Link Configuration

Update email templates to use deep links:

```
https://yourapp.com/reset-password?token={{.Token}}
↓ Change to ↓
sipelor://reset-password?token={{.Token}}
```

See `DEEP_LINKS_CONFIGURATION.md` for full setup.

---

## ✅ Testing Checklist

- [ ] Verification email sent and received
- [ ] Password reset email works
- [ ] Magic link email works (optional)
- [ ] Links open app correctly
- [ ] Email renders on Gmail
- [ ] Email renders on Outlook
- [ ] Email renders on mobile
- [ ] Images load correctly
- [ ] Responsive design works
- [ ] Links not broken
- [ ] SPAM score checked

---

**Last Updated**: 28 Januari 2026  
**Maintained By**: Development Team
