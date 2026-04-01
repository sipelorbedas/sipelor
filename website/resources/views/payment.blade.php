@extends('layouts.base')

@section('title', 'Pembayaran — SIPELOR BEDAS')
@section('description', 'Selesaikan pembayaran booking lapangan olahraga Anda di SIPELOR BEDAS.')

@section('styles')
<style>
  .pay-tab { padding: 10px 20px; border-radius: var(--radius-full); border: 1.5px solid var(--color-border); background: transparent; color: var(--color-text-muted); font-size: 0.8rem; font-weight: 700; cursor: pointer; transition: all var(--transition-fast); font-family: var(--font-body); }
  .pay-tab.active { background: rgba(255,88,0,0.15); border-color: var(--color-primary); color: var(--color-primary); }
  .pay-panel { display: none; }
  .pay-panel.active { display: block; }
  .bank-option { display: flex; align-items: center; gap: 10px; padding: 12px 16px; border-radius: var(--radius-md); border: 1.5px solid var(--color-border); cursor: pointer; transition: all var(--transition-fast); }
  .bank-option:hover { border-color: var(--color-border-light); }
  .bank-option.selected { border-color: var(--color-primary); background: rgba(255,88,0,0.06); }
  .bank-badge-big { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-weight: 900; font-size: 0.7rem; }
  .upload-area { border: 2px dashed var(--color-border); border-radius: var(--radius-lg); padding: 36px 20px; text-align: center; cursor: pointer; transition: all var(--transition-fast); }
  .upload-area:hover, .upload-area.dragging { border-color: var(--color-primary); background: rgba(255,88,0,0.04); }
  .payment-info-row { display: flex; justify-content: space-between; align-items: flex-start; padding: 8px 0; border-bottom: 1px solid var(--color-border); gap: 12px; }
  .payment-info-row:last-child { border-bottom: none; }
  .payment-info-label { font-size: 0.78rem; color: var(--color-text-muted); }
  .payment-info-value { font-size: 0.85rem; font-weight: 700; color: var(--color-text); text-align: right; }
  .payment-info-value.total { font-family: var(--font-display); font-size: 1.25rem; color: var(--color-primary); }
  @keyframes spin { to { transform: rotate(360deg); } }
</style>
@endsection

@section('content')

<nav class="navbar scrolled">
  <div class="container navbar-inner">
    <a href="{{ route('home') }}" class="navbar-logo">
      <div class="navbar-logo-icon">SB</div>
      <span class="navbar-logo-text">SIPELOR <span>BEDAS</span></span>
    </a>
    <div class="navbar-nav">
      <a href="{{ route('home') }}" class="nav-link">Beranda</a>
      <a href="{{ route('booking') }}" class="nav-link">Booking</a>
    </div>
    <div class="navbar-actions">
      <a href="{{ route('login') }}" class="btn btn-ghost btn-sm" id="nav-login-btn">Masuk</a>
      <div id="nav-user-menu" style="display:none;align-items:center;gap:10px">
        <span style="font-size:0.8rem;color:var(--color-text-muted)">👤 <span id="nav-user-name"></span></span>
        <button class="btn btn-ghost btn-sm" onclick="handleLogout()">Keluar</button>
      </div>
    </div>
  </div>
</nav>

