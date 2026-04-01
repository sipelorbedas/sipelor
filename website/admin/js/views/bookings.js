// ─────────────────────────────────────────────────────
// BOOKINGS VIEW
// ─────────────────────────────────────────────────────

let _bPage = 1, _bStatus = '', _bPayStatus = '', _bSearch = '';

// Track blob URLs so we can revoke them and avoid memory leaks
const _proofBlobUrls = [];
function _trackBlobUrl(url) {
  if (url && url.startsWith('blob:')) _proofBlobUrls.push(url);
}
function _revokeOldBlobUrls() {
  while (_proofBlobUrls.length) URL.revokeObjectURL(_proofBlobUrls.pop());
}

async function renderBookings(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Manajemen Pemesanan</div>
      <div class="page-subtitle">Kelola semua pemesanan, verifikasi pembayaran, dan konfirmasi booking.</div>
    </div>
    <div class="flex gap-2">
      <button class="btn btn-outline btn-sm" id="btn-export-csv" onclick="exportBookingsCSV()">
        📥 Export CSV
      </button>
    </div>
  </div>

  <div class="card">
    <!-- Controls -->
    <div class="table-controls">
      <div class="table-search">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
        <input type="text" placeholder="Cari ID pemesanan..." id="bSearch" value="${_bSearch}" oninput="debounceBookingSearch(this.value)" />
      </div>
      <div class="table-filter-group">
        <select class="form-control form-select" style="width:auto;padding:8px 36px 8px 12px;font-size:13px;" onchange="filterBookings('status', this.value)">
          <option value="">Semua Status</option>
          <option value="pending"   ${_bStatus==='pending'   ?'selected':''}>Menunggu</option>
          <option value="confirmed" ${_bStatus==='confirmed' ?'selected':''}>Dikonfirmasi</option>
          <option value="completed" ${_bStatus==='completed' ?'selected':''}>Selesai</option>
          <option value="cancelled" ${_bStatus==='cancelled' ?'selected':''}>Dibatalkan</option>
        </select>
        <select class="form-control form-select" style="width:auto;padding:8px 36px 8px 12px;font-size:13px;" onchange="filterBookings('payment', this.value)">
          <option value="">Semua Pembayaran</option>
          <option value="pending"  ${_bPayStatus==='pending' ?'selected':''}>Menunggu Verifikasi</option>
          <option value="verified" ${_bPayStatus==='verified'?'selected':''}>Terverifikasi</option>
          <option value="rejected" ${_bPayStatus==='rejected'?'selected':''}>Ditolak</option>
        </select>
      </div>
    </div>

    <!-- Table -->
    <div class="table-wrap" id="bookings-table-wrap">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>

    <!-- Pagination -->
    <div id="bookings-pagination"></div>
  </div>

  <!-- Detail Modal -->
  <div class="modal-overlay" id="booking-modal">
    <div class="modal modal-lg">
      <div class="modal-header">
        <div class="modal-title" id="modal-booking-title">Detail Pemesanan</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('booking-modal')">✕</button>
      </div>
      <div class="modal-body" id="modal-booking-body"></div>
      <div class="modal-footer" id="modal-booking-footer"></div>
    </div>
  </div>

  <!-- Proof Lightbox Modal -->
  <div class="modal-overlay" id="proof-lightbox-modal" onclick="closeModal('proof-lightbox-modal')">
    <div class="modal modal-xl" onclick="event.stopPropagation()" style="background:#111;border:none;border-radius:var(--radius-lg);">
      <div class="modal-header" style="background:#111;border-color:rgba(255,255,255,0.1);">
        <div class="modal-title" style="color:#fff;">🔍 Bukti Pembayaran</div>
        <button class="btn btn-ghost btn-icon" style="color:#fff;" onclick="closeModal('proof-lightbox-modal')">✕</button>
      </div>
      <div style="padding:16px;text-align:center;max-height:80vh;overflow:auto;background:#111;">
        <img id="proof-lightbox-img" src="" alt="Bukti Pembayaran"
          style="max-width:100%;max-height:70vh;object-fit:contain;border-radius:var(--radius);">
      </div>
    </div>
  </div>`;

  loadBookingsTable(api);
  window._bookingAPI = api;
}

async function loadBookingsTable(api, page = _bPage) {
  _bPage = page;
  const wrap = document.getElementById('bookings-table-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  const { data, count } = await api.getBookings({
    page: _bPage, limit: 10,
    status: _bStatus, paymentStatus: _bPayStatus, search: _bSearch,
  });

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">📋</div><h3>Tidak ada pemesanan</h3><p>Coba ubah filter pencarian.</p></div>`;
    document.getElementById('bookings-pagination').innerHTML = '';
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>ID Pemesanan</th>
        <th>Pengguna</th>
        <th>Lapangan</th>
        <th>Tanggal</th>
        <th>Jam</th>
        <th>Total</th>
        <th>Status</th>
        <th>Pembayaran</th>
        <th>Bukti Bayar</th>
        <th>Aksi</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(b => `
      <tr>
        <td><span class="cell-id">${b.booking_id}</span></td>
        <td>
          <div class="flex items-center gap-2">
            <div class="avatar-sm">${(b.user_name || 'U')[0]}</div>
            <div>
              <div class="font-medium" style="font-size:13px;">${b.user_name || '—'}</div>
            </div>
          </div>
        </td>
        <td>
          <div style="font-size:13px;font-weight:600;">${b.fields?.venue_name || '—'}</div>
          <div class="text-sm text-muted">${b.fields?.venue_type || ''} · ${b.fields?.area || ''}</div>
        </td>
        <td style="white-space:nowrap;">${fmtDate(b.booking_date)}</td>
        <td style="font-size:12px;">${fmtBookingTableTime(b)}</td>
        <td style="font-weight:700;color:var(--success);white-space:nowrap;">${fmtRp(b.total_amount)}</td>
        <td>
          ${bookingStatusBadge(b.status)}
          ${b.booking_type && b.booking_type !== 'regular'
            ? `<span class="badge" style="margin-left:4px;background:${b.booking_type==='pimpinan'?'#7C3AED':'#F59E0B'};color:#fff;font-size:10px;">
                ${b.booking_type==='pimpinan'?'👑 Pimpinan':'🏛️ OPD'}
               </span>`
            : ''}
        </td>
        <td>${paymentStatusBadge(b.payment_status)}</td>
        <td>${proofTableCell(b)}</td>
        <td>
          <div class="flex gap-2">
            <button class="btn btn-outline btn-sm btn-icon" title="Detail" onclick="openBookingDetail('${b.id}')">🔍</button>
            ${b.status === 'pending' ? `<button class="btn btn-success btn-sm btn-icon" title="Konfirmasi" onclick="quickApprove('${b.id}')">✓</button>` : ''}
            ${b.status === 'confirmed' ? `<button class="btn btn-info btn-sm btn-icon" title="Tandai Selesai" onclick="quickComplete('${b.id}')"><svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg></button>` : ''}
            ${b.payment_status === 'pending' ? `<button class="btn btn-primary btn-sm btn-icon" title="Verifikasi Bayar" onclick="quickVerifyPayment('${b.id}')">💳</button>` : ''}
            ${!['completed','cancelled'].includes(b.status) ? `<button class="btn btn-danger btn-sm btn-icon" title="Batalkan" onclick="quickCancel('${b.id}')">✕</button>` : ''}
          </div>
        </td>
      </tr>`).join('')}
    </tbody>
  </table>`;

  // Pagination
  const totalPages = Math.ceil(count / 10);
  document.getElementById('bookings-pagination').innerHTML = renderPagination(
    _bPage, totalPages, count, 'loadBookingsPage'
  );
  window.loadBookingsPage = (p) => loadBookingsTable(window._bookingAPI, p);
}

// ── Proof Cell Helper ──────────────────────────────────
function proofTableCell(b) {
  if (!b.proof) {
    return `<span class="text-muted" style="font-size:13px;">—</span>`;
  }
  const statusMap = {
    pending:  ['badge-warning', '⏳ Menunggu'],
    approved: ['badge-success', '✓ Disetujui'],
      verified: ['badge-success', '✓ Terverifikasi'],
    rejected: ['badge-danger',  '✕ Ditolak'],
  };
  const [cls, label] = statusMap[b.proof.status] || ['badge-gray', b.proof.status || 'Ada'];
  return `
    <button class="proof-table-btn" title="Lihat bukti pembayaran"
      onclick="openBookingDetail('${b.id}')">
      <span class="badge ${cls}" style="cursor:pointer;">
        📄 ${label}
      </span>
    </button>`;
}

// ── Actions ───────────────────────────────────────────
window.filterBookings = function(type, val) {
  if (type === 'status')  _bStatus    = val;
  if (type === 'payment') _bPayStatus = val;
  _bPage = 1;
  loadBookingsTable(window._bookingAPI);
};

let _bSearchTimer;
window.debounceBookingSearch = function(val) {
  clearTimeout(_bSearchTimer);
  _bSearchTimer = setTimeout(() => {
    _bSearch = val; _bPage = 1;
    loadBookingsTable(window._bookingAPI);
  }, 400);
};

window.openBookingDetail = async function(id) {
  const modal  = document.getElementById('booking-modal');
  const body   = document.getElementById('modal-booking-body');
  const footer = document.getElementById('modal-booking-footer');
  body.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;
  openModal('booking-modal');

  const b = await window._bookingAPI.getBookingById(id);
  if (!b) { body.innerHTML = `<p class="text-muted">Data tidak ditemukan.</p>`; return; }

  document.getElementById('modal-booking-title').textContent = `Pemesanan ${b.booking_id}`;

  body.innerHTML = `
  <div style="display:grid;gap:20px;">

    <!-- Booking info grid -->
    <div class="info-grid">
      <div class="info-item"><div class="info-label">ID Pemesanan</div><div class="info-value"><span class="cell-id">${b.booking_id}</span></div></div>
      <div class="info-item"><div class="info-label">Pengguna</div><div class="info-value">${b.user_name || b.user_id}</div></div>
      <div class="info-item"><div class="info-label">Lapangan</div><div class="info-value">${b.fields?.venue_name || '—'}</div></div>
      <div class="info-item"><div class="info-label">Jenis & Area</div><div class="info-value">${b.fields?.venue_type || ''} · ${b.fields?.area || ''}</div></div>
      <div class="info-item"><div class="info-label">Tanggal Booking</div><div class="info-value">${fmtDate(b.booking_date)}</div></div>
      <div class="info-item">
        <div class="info-label">🕐 Jadwal Main</div>
        <div class="info-value" style="font-size:15px;font-weight:700;color:var(--primary);">
          ${fmtBookingSchedule(b)}
        </div>
      </div>
      <div class="info-item">
        <div class="info-label">⏰ Mulai</div>
        <div class="info-value">${fmtBookingStart(b)}</div>
      </div>
      <div class="info-item">
        <div class="info-label">⏱️ Selesai</div>
        <div class="info-value">${fmtBookingEnd(b)}</div>
      </div>
      <div class="info-item">
        <div class="info-label">⌛ Durasi</div>
        <div class="info-value">${fmtDuration(b)}</div>
      </div>
      <div class="info-item"><div class="info-label">Total Pembayaran</div><div class="info-value" style="color:var(--success);font-size:18px;font-weight:800;">${fmtRp(b.total_amount)}</div></div>
      <div class="info-item"><div class="info-label">Dibuat Pada</div><div class="info-value">${fmtDateTime(b.created_at)}</div></div>
    </div>

    <!-- Status row -->
    <div class="flex gap-3">
      <div style="flex:1;"><div class="info-label">Status Pemesanan</div><div class="mt-1">${bookingStatusBadge(b.status)}</div></div>
      <div style="flex:1;"><div class="info-label">Status Pembayaran</div><div class="mt-1">${paymentStatusBadge(b.payment_status)}</div></div>
    </div>

    ${b.notes ? `<div><div class="info-label">Catatan</div><div class="info-value mt-1" style="font-size:13.5px;">${b.notes}</div></div>` : ''}

    <!-- ══ Bukti Pembayaran Section ══ -->
    <div>
      <div class="info-label" style="margin-bottom:10px;">📎 Bukti Pembayaran</div>
      <div id="proof-section-${id}">
        <div class="proof-loading"><span class="spinner spinner-sm"></span> Memuat bukti pembayaran...</div>
      </div>
    </div>

  </div>`;

  // Load proof async after modal is shown
  loadProofSection(id, `proof-section-${id}`);

  const btns = [];
  if (b.status === 'pending') {
    btns.push(`<button class="btn btn-success" onclick="approveBooking('${b.id}')">✓ Konfirmasi Pemesanan</button>`);
  }
  if (b.status === 'confirmed') {
    btns.push(`<button class="btn btn-info" onclick="completeBooking('${b.id}')"><svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" style="vertical-align:-2px;margin-right:6px;"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>Tandai Selesai</button>`);
  }
  if (b.payment_status === 'pending') {
    btns.push(`<button class="btn btn-primary" onclick="verifyPayment('${b.id}')">💳 Verifikasi Pembayaran</button>`);
    btns.push(`<button class="btn btn-danger btn-outline" onclick="rejectPayment('${b.id}')">✕ Tolak Pembayaran</button>`);
  }
  if (!['completed','cancelled'].includes(b.status)) {
    btns.push(`<button class="btn btn-danger" onclick="cancelBooking('${b.id}')">Batalkan Pemesanan</button>`);
  }
  btns.push(`<button class="btn btn-outline" onclick="closeModal('booking-modal')">Tutup</button>`);
  footer.innerHTML = btns.join('');
};

