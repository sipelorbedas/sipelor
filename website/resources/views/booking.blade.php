@extends('layouts.base')

@section('title', 'Booking Lapangan — SIPELOR BEDAS')
@section('description', 'Pesan lapangan olahraga di Sumedang. Pilih olahraga, lapangan, jadwal, dan lakukan pembayaran.')

@section('styles')
<style>
  .venue-list-img { width: 90px; height: 68px; border-radius: var(--radius-md); object-fit: cover; flex-shrink: 0; }
  .date-bar {
    display: flex; align-items: center; gap: 12px; padding: 14px 18px;
    background: var(--color-surface-2); border-radius: var(--radius-lg);
    border: 1.5px solid var(--color-border); margin-bottom: 20px;
  }
  .date-bar label { font-size: 0.8rem; font-weight: 700; color: var(--color-text-muted); text-transform: uppercase; letter-spacing: 0.5px; white-space: nowrap; }
  .date-bar input[type="date"] {
    flex: 1; background: transparent; border: none; color: var(--color-text);
    font-size: 0.95rem; font-family: var(--font-body); font-weight: 700; cursor: pointer; outline: none;
  }
  .date-bar input[type="date"]::-webkit-calendar-picker-indicator { filter: invert(1); cursor: pointer; width: 18px; height: 18px; }
  .date-bar-icon { font-size: 1.25rem; }
  .filter-bar { display: flex; align-items: center; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
  .filter-bar-label { font-size: 0.75rem; font-weight: 700; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.5px; }
  .filter-chip {
    padding: 5px 14px; border-radius: var(--radius-full); border: 1px solid var(--color-border);
    background: var(--color-glass); font-size: 0.75rem; font-weight: 700; color: var(--color-text-muted); cursor: pointer; transition: all var(--transition-fast);
  }
  .filter-chip:hover { border-color: var(--color-border-light); color: var(--color-text); }
  .filter-chip.active { background: rgba(255,88,0,0.15); border-color: var(--color-primary); color: var(--color-primary); }
  .timeslot { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 10px 6px; height: 60px; }
  .venue-count-badge {
    display: inline-flex; align-items: center; gap: 6px; padding: 4px 12px; border-radius: var(--radius-full);
    background: rgba(255,88,0,0.1); border: 1px solid rgba(255,88,0,0.2); font-size: 0.72rem; font-weight: 700; color: var(--color-primary); margin-bottom: 16px;
  }
</style>
@endsection

@section('content')

<!-- NAVBAR -->
<nav class="navbar scrolled">
  <div class="container navbar-inner">
    <a href="{{ route('home') }}" class="navbar-logo">
      <div class="navbar-logo-icon">SB</div>
      <span class="navbar-logo-text">SIPELOR <span>BEDAS</span></span>
    </a>
    <div class="navbar-nav">
      <a href="{{ route('home') }}" class="nav-link">Beranda</a>
      <a href="{{ route('booking') }}" class="nav-link active">Booking</a>
    </div>
    <div class="navbar-actions">
      <a href="{{ route('login') }}" class="btn btn-ghost btn-sm" id="nav-login-btn">Masuk</a>
      <div id="nav-user-menu" style="display:none;align-items:center;gap:10px">
        <span style="font-size:0.8rem;color:var(--color-text-muted)">👤 <span id="nav-user-name"></span></span>
        <button class="btn btn-ghost btn-sm" onclick="handleLogout()">Keluar</button>
      </div>
    </div>
    <div class="navbar-mobile-toggle" onclick="document.getElementById('mobile-menu-booking').classList.toggle('open')">
      <span></span><span></span><span></span>
    </div>
  </div>
</nav>
<div class="mobile-menu" id="mobile-menu-booking">
  <a href="{{ route('home') }}" class="nav-link">Beranda</a>
  <div class="mobile-menu-actions">
    <a href="{{ route('login') }}" class="btn btn-primary btn-full">Masuk / Daftar</a>
  </div>
</div>

<!-- BOOKING PAGE -->
<div class="booking-page">

  <!-- STEP INDICATOR HEADER -->
  <div class="booking-header">
    <div class="container">
      <h1 style="font-family:var(--font-display);font-size:1.75rem;margin-bottom:2px">
        Booking <span style="color:var(--color-primary)">Lapangan</span>
      </h1>
      <p style="color:var(--color-text-muted);font-size:0.8rem;margin-bottom:20px">Ikuti langkah-langkah di bawah</p>
      <div class="booking-steps">
        <div class="booking-step-item active">
          <div class="booking-step-num">1</div>
          <div class="booking-step-label">Olahraga</div>
        </div>
        <div class="booking-step-item">
          <div class="booking-step-num">2</div>
          <div class="booking-step-label">Lapangan</div>
        </div>
        <div class="booking-step-item">
          <div class="booking-step-num">3</div>
          <div class="booking-step-label">Jadwal</div>
        </div>
        <div class="booking-step-item">
          <div class="booking-step-num">4</div>
          <div class="booking-step-label">Konfirmasi</div>
        </div>
      </div>
    </div>
  </div>

  <!-- BOOKING CONTENT -->
  <div class="booking-content">
    <div class="container">
      <div class="booking-layout">

        <!-- MAIN PANELS -->
        <div class="booking-main">

          <!-- STEP 1: Sport Type -->
          <div class="booking-panel active" id="booking-panel-1">
            <div class="panel-title">⚽ Pilih Jenis Olahraga</div>
            <p style="color:var(--color-text-muted);font-size:0.875rem;margin-bottom:20px">
              Pilih olahraga yang ingin kamu mainkan untuk melihat lapangan yang tersedia.
            </p>
            <div class="sport-selector" id="sport-types-grid"></div>
            <button class="btn btn-primary btn-lg" id="btn-next-step1" style="margin-top:8px">
              Lanjut: Pilih Lapangan →
            </button>
          </div>

          <!-- STEP 2: Date + Venue -->
          <div class="booking-panel" id="booking-panel-2">
            <div class="panel-title">🏟️ Pilih Tanggal & Lapangan</div>
            <div class="date-bar">
              <span class="date-bar-icon">📅</span>
              <label for="booking-date-step2">Tanggal Bermain</label>
              <input type="date" id="booking-date-step2" class="booking-date-input" required>
            </div>
            <div class="filter-bar">
              <span class="filter-bar-label">Filter:</span>
              <div class="filter-chip active" data-filter="all" onclick="filterVenues('all', this)">Semua</div>
              <div class="filter-chip" data-filter="futsal" onclick="filterVenues('futsal', this)">⚽ Futsal</div>
              <div class="filter-chip" data-filter="badminton" onclick="filterVenues('badminton', this)">🏸 Badminton</div>
              <div class="filter-chip" data-filter="basketball" onclick="filterVenues('basketball', this)">🏀 Basketball</div>
              <div class="filter-chip" data-filter="volleyball" onclick="filterVenues('volleyball', this)">🏐 Voli</div>
            </div>
            <div id="venue-count-badge" class="venue-count-badge">🏟️ Menampilkan semua lapangan</div>
            <div class="venue-list" id="venue-list"></div>
            <div id="venue-selected-preview" style="margin-top:16px;display:none"></div>
            <div style="display:flex;gap:12px;margin-top:20px">
              <button class="btn btn-outline btn-lg" id="btn-back-step2">← Kembali</button>
              <button class="btn btn-primary btn-lg" id="btn-next-step2" style="flex:1">Lanjut: Pilih Jam →</button>
            </div>
          </div>

          <!-- STEP 3: Time Slot + Duration -->
          <div class="booking-panel" id="booking-panel-3">
            <div class="panel-title">⏰ Pilih Jam & Durasi</div>

            <div id="step3-info" style="margin-bottom:20px;padding:14px 18px;background:var(--color-surface);border-radius:var(--radius-lg);border:1px solid var(--color-border);display:flex;gap:12px;align-items:center;flex-wrap:wrap">
              <div style="font-size:1.5rem" id="step3-sport-icon">⚽</div>
              <div style="flex:1;min-width:0">
                <div style="font-weight:700;font-size:0.9rem" id="step3-venue-name">-</div>
                <div style="font-size:0.78rem;color:var(--color-text-muted)" id="step3-date-display">-</div>
              </div>
              <div>
                <div style="font-family:var(--font-display);font-size:1.25rem;color:var(--color-primary)" id="step3-price">-</div>
                <div style="font-size:0.65rem;color:var(--color-text-dim)">per jam</div>
              </div>
              <button class="btn btn-ghost btn-sm" onclick="goToStep(2)" style="font-size:0.75rem">✏️ Ganti</button>
            </div>

            <div style="margin-bottom:20px">
              <label style="display:block;font-size:0.8rem;font-weight:700;color:var(--color-text-muted);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px">
                📅 Tanggal Bermain
              </label>
              <div class="date-bar" style="margin-bottom:0">
                <span class="date-bar-icon">📅</span>
                <label for="booking-date-step3" style="white-space:nowrap">Pilih tanggal</label>
                <input type="date" id="booking-date-step3" class="booking-date-input" required>
              </div>
            </div>

            <div style="margin-bottom:20px">
              <label style="display:block;font-size:0.8rem;font-weight:700;color:var(--color-text-muted);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:10px">
                ⏰ Jam Mulai
              </label>
              <div class="timeslot-grid" id="timeslot-grid"></div>
              <div style="display:flex;gap:16px;font-size:0.72rem;color:var(--color-text-dim);margin-top:10px">
                <span style="display:flex;align-items:center;gap:4px"><span style="width:10px;height:10px;border-radius:2px;background:var(--color-surface-2);border:1px solid var(--color-border);display:inline-block"></span>Tersedia</span>
                <span style="display:flex;align-items:center;gap:4px"><span style="width:10px;height:10px;border-radius:2px;background:rgba(239,68,68,0.15);border:1px solid rgba(239,68,68,0.3);display:inline-block"></span>Penuh</span>
                <span style="display:flex;align-items:center;gap:4px"><span style="width:10px;height:10px;border-radius:2px;background:rgba(255,88,0,0.2);border:1px solid var(--color-primary);display:inline-block"></span>Dipilih</span>
              </div>
            </div>

            <div style="margin-bottom:24px">
              <label style="display:block;font-size:0.8rem;font-weight:700;color:var(--color-text-muted);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:10px">
                ⏱️ Durasi Bermain
              </label>
              <div class="duration-selector">
                <div class="duration-btn selected" data-hours="1">1 Jam</div>
                <div class="duration-btn" data-hours="2">2 Jam</div>
                <div class="duration-btn" data-hours="3">3 Jam</div>
                <div class="duration-btn" data-hours="4">4 Jam</div>
              </div>
              <div style="margin-top:8px;font-size:0.8rem;color:var(--color-text-muted)" id="duration-total-display"></div>
            </div>

            <div style="display:flex;gap:12px">
              <button class="btn btn-outline btn-lg" id="btn-back-step3">← Kembali</button>
              <button class="btn btn-primary btn-lg" id="btn-next-step3" style="flex:1">Lanjut: Konfirmasi →</button>
            </div>
          </div>

          <!-- STEP 4: Confirmation -->
          <div class="booking-panel" id="booking-panel-4">
            <div class="panel-title">✅ Konfirmasi Pesanan</div>

            <div style="background:var(--color-surface);border-radius:var(--radius-xl);border:1px solid var(--color-border);overflow:hidden;margin-bottom:20px">
              <div style="padding:16px 20px;background:linear-gradient(135deg,var(--color-surface-2),var(--color-surface));border-bottom:1px solid var(--color-border)">
                <div style="font-family:var(--font-display);font-size:1.1rem;letter-spacing:1px">DETAIL PESANAN</div>
              </div>
              <div style="padding:20px">
                <div class="payment-info-row"><span class="payment-info-label">Jenis Olahraga</span><span class="payment-info-value" id="confirm-sport">-</span></div>
                <div class="payment-info-row"><span class="payment-info-label">Lapangan</span><span class="payment-info-value" id="confirm-venue">-</span></div>
                <div class="payment-info-row"><span class="payment-info-label">Tanggal</span><span class="payment-info-value" id="confirm-date">-</span></div>
                <div class="payment-info-row"><span class="payment-info-label">Waktu</span><span class="payment-info-value" id="confirm-time">-</span></div>
                <div class="payment-info-row"><span class="payment-info-label">Durasi</span><span class="payment-info-value" id="confirm-duration">-</span></div>
                <div class="payment-info-row"><span class="payment-info-label">Harga/Jam</span><span class="payment-info-value" id="confirm-price">-</span></div>
                <div style="height:1px;background:var(--color-border);margin:12px 0"></div>
                <div class="payment-info-row">
                  <span class="payment-info-label" style="font-family:var(--font-display);font-size:1rem">TOTAL BAYAR</span>
                  <span class="payment-info-value total" id="confirm-total">Rp 0</span>
                </div>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label" for="booking-notes">Catatan (opsional)</label>
              <textarea id="booking-notes" class="form-control" placeholder="Contoh: Butuh pintu masuk tambahan, membawa 12 orang, dll..." rows="2" style="resize:vertical"></textarea>
            </div>

            <div style="padding:14px 16px;border-radius:var(--radius-md);background:rgba(70,143,234,0.08);border:1px solid rgba(70,143,234,0.2);margin-bottom:20px;font-size:0.82rem;line-height:1.6">
              <strong style="color:var(--color-secondary)">💳 Selanjutnya: Pembayaran</strong>
              <p style="color:var(--color-text-muted);margin-top:4px">
                Setelah konfirmasi, Anda akan mendapat <strong style="color:var(--color-text)">QR Code QRIS</strong> atau opsi transfer bank.
                Admin memverifikasi dalam <strong style="color:var(--color-warning)">1×24 jam</strong>.
              </p>
            </div>

            <div style="display:flex;gap:12px">
              <button class="btn btn-outline btn-lg" id="btn-back-step4">← Kembali</button>
              <button class="btn btn-primary btn-lg" id="btn-confirm-booking" style="flex:1">🎯 Konfirmasi & Lanjut Bayar</button>
            </div>
          </div>

        </div><!-- /booking-main -->

        <!-- SIDEBAR SUMMARY -->
        <div class="booking-summary">
          <div class="booking-summary-header">📋 Ringkasan Booking</div>
          <div class="booking-summary-body">
            <div class="summary-row"><span class="summary-label">Olahraga</span><span class="summary-value" id="summary-sport">-</span></div>
            <div class="summary-row"><span class="summary-label">Lapangan</span><span class="summary-value" id="summary-venue">-</span></div>
            <div class="summary-row"><span class="summary-label">Tanggal</span><span class="summary-value" id="summary-date">-</span></div>
            <div class="summary-row"><span class="summary-label">Waktu</span><span class="summary-value" id="summary-time">-</span></div>
            <div class="summary-row"><span class="summary-label">Durasi</span><span class="summary-value" id="summary-duration">-</span></div>
            <div class="summary-divider"></div>
            <div class="summary-row">
              <span class="summary-label summary-total-label">Total</span>
              <span class="summary-value summary-total-value" id="summary-total">Rp 0</span>
            </div>
          </div>
          <div class="booking-summary-footer">
            <div style="font-size:0.72rem;color:var(--color-text-dim);line-height:1.6;margin-bottom:10px">
              ⚡ Bayar via QRIS atau Transfer Bank setelah konfirmasi
            </div>
            <div style="display:flex;gap:6px;flex-wrap:wrap">
              <span style="padding:3px 10px;background:rgba(255,255,255,0.04);border:1px solid var(--color-border);border-radius:6px;font-size:0.62rem;color:var(--color-text-dim)">BRI</span>
              <span style="padding:3px 10px;background:rgba(255,255,255,0.04);border:1px solid var(--color-border);border-radius:6px;font-size:0.62rem;color:var(--color-text-dim)">Mandiri</span>
              <span style="padding:3px 10px;background:rgba(255,255,255,0.04);border:1px solid var(--color-border);border-radius:6px;font-size:0.62rem;color:var(--color-text-dim)">BNI</span>
              <span style="padding:3px 10px;background:rgba(255,255,255,0.04);border:1px solid var(--color-border);border-radius:6px;font-size:0.62rem;color:var(--color-text-dim)">QRIS</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</div><!-- /booking-page -->

@endsection

@section('scripts')
<script src="{{ asset('js/auth.js') }}"></script>
<script src="{{ asset('js/booking.js') }}"></script>
<script>
  // Filter venues quick switch (tetap di blade karena onclick inline)
  function filterVenues(type, el) {
    document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
    el.classList.add('active');
    const badge = document.getElementById('venue-count-badge');
    if (type === 'all') {
      renderVenueList(bookingState.sportType || null);
      const count = bookingState.sportType
        ? MOCK_FIELDS.filter(f => matchSportType(f.venueType, bookingState.sportType)).length
        : MOCK_FIELDS.length;
      badge.textContent = `🏟️ ${count} lapangan tersedia`;
    } else {
      renderVenueList(type);
      const count = MOCK_FIELDS.filter(f => matchSportType(f.venueType, type)).length;
      const sport = SPORT_TYPES.find(s => s.id === type);
      badge.textContent = `${sport?.icon || '🏟️'} ${count} lapangan ${sport?.name || type}`;
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    // Update durasi total display
    document.querySelectorAll('.duration-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const h = parseInt(btn.dataset.hours);
        const price = bookingState.field?.pricePerHour || 0;
        const el = document.getElementById('duration-total-display');
        if (el) {
          el.textContent = price > 0
            ? `${h} jam × ${formatRupiah(price)} = ${formatRupiah(price * h)}`
            : `Durasi: ${h} jam`;
        }
      });
    });

    // Set active filter chip sesuai sport dari URL
    const params = new URLSearchParams(window.location.search);
    const sport = params.get('sport');
    if (sport) {
      document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
      const chip = document.querySelector(`.filter-chip[data-filter="${sport}"]`);
      if (chip) chip.classList.add('active');
    }
  });
</script>
@endsection