<div style="min-height:100vh;padding:100px 0 60px">
  <div class="container" style="max-width:900px">

    <!-- Header -->
    <div style="text-align:center;margin-bottom:36px">
      <div class="section-label" style="margin:0 auto 12px">💳 Pembayaran</div>
      <h1 style="font-family:var(--font-display);font-size:2rem;letter-spacing:2px;margin-bottom:6px">
        SELESAIKAN <span style="color:var(--color-primary)">PEMBAYARAN</span>
      </h1>
      <p style="color:var(--color-text-muted);font-size:0.875rem">Kode Booking: <strong style="color:var(--color-text);font-family:var(--font-display)" id="pay-booking-code">-</strong></p>
      <div style="display:inline-flex;align-items:center;gap:8px;margin-top:12px;padding:8px 20px;border-radius:var(--radius-full);background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.25)">
        <span style="font-size:0.8rem;color:#ef4444">⏱️ Batas waktu pembayaran:</span>
        <strong style="font-family:var(--font-display);font-size:1rem;color:#ef4444" id="payment-countdown">15:00</strong>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:1fr 340px;gap:24px;align-items:start">

      <!-- Left: Payment methods -->
      <div>
        <!-- Amount card -->
        <div style="background:linear-gradient(135deg,var(--color-surface-2),var(--color-surface));border:1px solid var(--color-border);border-radius:var(--radius-xl);padding:24px;margin-bottom:20px">
          <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px">
            <div>
              <div style="font-size:0.72rem;color:var(--color-text-dim);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:4px">Total Pembayaran</div>
              <div style="font-family:var(--font-display);font-size:2.25rem;color:var(--color-primary);letter-spacing:1px" id="pay-amount-big">Rp 0</div>
              <div style="font-size:0.78rem;color:var(--color-text-muted);margin-top:4px" id="pay-venue-label">-</div>
            </div>
            <div style="text-align:right;font-size:0.78rem;color:var(--color-text-muted);line-height:1.8">
              <div id="pay-field">-</div>
              <div id="pay-date">-</div>
              <div id="pay-time">-</div>
            </div>
          </div>
        </div>

        <!-- Tabs -->
        <div style="display:flex;gap:10px;margin-bottom:20px;flex-wrap:wrap">
          <button class="pay-tab active" data-tab="qris">📱 QRIS</button>
          <button class="pay-tab" data-tab="bank">🏦 Transfer Bank</button>
          <button class="pay-tab" data-tab="ewallet">💚 E-Wallet</button>
        </div>

        <!-- QRIS Panel -->
        <div class="pay-panel active" id="pay-panel-qris">
          <div style="background:var(--color-surface);border-radius:var(--radius-xl);border:1px solid var(--color-border);padding:28px;text-align:center">
            <div style="font-weight:700;font-size:0.85rem;margin-bottom:6px;color:var(--color-text)">Scan QR Code QRIS</div>
            <div style="font-size:0.78rem;color:var(--color-text-muted);margin-bottom:20px">Kompatibel dengan semua m-banking & dompet digital</div>
            <div style="display:inline-block;padding:16px;background:#fff;border-radius:16px;margin-bottom:16px;box-shadow:0 4px 24px rgba(0,0,0,0.3)">
              <img
                src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=SIPELOR-BEDAS-PAYMENT-DEMO&bgcolor=ffffff&color=000000"
                alt="QR Code Pembayaran"
                style="width:200px;height:200px;display:block"
                onerror="this.parentElement.innerHTML='<div style=\'width:200px;height:200px;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#333\'><div style=\'font-size:4rem\'>📱</div><div style=\'font-size:0.7rem;margin-top:8px\'>QR CODE</div></div>'"
              >
            </div>
            <div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap;margin-bottom:16px">
              <span style="padding:4px 12px;border-radius:20px;background:rgba(255,255,255,0.05);border:1px solid var(--color-border);font-size:0.7rem;color:var(--color-text-muted)">GoPay</span>
              <span style="padding:4px 12px;border-radius:20px;background:rgba(255,255,255,0.05);border:1px solid var(--color-border);font-size:0.7rem;color:var(--color-text-muted)">OVO</span>
              <span style="padding:4px 12px;border-radius:20px;background:rgba(255,255,255,0.05);border:1px solid var(--color-border);font-size:0.7rem;color:var(--color-text-muted)">DANA</span>
              <span style="padding:4px 12px;border-radius:20px;background:rgba(255,255,255,0.05);border:1px solid var(--color-border);font-size:0.7rem;color:var(--color-text-muted)">ShopeePay</span>
              <span style="padding:4px 12px;border-radius:20px;background:rgba(255,255,255,0.05);border:1px solid var(--color-border);font-size:0.7rem;color:var(--color-text-muted)">LinkAja</span>
            </div>
            <div style="font-size:0.75rem;color:var(--color-text-dim);line-height:1.6">
              Buka aplikasi m-banking / dompet digital → Scan QR → Masukkan jumlah <strong style="color:var(--color-text)" id="pay-total">Rp 0</strong> → Konfirmasi
            </div>
          </div>
        </div>

        <!-- Bank Transfer Panel -->
        <div class="pay-panel" id="pay-panel-bank">
          <div style="margin-bottom:12px;font-size:0.78rem;color:var(--color-text-muted)">Pilih bank tujuan transfer:</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:20px">
            <div class="bank-option selected" data-bank="BRI">
              <div class="bank-badge-big" style="background:#1F4E9E;color:#fff">BRI</div>
              <div><div style="font-weight:700;font-size:0.82rem">Bank BRI</div><div style="font-size:0.7rem;color:var(--color-text-muted)">Rekening Tabungan</div></div>
            </div>
            <div class="bank-option" data-bank="MANDIRI">
              <div class="bank-badge-big" style="background:#003087;color:#FBBA00;letter-spacing:-1px">MNR</div>
              <div><div style="font-weight:700;font-size:0.82rem">Bank Mandiri</div><div style="font-size:0.7rem;color:var(--color-text-muted)">Rekening Tabungan</div></div>
            </div>
            <div class="bank-option" data-bank="BNI">
              <div class="bank-badge-big" style="background:#F15A29;color:#fff">BNI</div>
              <div><div style="font-weight:700;font-size:0.82rem">Bank BNI</div><div style="font-size:0.7rem;color:var(--color-text-muted)">Rekening Tabungan</div></div>
            </div>
          </div>
          <div style="padding:20px;background:var(--color-surface);border-radius:var(--radius-lg);border:1px solid var(--color-border);margin-bottom:16px">
            <div style="font-size:0.72rem;color:var(--color-text-dim);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:12px">Informasi Rekening</div>
            <div class="payment-info-row">
              <span class="payment-info-label">Bank</span>
              <span class="payment-info-value" id="bank-name">BRI</span>
            </div>
            <div class="payment-info-row">
              <span class="payment-info-label">No. Rekening</span>
              <span class="payment-info-value" id="bank-account-number">0895 8765 4321 001</span>
            </div>
            <div class="payment-info-row">
              <span class="payment-info-label">Atas Nama</span>
              <span class="payment-info-value" id="bank-account-name">SIPELOR BEDAS</span>
            </div>
            <div class="payment-info-row">
              <span class="payment-info-label">Nominal</span>
              <span class="payment-info-value total" id="pay-total-bank">-</span>
            </div>
          </div>
          <button id="copy-account-btn" class="btn btn-outline btn-full" style="margin-bottom:8px">📋 Salin Nomor Rekening</button>
          <p style="font-size:0.72rem;color:var(--color-text-dim);text-align:center">Transfer tepat sesuai jumlah di atas agar verifikasi lebih cepat</p>
        </div>

        <!-- E-Wallet Panel -->
        <div class="pay-panel" id="pay-panel-ewallet">
          <div style="padding:24px;background:var(--color-surface);border-radius:var(--radius-xl);border:1px solid var(--color-border);text-align:center">
            <div style="font-size:2.5rem;margin-bottom:12px">💚</div>
            <div style="font-weight:700;margin-bottom:4px">GoPay / OVO / DANA</div>
            <div style="font-size:0.78rem;color:var(--color-text-muted);margin-bottom:20px">Kirim ke nomor berikut:</div>
            <div style="font-family:var(--font-display);font-size:1.75rem;letter-spacing:2px;color:var(--color-text);margin-bottom:8px">0812-3456-7890</div>
            <div style="font-size:0.75rem;color:var(--color-text-muted);margin-bottom:20px">a.n. SIPELOR BEDAS</div>
            <button onclick="navigator.clipboard.writeText('081234567890').then(()=>showToast('Nomor disalin! 📋','success'))" class="btn btn-outline" style="font-size:0.8rem">📋 Salin Nomor</button>
          </div>
        </div>

        <!-- Upload Bukti -->
        <div style="margin-top:24px">
          <div style="font-size:0.8rem;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;color:var(--color-text-muted);margin-bottom:12px">📎 Upload Bukti Pembayaran</div>
          <div class="upload-area" id="upload-area">
            <div style="font-size:2.5rem;margin-bottom:8px">📸</div>
            <div style="font-weight:700;font-size:0.9rem;margin-bottom:4px">Klik atau drag & drop</div>
            <div style="font-size:0.75rem;color:var(--color-text-muted)">JPG, PNG, WebP — Max 5 MB</div>
            <input type="file" id="proof-upload" accept="image/*" style="display:none">
          </div>
          <div id="proof-preview" style="display:none;text-align:center;margin-top:12px"></div>
        </div>

        <button class="btn btn-primary btn-full btn-lg" id="btn-submit-payment" style="margin-top:20px;font-size:1rem">
          ✅ Konfirmasi Pembayaran
        </button>
        <p style="font-size:0.72rem;color:var(--color-text-dim);text-align:center;margin-top:10px;line-height:1.6">
          Admin akan memverifikasi pembayaran dalam <strong style="color:var(--color-warning)">1×24 jam</strong>. Notifikasi dikirim via email.
        </p>
      </div>

      <!-- Right: Order Summary -->
      <div style="position:sticky;top:90px">
        <div style="background:var(--color-surface);border:1px solid var(--color-border);border-radius:var(--radius-xl);overflow:hidden">
          <div style="padding:16px 20px;background:var(--color-surface-2);border-bottom:1px solid var(--color-border)">
            <div style="font-family:var(--font-display);font-size:0.95rem;letter-spacing:1px">RINGKASAN PESANAN</div>
          </div>
          <div style="padding:20px">
            <div class="payment-info-row"><span class="payment-info-label">Lapangan</span><span class="payment-info-value" id="pay-field-summary">-</span></div>
            <div class="payment-info-row"><span class="payment-info-label">Tanggal</span><span class="payment-info-value" id="pay-date-summary">-</span></div>
            <div class="payment-info-row"><span class="payment-info-label">Waktu</span><span class="payment-info-value" id="pay-time-summary">-</span></div>
            <div class="payment-info-row"><span class="payment-info-label">Durasi</span><span class="payment-info-value" id="pay-duration-summary">-</span></div>
            <div style="height:1px;background:var(--color-border);margin:12px 0"></div>
            <div class="payment-info-row">
              <span class="payment-info-label" style="font-family:var(--font-display);font-size:0.9rem">TOTAL</span>
              <span class="payment-info-value total" id="pay-total-summary">Rp 0</span>
            </div>
          </div>
        </div>

        <div style="margin-top:16px;padding:14px 16px;border-radius:var(--radius-md);background:rgba(34,197,94,0.08);border:1px solid rgba(34,197,94,0.2);font-size:0.78rem;line-height:1.7;color:var(--color-text-muted)">
          <strong style="color:#22c55e">🔒 Pembayaran Aman</strong><br>
          Data transaksi terenkripsi dan dilindungi. Upload hanya bukti pembayaran yang sah.
        </div>

        <a href="{{ route('booking') }}" style="display:block;text-align:center;margin-top:14px;font-size:0.78rem;color:var(--color-text-dim);transition:color 0.2s" onmouseover="this.style.color='var(--color-text)'" onmouseout="this.style.color='var(--color-text-dim)'">
          ← Kembali ke Booking
        </a>
      </div>
    </div>
  </div>
</div>

@endsection

@section('scripts')
<script src="{{ asset('js/auth.js') }}"></script>
<script src="{{ asset('js/payment.js') }}"></script>
<script>
  // Sync summary fields setelah DOM + payment.js siap
  document.addEventListener('DOMContentLoaded', () => {
    const syncIds = {
      'pay-field-summary':    'pay-field',
      'pay-date-summary':     'pay-date',
      'pay-time-summary':     'pay-time',
      'pay-duration-summary': 'pay-duration',
      'pay-total-summary':    'pay-amount-big',
      'pay-total-bank':       'pay-amount-big',
    };
    Object.entries(syncIds).forEach(([dest, src]) => {
      const srcEl  = document.getElementById(src);
      const destEl = document.getElementById(dest);
      if (srcEl && destEl) destEl.textContent = srcEl.textContent;
    });
  });
</script>
@endsection