// ── Proof Section Loader ──────────────────────────────
async function loadProofSection(bookingId, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;

  // Revoke any previous blob URLs to free memory
  _revokeOldBlobUrls();

  try {
    // Use the decrypting variant — Flutter encrypts files before upload (AES-CTR).
    // Falls back to raw URL gracefully if decryption is not needed.
    const result = await window._bookingAPI.getDecryptedPaymentProofBlobUrl(bookingId);

    if (!result) {
      container.innerHTML = `
        <div class="proof-empty-state">
          <span style="font-size:28px;">🧾</span>
          <div style="margin-top:8px;font-size:13px;color:var(--text-muted);">Belum ada bukti pembayaran yang diunggah.</div>
        </div>`;
      return;
    }

    const { url, proof, mimeType } = result;

    // Track blob URLs for later cleanup
    _trackBlobUrl(url);

    const proofStatusMap = {
      pending:  ['badge-warning', '⏳ Menunggu Review'],
      approved: ['badge-success', '✓ Disetujui'],
      verified: ['badge-success', '✓ Terverifikasi'],
      rejected: ['badge-danger',  '✕ Ditolak'],
    };
    const [statusCls, statusLabel] = proofStatusMap[proof.status] || ['badge-gray', proof.status || '—'];
    const uploadedAt = fmtDateTime(proof.created_at);

    // Determine file type — use mimeType from decryption when available (blob URLs
    // don't carry file extensions); fall back to extension-based check for raw URLs.
    const isImage = mimeType
      ? mimeType.startsWith('image/')
      : /\.(jpg|jpeg|png|webp|gif)$/i.test((url || proof.file_path || '').split('?')[0]);
    const isPdf   = mimeType
      ? mimeType === 'application/pdf'
      : /\.pdf$/i.test((url || proof.file_path || '').split('?')[0]);

    // Safe filename for download
    const rawName = (proof.file_path || '').split('/').pop().split('?')[0];
    const dlName  = rawName || `bukti_${proof.booking_id || 'pembayaran'}.jpg`;

    // Store url on the container so downloadProof can use the already-decrypted blob
    container.dataset.proofUrl  = url;
    container.dataset.proofName = dlName;
    container.dataset.isImage   = isImage ? '1' : '0';

    container.innerHTML = `
      <div class="proof-card">

        <!-- Preview area -->
        ${isImage ? `
          <div class="proof-img-wrap" onclick="openProofLightbox('${url.replace(/'/g, "\\'")}')">
            <img src="${url}" alt="Bukti Pembayaran" class="proof-img"
              onerror="this.parentElement.innerHTML='<div class=\\'proof-img-error\\'>⚠️ Gagal memuat gambar — format file tidak didukung browser</div>'">
            <div class="proof-img-overlay">🔍 Klik untuk perbesar</div>
          </div>
        ` : isPdf ? `
          <div class="proof-pdf-preview">
            <span style="font-size:40px;">📄</span>
            <div style="margin-top:6px;font-size:12px;color:var(--text-muted);">Dokumen PDF</div>
          </div>
        ` : `
          <div class="proof-pdf-preview">
            <span style="font-size:40px;">📎</span>
            <div style="margin-top:6px;font-size:12px;color:var(--text-muted);">File Lampiran</div>
          </div>
        `}

        <!-- Meta -->
        <div class="proof-meta">
          <div class="flex items-center gap-2" style="flex-wrap:wrap;">
            <span class="badge ${statusCls}">${statusLabel}</span>
            <span class="text-muted" style="font-size:12px;">Diunggah: ${uploadedAt}</span>
          </div>
        </div>

        <!-- Action buttons -->
        <div class="proof-actions">
          ${isImage ? `
            <button class="btn btn-outline btn-sm" onclick="openProofLightbox('${url.replace(/'/g, "\\'")}')">
              🔍 Lihat
            </button>
          ` : `
            <a href="${url}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm">
              🔍 Buka
            </a>
          `}
          <button class="btn btn-primary btn-sm" onclick="downloadProof('${bookingId}', '${dlName}')">
            📥 Download
          </button>
          ${proof.status === 'pending' ? `
            <button class="btn btn-success btn-sm" id="proof-verify-btn-${proof.id}"
              onclick="verifyProofStatus('${proof.id}', '${bookingId}', '${containerId}')">
              ✓ Verifikasi Bukti Bayar
            </button>
            <button class="btn btn-danger btn-outline btn-sm"
              onclick="rejectProofStatus('${proof.id}', '${bookingId}', '${containerId}')">
              ✕ Tolak Bukti
            </button>
          ` : ''}
        </div>
      </div>`;
  } catch (e) {
    console.error('[SIPELOR] loadProofSection error:', e);

    // Deteksi error RLS (kode 42501 atau pesan mengandung 'policy'/'permission')
    const isRLS = e?.code === '42501'
      || /policy|permission|rls|row.level/i.test(e?.message || '');

    container.innerHTML = `
      <div class="proof-empty-state" style="border:1.5px solid ${isRLS ? '#FCA5A5' : 'var(--border)'};border-radius:var(--radius);padding:16px;background:${isRLS ? '#FEF2F2' : 'transparent'};">
        <span style="font-size:28px;">${isRLS ? '🔒' : '⚠️'}</span>
        <div style="margin-top:8px;font-size:13px;color:${isRLS ? '#991B1B' : 'var(--text-muted)'};">
          ${isRLS
            ? `<strong>Akses ditolak oleh RLS Supabase.</strong><br>
               <span style="font-weight:400;">Jalankan SQL berikut di <b>Supabase Dashboard → SQL Editor</b>:</span><br>
               <code style="display:inline-block;margin-top:6px;background:#fee2e2;padding:3px 8px;border-radius:4px;font-size:12px;">
                 fix_payment_proofs_select_rls.sql
               </code>`
            : 'Gagal memuat bukti pembayaran. Coba buka ulang detail pemesanan.'
          }
        </div>
      </div>`;
  }
}

