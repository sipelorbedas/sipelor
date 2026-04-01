// =============================================
// SIPELOR BEDAS — Payment Handler
// =============================================

let paymentTimer = null;
let paymentSeconds = 15 * 60; // 15 menit

document.addEventListener('DOMContentLoaded', () => {
  const params  = new URLSearchParams(window.location.search);
  const booking = {
    booking_code: params.get('booking_code') || ('SPL-' + Date.now()),
    field:        params.get('field')   || localStorage.getItem('sipelor_booking_field') || 'Lapangan Futsal A',
    date:         params.get('date')    || new Date().toISOString().split('T')[0],
    time:         params.get('time')    || '08:00 – 09:00',
    duration:     params.get('duration') || '1',
    total:        parseFloat(params.get('total') || '150000'),
  };

  // Isi UI
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('pay-booking-code', booking.booking_code);
  set('pay-field',        booking.field);
  set('pay-date',         formatDateID(booking.date));
  set('pay-time',         booking.time);
  set('pay-duration',     booking.duration + ' jam');
  set('pay-total',        formatRupiah(booking.total));
  set('pay-amount-big',   formatRupiah(booking.total));
  set('pay-venue-label',  `${booking.field} · ${booking.duration} Jam`);

  // Tab metode pembayaran
  document.querySelectorAll('.pay-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.pay-tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.pay-panel').forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById('pay-panel-' + tab.dataset.tab)?.classList.add('active');
    });
  });

  // Bank selector
  document.querySelectorAll('.bank-option').forEach(opt => {
    opt.addEventListener('click', () => {
      document.querySelectorAll('.bank-option').forEach(o => o.classList.remove('selected'));
      opt.classList.add('selected');
      const bankId  = opt.dataset.bank;
      const bankCfg = SIPELOR_CONFIG?.PAYMENT?.[bankId];
      if (bankCfg) {
        const nameEl = document.getElementById('bank-account-name');
        const numEl  = document.getElementById('bank-account-number');
        const bankEl = document.getElementById('bank-name');
        if (nameEl) nameEl.textContent = bankCfg.account_name;
        if (numEl)  numEl.textContent  = bankCfg.account_number;
        if (bankEl) bankEl.textContent = bankCfg.bank;
      }
    });
  });

  // Copy rekening
  document.getElementById('copy-account-btn')?.addEventListener('click', () => {
    const num = document.getElementById('bank-account-number')?.textContent?.replace(/\s/g, '');
    if (num) {
      navigator.clipboard.writeText(num)
        .then(() => showToast('Nomor rekening disalin! 📋', 'success'))
        .catch(() => showToast('Gagal menyalin. Salin manual.', 'error'));
    }
  });

  // Upload bukti bayar
  const uploadInput = document.getElementById('proof-upload');
  const uploadArea  = document.getElementById('upload-area');
  if (uploadInput && uploadArea) {
    uploadArea.addEventListener('click', () => uploadInput.click());
    uploadArea.addEventListener('dragover', (e) => { e.preventDefault(); uploadArea.classList.add('dragging'); });
    uploadArea.addEventListener('dragleave', ()  => uploadArea.classList.remove('dragging'));
    uploadArea.addEventListener('drop', (e) => {
      e.preventDefault();
      uploadArea.classList.remove('dragging');
      const file = e.dataTransfer.files[0];
      if (file) handleProofFile(file);
    });
    uploadInput.addEventListener('change', () => {
      if (uploadInput.files[0]) handleProofFile(uploadInput.files[0]);
    });
  }

  document.getElementById('btn-submit-payment')?.addEventListener('click', handleSubmitPayment);

  // Start timer
  startPaymentTimer();
  updateNavbarAuth();
});

function handleProofFile(file) {
  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (!allowed.includes(file.type)) {
    showToast('Format file tidak didukung. Gunakan JPG, PNG, atau WebP.', 'error');
    return;
  }
  if (file.size > 5 * 1024 * 1024) {
    showToast('Ukuran file maksimal 5 MB.', 'error');
    return;
  }
  const reader  = new FileReader();
  reader.onload = (e) => {
    const preview = document.getElementById('proof-preview');
    const area    = document.getElementById('upload-area');
    if (preview) {
      preview.innerHTML = `
        <div style="position:relative;display:inline-block">
          <img src="${e.target.result}" alt="Bukti Bayar" style="max-width:100%;max-height:240px;border-radius:10px;object-fit:contain">
          <button onclick="clearProof()" style="position:absolute;top:-8px;right:-8px;width:26px;height:26px;border-radius:50%;background:var(--color-error,#ef4444);border:none;color:#fff;font-size:0.9rem;cursor:pointer;display:flex;align-items:center;justify-content:center">✕</button>
        </div>
        <div style="margin-top:10px;font-size:0.8rem;color:var(--color-success,#22c55e);font-weight:700">✅ ${file.name} (${(file.size/1024).toFixed(0)} KB)</div>
      `;
      preview.style.display = 'block';
      if (area) area.style.display = 'none';
    }
  };
  reader.readAsDataURL(file);
}

function clearProof() {
  const preview = document.getElementById('proof-preview');
  const area    = document.getElementById('upload-area');
  const input   = document.getElementById('proof-upload');
  if (preview) { preview.innerHTML = ''; preview.style.display = 'none'; }
  if (area)    area.style.display = 'block';
  if (input)   input.value = '';
}

async function handleSubmitPayment() {
  const proof = document.getElementById('proof-upload')?.files?.[0];
  if (!proof) {
    showToast('Upload bukti pembayaran terlebih dahulu!', 'error');
    return;
  }
  const btn = document.getElementById('btn-submit-payment');
  if (btn) {
    btn.disabled = true;
    btn.innerHTML = '<span style="display:inline-block;width:16px;height:16px;border:2px solid rgba(255,255,255,0.3);border-top-color:#fff;border-radius:50%;animation:spin 0.8s linear infinite;vertical-align:middle;margin-right:8px"></span>Mengirim...';
  }
  await simulateDelay(2000);
  showToast('Bukti pembayaran berhasil dikirim! Admin akan memverifikasi dalam 1×24 jam. 🎉', 'success', 5000);
  stopPaymentTimer();
  setTimeout(() => { window.location.href = '/'; }, 4000);
}

function startPaymentTimer() {
  const el = document.getElementById('payment-countdown');
  if (!el) return;
  paymentTimer = setInterval(() => {
    paymentSeconds--;
    if (paymentSeconds <= 0) {
      stopPaymentTimer();
      showToast('Waktu pembayaran telah habis. Silakan booking ulang.', 'warning', 6000);
      el.textContent = '00:00';
      return;
    }
    const m = Math.floor(paymentSeconds / 60);
    const s = paymentSeconds % 60;
    el.textContent = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }, 1000);
}

function stopPaymentTimer() {
  if (paymentTimer) { clearInterval(paymentTimer); paymentTimer = null; }
}

// Fallback jika formatRupiah/formatDateID belum ada
if (typeof formatRupiah === 'undefined') {
  window.formatRupiah = n => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(n);
}
if (typeof formatDateID === 'undefined') {
  window.formatDateID = d => new Date(d + 'T00:00:00').toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
}