// ── Proof Actions ─────────────────────────────────────
window.openProofLightbox = function(url) {
  const img = document.getElementById('proof-lightbox-img');
  if (img) img.src = url;
  openModal('proof-lightbox-modal');
};

window.downloadProof = async function(bookingId, fileName) {
  showToast('Memproses download...', 'info');
  try {
    const cleanName = (fileName && fileName !== 'undefined' && fileName.length > 4)
      ? fileName
      : `bukti_pembayaran_${bookingId}.jpg`;

    // Re-use the already-decrypted blob URL from the proof section if available,
    // so we don't have to re-download and re-decrypt the file.
    const proofContainer = document.querySelector(`[id^="proof-section-"]`);
    const cachedUrl = proofContainer?.dataset?.proofUrl;

    let downloadUrl = cachedUrl;
    if (!downloadUrl) {
      // Not cached — fetch and decrypt fresh
      const result = await window._bookingAPI.getDecryptedPaymentProofBlobUrl(bookingId);
      if (!result?.url) {
        showToast('Bukti pembayaran tidak ditemukan.', 'error');
        return;
      }
      downloadUrl = result.url;
      _trackBlobUrl(downloadUrl);
    }

    const a = document.createElement('a');
    a.href = downloadUrl;
    a.download = cleanName;
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    showToast('Download dimulai! ✅', 'success');
  } catch (e) {
    showToast('Gagal download: ' + e.message, 'error');
  }
};

// ── Booking Action Handlers ───────────────────────────
// Revoke blob URLs when the booking detail modal closes
const _origCloseModal = window.closeModal;
window.closeModal = function(id) {
  if (id === 'booking-modal') _revokeOldBlobUrls();
  if (_origCloseModal) _origCloseModal(id);
};

window.approveBooking = async function(id) {
  try {
    await window._bookingAPI.updateBookingStatus(id, 'confirmed');
    showToast('Pemesanan berhasil dikonfirmasi! ✅', 'success');
    closeModal('booking-modal');
    loadBookingsTable(window._bookingAPI);
  } catch(e) { showToast('Gagal: ' + e.message, 'error'); }
};
window.quickApprove = (id) => window.approveBooking(id);

window.verifyPayment = async function(id) {
  try {
    await window._bookingAPI.updatePaymentStatus(id, 'verified');
    showToast('Pembayaran terverifikasi! ✅', 'success');
    closeModal('booking-modal');
    loadBookingsTable(window._bookingAPI);
  } catch(e) { showToast('Gagal: ' + e.message, 'error'); }
};
window.quickVerifyPayment = (id) => window.verifyPayment(id);

window.rejectPayment = async function(id) {
  if (!confirm('Tolak pembayaran ini?')) return;
  try {
    await window._bookingAPI.updatePaymentStatus(id, 'rejected');
    showToast('Pembayaran ditolak.', 'warning');
    closeModal('booking-modal');
    loadBookingsTable(window._bookingAPI);
  } catch(e) { showToast('Gagal: ' + e.message, 'error'); }
};

window.cancelBooking = async function(id) {
  if (!confirm('Batalkan pemesanan ini?')) return;
  try {
    await window._bookingAPI.updateBookingStatus(id, 'cancelled');
    showToast('Pemesanan dibatalkan.', 'warning');
    closeModal('booking-modal');
    loadBookingsTable(window._bookingAPI);
  } catch(e) { showToast('Gagal: ' + e.message, 'error'); }
};
window.quickCancel = (id) => window.cancelBooking(id);

window.completeBooking = async function(id) {
  if (!confirm('Tandai pemesanan ini sebagai Selesai?')) return;
  try {
    await window._bookingAPI.updateBookingStatus(id, 'completed');
    showToast('Pemesanan ditandai selesai! ✅', 'success');
    closeModal('booking-modal');
    loadBookingsTable(window._bookingAPI);
  } catch(e) { showToast('Gagal: ' + e.message, 'error'); }
};
window.quickComplete = (id) => window.completeBooking(id);

// ── Proof Status Handlers ────────────────────────────
window.verifyProofStatus = async function(proofId, bookingId, containerId) {
  const btn = document.getElementById(`proof-verify-btn-${proofId}`);
  if (btn) { btn.disabled = true; btn.textContent = 'Memverifikasi...'; }
  try {
    // Update the proof record status → verified (only the proof, not the whole booking)
    await window._bookingAPI.updateProofStatus(proofId, 'verified');
    showToast('Bukti pembayaran berhasil diverifikasi! ✅', 'success');
    // Refresh proof section in-place without closing modal
    loadProofSection(bookingId, containerId);
    // Refresh footer buttons to reflect new payment_status
    openBookingDetail(bookingId);
    // Refresh the table in background
    loadBookingsTable(window._bookingAPI);
  } catch(e) {
    if (btn) { btn.disabled = false; btn.textContent = '✓ Verifikasi Bukti Bayar'; }
    showToast('Gagal verifikasi: ' + e.message, 'error');
  }
};

window.rejectProofStatus = async function(proofId, bookingId, containerId) {
  if (!confirm('Tolak bukti pembayaran ini?')) return;
  try {
    await window._bookingAPI.updateProofStatus(proofId, 'rejected');
    await window._bookingAPI.updatePaymentStatus(bookingId, 'rejected');
    showToast('Bukti pembayaran ditolak.', 'warning');
    loadProofSection(bookingId, containerId);
    openBookingDetail(bookingId);
    loadBookingsTable(window._bookingAPI);
  } catch(e) { showToast('Gagal: ' + e.message, 'error'); }
};

// ── Multi-day Duration Helpers ────────────────────────
/**
 * Compute start DateTime from booking_date + start_time
 */
function _bookingStartDate(b) {
  const rawDate = b.booking_date || '';
  const base = rawDate.includes('T') ? rawDate : rawDate + 'T00:00:00';
  const d = new Date(base);
  if (b.start_time && !b.start_time.includes('T')) {
    const [h, m] = b.start_time.split(':').map(Number);
    d.setHours(h || 0, m || 0, 0, 0);
  }
  return d;
}

/**
 * Compute end DateTime = start + duration_hours
 * Falls back to end_time on the same day if no duration
 */
function _bookingEndDate(b) {
  const durH = Number(b.duration_hours) || 0;
  if (durH > 0) {
    const start = _bookingStartDate(b);
    return new Date(start.getTime() + durH * 3600000);
  }
  // No duration — derive from end_time on same day
  const rawDate = b.booking_date || '';
  const base = rawDate.includes('T') ? rawDate : rawDate + 'T00:00:00';
  const d = new Date(base);
  if (b.end_time && !b.end_time.includes('T')) {
    const [h, m] = b.end_time.split(':').map(Number);
    d.setHours(h || 0, m || 0, 0, 0);
  }
  return d;
}

/** Format the full booking schedule, expanding to date range when >1 day */
function fmtBookingSchedule(b) {
  const durH = Number(b.duration_hours) || 0;
  const startDt = _bookingStartDate(b);
  const endDt   = _bookingEndDate(b);

  const startDay = startDt.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
  const endDay   = endDt.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
  const startT   = startDt.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  const endT     = endDt.toLocaleTimeString('id-ID',   { hour: '2-digit', minute: '2-digit' });

  if (durH >= 24) {
    // Show full date+time range
    return `${startDay}, ${startT} <span style="color:var(--text-muted)">s/d</span> ${endDay}, ${endT}`;
  }
  return `${startDay}, ${startT} – ${endT}`;
}

/** Start date+time label */
function fmtBookingStart(b) {
  const durH = Number(b.duration_hours) || 0;
  if (durH >= 24) {
    const dt = _bookingStartDate(b);
    return dt.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) + ', ' +
           dt.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  }
  return `${fmtDate(b.booking_date)}, ${fmtTime(b.start_time)}`;
}

/** End date+time label — computes end date for multi-day bookings */
function fmtBookingEnd(b) {
  const durH = Number(b.duration_hours) || 0;
  if (durH >= 24) {
    const dt = _bookingEndDate(b);
    return dt.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) + ', ' +
           dt.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  }
  return fmtTime(b.end_time);
}

/** Duration — shows days + hours when >= 24h */
function fmtDuration(b) {
  const h = Number(b.duration_hours) || 0;
  if (h <= 0) return '—';
  if (h < 24) return `${h} jam`;
  const days = Math.floor(h / 24);
  const rem  = h % 24;
  return rem > 0 ? `${days} hari ${rem} jam` : `${days} hari`;
}

/** Table cell — compact time range; adds date if multi-day */
function fmtBookingTableTime(b) {
  const durH = Number(b.duration_hours) || 0;
  if (durH >= 24) {
    const s = _bookingStartDate(b);
    const e = _bookingEndDate(b);
    const sd = s.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
    const ed = e.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
    const st = s.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    const et = e.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    return `<div style="white-space:nowrap;">${sd} ${st}</div><div style="white-space:nowrap;color:var(--text-muted)">s/d ${ed} ${et}</div>`;
  }
  return `${fmtTime(b.start_time)} – ${fmtTime(b.end_time)}`;
}

window.exportBookingsCSV = function() {
  showToast('Mengekspor data pemesanan...', 'info');
  const csvContent = "data:text/csv;charset=utf-8,ID,Pengguna,Lapangan,Tanggal,Total,Status,Pembayaran,BuktiBayar\n";
  const link = document.createElement('a');
  link.setAttribute('href', encodeURI(csvContent));
  link.setAttribute('download', `bookings_${new Date().toISOString().split('T')[0]}.csv`);
  link.click();
};
