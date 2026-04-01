// ─────────────────────────────────────────────────────
// OPD / PIMPINAN VIEW
// Kelola daftar OPD dan blokir jadwal lapangan
// ─────────────────────────────────────────────────────

let _opdList       = [];  // cache daftar OPD
let _opdFields     = [];  // cache daftar lapangan
let _opdBookingPage = 1;

async function renderOPD(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">🏛️ OPD / Pimpinan</div>
      <div class="page-subtitle">Kelola daftar OPD dan blokir jadwal lapangan untuk keperluan resmi.</div>
    </div>
  </div>

  <!-- ── GRID: Daftar OPD | Form Blokir ── -->
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;align-items:start;">

    <!-- Daftar OPD -->
    <div class="card" style="padding:0;overflow:hidden;">
      <div style="padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;">
        <div>
          <div style="font-size:15px;font-weight:700;color:var(--text);">Daftar OPD & Pimpinan</div>
          <div style="font-size:12px;color:var(--text-muted);margin-top:2px;">Kelola organisasi beserta diskon yang diberikan</div>
        </div>
        <button class="btn btn-primary btn-sm" onclick="openOPDModal()">
          <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" style="vertical-align:-2px;margin-right:5px;"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Tambah OPD
        </button>
      </div>
      <div id="opd-list-wrap" style="padding:16px;">
        <div class="page-loader"><span class="spinner"></span></div>
      </div>
    </div>

    <!-- Form Blokir Jadwal -->
    <div class="card" style="padding:28px 32px;">
      <div style="font-size:15px;font-weight:700;color:var(--text);margin-bottom:6px;">📅 Blokir Jadwal Lapangan</div>
      <div style="font-size:12px;color:var(--text-muted);margin-bottom:28px;">
        Booking akan langsung <strong>Dikonfirmasi</strong> dan memblokir slot waktu tersebut.
      </div>
      <form id="opd-booking-form" onsubmit="submitOPDBooking(event)">

        <!-- Section 1: Type & Organization -->
        <div class="form-group">
          <label class="form-label">Tipe Pemblokir</label>
          <select class="form-control form-select" id="ob-type" required>
            <option value="opd">OPD (Organisasi Perangkat Daerah)</option>
            <option value="pimpinan">Pimpinan Daerah</option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label">OPD / Pimpinan <span style="color:var(--danger)">*</span></label>
          <select class="form-control form-select" id="ob-opd" required onchange="_onOPDSelectChange()">
            <option value="">— Pilih OPD —</option>
          </select>
        </div>

        <!-- Diskon Badge OPD -->
        <div id="ob-discount-badge" style="display:none;margin-bottom:20px;">
          <div style="
            background:linear-gradient(135deg,rgba(168,85,247,0.15),rgba(217,70,239,0.10));
            border:1px solid rgba(168,85,247,0.35);
            border-radius:10px;
            padding:10px 14px;
            display:flex;align-items:center;gap:10px;
          ">
            <span style="font-size:20px;">🏷️</span>
            <div>
              <div style="font-size:12px;font-weight:700;color:var(--primary, #A855F7);" id="ob-discount-label">Diskon 0%</div>
              <div style="font-size:11px;color:var(--text-muted);">Diskon khusus untuk OPD/Pimpinan ini</div>
            </div>
          </div>
        </div>

        <!-- Section 2: Event Details -->
        <div class="form-group">
          <label class="form-label">Keterangan Acara <span style="color:var(--danger)">*</span></label>
          <input type="text" class="form-control" id="ob-label"
            placeholder="Contoh: Bupati Cup 2026, Rapat Dinas, dll." required maxlength="120" />
        </div>

        <div class="form-group" style="margin-bottom:20px;">
          <label class="form-label">Lapangan <span style="color:var(--danger)">*</span></label>
          <select class="form-control form-select" id="ob-field" required onchange="_onFieldOrDurationChange()">
            <option value="">— Pilih Lapangan —</option>
          </select>
        </div>

        <!-- Section 3: Date & Duration -->
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px;">
          <div class="form-group" style="margin-bottom:0;">
            <label class="form-label">Tanggal <span style="color:var(--danger)">*</span></label>
            <input type="date" class="form-control" id="ob-date"
              min="${new Date().toISOString().split('T')[0]}" required />
          </div>
          <div class="form-group" style="margin-bottom:0;">
            <label class="form-label">Durasi (jam) <span style="color:var(--danger)">*</span></label>
            <select class="form-control form-select" id="ob-duration" required onchange="_onFieldOrDurationChange()">
              ${[1,2,3,4,5,6,8].map(h => `<option value="${h}">${h} Jam</option>`).join('')}
            </select>
          </div>
        </div>

        <!-- Section 4: Time Range -->
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px;">
          <div class="form-group" style="margin-bottom:0;">
            <label class="form-label">Jam Mulai <span style="color:var(--danger)">*</span></label>
            <select class="form-control form-select" id="ob-start" required onchange="_updateEndTime()">
              ${Array.from({length:17},(_,i)=>i+6).map(h=>{
                const hh=h.toString().padStart(2,'0');
                return `<option value="${hh}:00">${hh}:00</option>`;
              }).join('')}
            </select>
          </div>
          <div class="form-group" style="margin-bottom:0;">
            <label class="form-label">Jam Selesai</label>
            <input type="text" class="form-control" id="ob-end" readonly
              style="background:var(--bg-secondary);cursor:not-allowed;"
              placeholder="Dihitung otomatis" />
          </div>
        </div>

        <!-- ── Kalkulasi Harga ── -->
        <div id="ob-price-preview" style="display:none;margin-bottom:20px;">
          <div style="
            background:var(--bg-secondary, rgba(255,255,255,0.04));
            border:1px solid var(--border);
            border-radius:10px;
            padding:14px 16px;
          ">
            <div style="font-size:12px;font-weight:700;color:var(--text-muted);margin-bottom:10px;text-transform:uppercase;letter-spacing:.5px;">
              💰 Kalkulasi Harga
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
              <span style="font-size:13px;color:var(--text-muted);">Harga Normal</span>
              <span style="font-size:13px;color:var(--text);" id="ob-price-normal">—</span>
            </div>
            <div id="ob-price-discount-row" style="display:none;justify-content:space-between;align-items:center;margin-bottom:6px;">
              <span style="font-size:13px;color:#F59E0B;" id="ob-price-discount-pct-label">Diskon (0%)</span>
              <span style="font-size:13px;color:#F59E0B;" id="ob-price-discount-amt">— </span>
            </div>
            <div style="border-top:1px solid var(--border);margin:8px 0;"></div>
            <div style="display:flex;justify-content:space-between;align-items:center;">
              <span style="font-size:14px;font-weight:700;color:var(--text);">Total Dibayar</span>
              <span style="font-size:15px;font-weight:800;color:var(--primary, #A855F7);" id="ob-price-final">—</span>
            </div>
          </div>
        </div>

        <!-- Section 5: Notes -->
        <div class="form-group">
          <label class="form-label">Catatan (Opsional)</label>
          <textarea class="form-control" id="ob-notes" rows="2"
            placeholder="Catatan tambahan untuk admin..."></textarea>
        </div>

        <button type="submit" class="btn btn-primary" style="width:100%;" id="ob-submit-btn">
          🔒 Blokir Jadwal
        </button>
      </form>
    </div>
  </div>

  <!-- ── Riwayat Booking OPD ── -->
  <div class="card" style="margin-top:20px;padding:0;overflow:hidden;">
    <div style="padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;">
      <div>
        <div style="font-size:15px;font-weight:700;color:var(--text);">Riwayat Blokir Jadwal OPD</div>
        <div style="font-size:12px;color:var(--text-muted);margin-top:2px;">Semua jadwal yang sudah diblokir untuk OPD/Pimpinan</div>
      </div>
      <button class="btn btn-outline btn-sm" onclick="loadOPDBookingsTable(window._opdAPI)">
        <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" style="vertical-align:-2px;margin-right:4px;"><path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/></svg>
        Refresh
      </button>
    </div>
    <div id="opd-bookings-wrap" style="padding:16px;">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
  </div>

  <!-- Modal Tambah/Edit OPD -->
  <div class="modal-overlay" id="opd-modal">
    <div class="modal">
      <div class="modal-header">
        <div class="modal-title" id="opd-modal-title">Tambah OPD</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('opd-modal')">✕</button>
      </div>
      <div class="modal-body" id="opd-modal-body"></div>
    </div>
  </div>`;

  window._opdAPI = api;

  // Event listeners
  document.getElementById('ob-start').addEventListener('change', _updateEndTime);
  document.getElementById('ob-duration').addEventListener('change', _updateEndTime);
  _updateEndTime();

  // Load data paralel
  await Promise.all([
    _loadOPDList(api),
    _loadFieldsForOPDForm(api),
    loadOPDBookingsTable(api),
  ]);
}

// ── Hitung jam selesai otomatis ────────────────────────────────
function _updateEndTime() {
  const startVal = document.getElementById('ob-start')?.value || '06:00';
  const durVal   = parseInt(document.getElementById('ob-duration')?.value || '1');
  const [h] = startVal.split(':').map(Number);
  const endH = (h + durVal).toString().padStart(2, '0');
  const endEl = document.getElementById('ob-end');
  if (endEl) endEl.value = `${endH}:00`;
  _updatePricePreview();
}

// ── Saat OPD dipilih → tampilkan badge diskon & update preview ─
window._onOPDSelectChange = function() {
  const sel = document.getElementById('ob-opd');
  const opt = sel?.options[sel.selectedIndex];
  const pct = parseFloat(opt?.dataset?.discount || 0);

  const badge = document.getElementById('ob-discount-badge');
  const label = document.getElementById('ob-discount-label');
  if (badge && label) {
    if (pct > 0 && opt?.value) {
      label.textContent = `Diskon ${pct}% untuk ${opt.text}`;
      badge.style.display = '';
    } else {
      badge.style.display = 'none';
    }
  }
  _updatePricePreview();
};

// ── Saat lapangan atau durasi berubah ──────────────────────────
window._onFieldOrDurationChange = function() {
  _updateEndTime();  // juga update jam selesai
  _updatePricePreview();
};

// ── Kalkulasi & tampilkan preview harga ────────────────────────
function _updatePricePreview() {
  const fieldSel   = document.getElementById('ob-field');
  const fieldOpt   = fieldSel?.options[fieldSel.selectedIndex];
  const pricePerHr = parseFloat(fieldOpt?.dataset?.price || 0);
  const duration   = parseInt(document.getElementById('ob-duration')?.value || 1);

  const opdSel   = document.getElementById('ob-opd');
  const opdOpt   = opdSel?.options[opdSel.selectedIndex];
  const discount = parseFloat(opdOpt?.dataset?.discount || 0);

  const preview = document.getElementById('ob-price-preview');
  if (!preview) return;

  // Jika lapangan belum dipilih, sembunyikan preview
  if (!fieldOpt?.value || pricePerHr <= 0) {
    preview.style.display = 'none';
    return;
  }

  preview.style.display = '';

  const baseAmount     = pricePerHr * duration;
  const discountAmount = Math.round(baseAmount * discount / 100);
  const finalAmount    = Math.max(0, baseAmount - discountAmount);

  document.getElementById('ob-price-normal').textContent =
    fmtRp(baseAmount) + ` (${fmtRp(pricePerHr)} × ${duration} jam)`;

  const discountRow = document.getElementById('ob-price-discount-row');
  if (discount > 0) {
    discountRow.style.display = 'flex';
    document.getElementById('ob-price-discount-pct-label').textContent = `Diskon (${discount}%)`;
    document.getElementById('ob-price-discount-amt').textContent = `- ${fmtRp(discountAmount)}`;
  } else {
    discountRow.style.display = 'none';
  }

  document.getElementById('ob-price-final').textContent = fmtRp(finalAmount);
}

// ── Load daftar OPD ────────────────────────────────────────────
async function _loadOPDList(api) {
  _opdList = await api.getOPDList();
  _renderOPDList();
  _populateOPDDropdown();
}

function _discountBadgeHtml(pct) {
  if (!pct || pct <= 0) return '<span style="color:var(--text-muted);font-size:12px;">—</span>';
  const color = pct >= 100 ? '#10B981' : pct >= 50 ? '#F59E0B' : '#A855F7';
  return `<span style="
    display:inline-flex;align-items:center;gap:4px;
    background:${color}20;border:1px solid ${color}50;
    color:${color};font-size:12px;font-weight:700;
    padding:2px 8px;border-radius:20px;
  ">🏷️ ${pct}%</span>`;
}

function _renderOPDList() {
  const wrap = document.getElementById('opd-list-wrap');
  if (!wrap) return;

  if (!_opdList.length) {
    wrap.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">🏛️</div>
      <h3>Belum ada OPD</h3>
      <p>Klik tombol "Tambah OPD" untuk menambah organisasi.</p>
    </div>`;
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>Nama OPD / Pimpinan</th>
        <th>PIC</th>
        <th>Kontak</th>
        <th>Diskon</th>
        <th>Status</th>
        <th>Aksi</th>
      </tr>
    </thead>
    <tbody>
      ${_opdList.map(o => `
      <tr>
        <td style="font-weight:600;font-size:13px;">${o.name}</td>
        <td style="font-size:13px;">${o.contact_person || '—'}</td>
        <td>
          <div style="font-size:12px;">${o.phone || '—'}</div>
          <div style="font-size:11px;color:var(--text-muted);">${o.email || ''}</div>
        </td>
        <td>${_discountBadgeHtml(o.discount_percentage)}</td>
        <td>
          <span class="badge ${o.is_active ? 'badge-success' : 'badge-gray'}">
            ${o.is_active ? 'Aktif' : 'Nonaktif'}
          </span>
        </td>
        <td>
          <div class="flex gap-2">
            <button class="btn btn-outline btn-sm btn-icon" title="Edit" onclick="editOPD('${o.id}')">✏️</button>
            <button class="btn btn-danger btn-sm btn-icon" title="Hapus" onclick="deleteOPD('${o.id}', '${o.name.replace(/'/g,"\\'")}')">🗑️</button>
          </div>
        </td>
      </tr>`).join('')}
    </tbody>
  </table>`;
}

function _populateOPDDropdown() {
  const sel = document.getElementById('ob-opd');
  if (!sel) return;
  sel.innerHTML = '<option value="">— Pilih OPD —</option>' +
    _opdList.filter(o => o.is_active)
      .map(o => {
        const pct = o.discount_percentage || 0;
        const label = pct > 0 ? `${o.name} (Diskon ${pct}%)` : o.name;
        return `<option value="${o.id}" data-discount="${pct}">${label}</option>`;
      }).join('');
  // Reset badge & preview
  const badge = document.getElementById('ob-discount-badge');
  if (badge) badge.style.display = 'none';
  const preview = document.getElementById('ob-price-preview');
  if (preview) preview.style.display = 'none';
}

// ── Load lapangan untuk form ────────────────────────────────────
async function _loadFieldsForOPDForm(api) {
  try {
    const { data } = await api.getFields({ limit: 50 });
    _opdFields = data || [];
  } catch (_) {
    _opdFields = api._mockFields ? api._mockFields() : [];
  }
  const sel = document.getElementById('ob-field');
  if (!sel) return;
  sel.innerHTML = '<option value="">— Pilih Lapangan —</option>' +
    _opdFields.map(f => {
      const price = f.price_per_hour || 0;
      return `<option value="${f.id}" data-price="${price}">${f.venue_name} (${f.venue_type} · ${f.area}) — ${fmtRp(price)}/jam</option>`;
    }).join('');
}

// ── Load riwayat blokir OPD ────────────────────────────────────
async function loadOPDBookingsTable(api, page = _opdBookingPage) {
  _opdBookingPage = page;
  const wrap = document.getElementById('opd-bookings-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  const { data, count } = await api.getOPDBookings({ page, limit: 10 });

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">📅</div>
      <h3>Belum ada blokir jadwal</h3>
      <p>Gunakan form di atas untuk memblokir jadwal lapangan.</p>
    </div>`;
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>ID</th>
        <th>OPD / Pimpinan</th>
        <th>Keterangan Acara</th>
        <th>Lapangan</th>
        <th>Tanggal</th>
        <th>Jam</th>
        <th>Diskon</th>
        <th>Total</th>
        <th>Tipe</th>
        <th>Aksi</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(b => {
        const discountPct = b.discount_percentage || 0;
        const totalAmt    = b.total_amount || 0;
        return `
        <tr>
          <td><span class="cell-id">${b.booking_id}</span></td>
          <td style="font-size:13px;font-weight:600;">${b.opd_organizations?.name || '—'}</td>
          <td style="font-size:13px;">${b.booked_for_label || b.notes || '—'}</td>
          <td>
            <div style="font-size:13px;font-weight:600;">${b.fields?.venue_name || '—'}</div>
            <div style="font-size:11px;color:var(--text-muted);">${b.fields?.venue_type || ''} · ${b.fields?.area || ''}</div>
          </td>
          <td style="white-space:nowrap;font-size:13px;">${fmtDate(b.booking_date)}</td>
          <td style="font-size:12px;">${fmtTime(b.start_time)} – ${fmtTime(b.end_time)}</td>
          <td>${_discountBadgeHtml(discountPct)}</td>
          <td style="font-size:13px;font-weight:700;white-space:nowrap;">
            ${totalAmt === 0
              ? '<span style="color:#10B981;font-weight:700;">Gratis</span>'
              : fmtRp(totalAmt)
            }
          </td>
          <td>
            <span class="badge" style="background:${b.booking_type === 'pimpinan' ? '#7C3AED' : '#F59E0B'};color:#fff;">
              ${b.booking_type === 'pimpinan' ? '👑 Pimpinan' : '🏛️ OPD'}
            </span>
          </td>
          <td>
            <button class="btn btn-danger btn-sm btn-icon" title="Hapus Blokir"
              onclick="cancelOPDBooking('${b.id}')">✕</button>
          </td>
        </tr>`;
      }).join('')}
    </tbody>
  </table>
  ${renderPagination(page, Math.ceil(count/10), count, 'loadOPDBookingsPage')}`;

  window.loadOPDBookingsPage = (p) => loadOPDBookingsTable(window._opdAPI, p);
}

// ── Submit form blokir ─────────────────────────────────────────
window.submitOPDBooking = async function(e) {
  e.preventDefault();
  const btn = document.getElementById('ob-submit-btn');
  btn.disabled = true;
  btn.textContent = 'Memproses...';

  try {
    const startTime = document.getElementById('ob-start').value;
    const duration  = parseInt(document.getElementById('ob-duration').value);
    const startH    = parseInt(startTime.split(':')[0]);
    const endTime   = `${(startH + duration).toString().padStart(2,'0')}:00`;

    // Ambil harga lapangan & diskon OPD dari data attribute
    const fieldSel     = document.getElementById('ob-field');
    const fieldOpt     = fieldSel?.options[fieldSel.selectedIndex];
    const pricePerHour = parseFloat(fieldOpt?.dataset?.price || 0);

    const opdSel    = document.getElementById('ob-opd');
    const opdOpt    = opdSel?.options[opdSel.selectedIndex];
    const discountPct = parseFloat(opdOpt?.dataset?.discount || 0);

    const payload = {
      booking_type:        document.getElementById('ob-type').value,
      opd_id:              document.getElementById('ob-opd').value || null,
      booked_for_label:    document.getElementById('ob-label').value.trim(),
      field_id:            document.getElementById('ob-field').value,
      booking_date:        document.getElementById('ob-date').value,
      start_time:          startTime,
      end_time:            endTime,
      duration_hours:      duration,
      notes:               document.getElementById('ob-notes').value.trim() || null,
      price_per_hour:      pricePerHour,
      discount_percentage: discountPct,
    };

    await window._opdAPI.createOPDBooking(payload);
    showToast('Jadwal berhasil diblokir! 🔒', 'success');
    document.getElementById('opd-booking-form').reset();
    _updateEndTime();
    // Reset UI state
    const badge = document.getElementById('ob-discount-badge');
    if (badge) badge.style.display = 'none';
    const preview = document.getElementById('ob-price-preview');
    if (preview) preview.style.display = 'none';
    await loadOPDBookingsTable(window._opdAPI, 1);
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.textContent = '🔒 Blokir Jadwal';
  }
};

// ── Batal blokir ──────────────────────────────────────────────
window.cancelOPDBooking = async function(id) {
  if (!confirm('Hapus blokir jadwal ini? Slot akan kembali tersedia untuk umum.')) return;
  try {
    await window._opdAPI.deleteOPDBooking(id);
    showToast('Blokir jadwal dihapus.', 'warning');
    await loadOPDBookingsTable(window._opdAPI, 1);
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error');
  }
};

// ── CRUD OPD ──────────────────────────────────────────────────
window.openOPDModal = function(opd = null) {
  const isEdit = opd !== null;
  document.getElementById('opd-modal-title').textContent = isEdit ? 'Edit OPD' : 'Tambah OPD';
  const discountVal = opd?.discount_percentage ?? 0;
  document.getElementById('opd-modal-body').innerHTML = `
    <div class="form-group">
      <label class="form-label">Nama OPD / Pimpinan <span style="color:var(--danger)">*</span></label>
      <input type="text" class="form-control" id="opd-name" value="${opd?.name || ''}"
        placeholder="Contoh: Dinas Pendidikan Kab. Bandung" required maxlength="120" />
    </div>
    <div class="form-group">
      <label class="form-label">Nama PIC</label>
      <input type="text" class="form-control" id="opd-pic" value="${opd?.contact_person || ''}"
        placeholder="Nama penanggung jawab" maxlength="80" />
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
      <div class="form-group">
        <label class="form-label">Telepon</label>
        <input type="text" class="form-control" id="opd-phone" value="${opd?.phone || ''}"
          placeholder="022-xxxxxxx" maxlength="20" />
      </div>
      <div class="form-group">
        <label class="form-label">Email</label>
        <input type="email" class="form-control" id="opd-email" value="${opd?.email || ''}"
          placeholder="dinas@bandungkab.go.id" maxlength="80" />
      </div>
    </div>

    <!-- ── Diskon ── -->
    <div class="form-group">
      <label class="form-label">
        🏷️ Diskon
        <span style="font-size:11px;font-weight:400;color:var(--text-muted);margin-left:6px;">
          Persentase diskon harga lapangan (0 = tidak ada diskon, 100 = gratis)
        </span>
      </label>
      <div style="display:flex;align-items:center;gap:12px;">
        <input type="range" id="opd-discount-range" min="0" max="100" step="5"
          value="${discountVal}"
          style="flex:1;accent-color:var(--primary,#A855F7);cursor:pointer;"
          oninput="document.getElementById('opd-discount-num').value=this.value;_syncDiscountPreview();" />
        <div style="display:flex;align-items:center;gap:4px;">
          <input type="number" id="opd-discount-num" min="0" max="100" value="${discountVal}"
            style="width:64px;text-align:center;"
            class="form-control"
            oninput="document.getElementById('opd-discount-range').value=this.value;_syncDiscountPreview();" />
          <span style="font-size:14px;font-weight:700;color:var(--text-muted);">%</span>
        </div>
      </div>
      <div id="opd-discount-preview-badge" style="margin-top:8px;"></div>
    </div>

    <div class="form-group">
      <label class="form-label">Status</label>
      <select class="form-control form-select" id="opd-active">
        <option value="true"  ${(!opd || opd.is_active) ? 'selected' : ''}>Aktif</option>
        <option value="false" ${opd && !opd.is_active   ? 'selected' : ''}>Nonaktif</option>
      </select>
    </div>
    <div class="modal-footer" style="padding:0;margin-top:4px;">
      <button class="btn btn-outline" onclick="closeModal('opd-modal')">Batal</button>
      <button class="btn btn-primary" onclick="saveOPD('${opd?.id || ''}')">
        ${isEdit ? 'Simpan Perubahan' : 'Tambah OPD'}
      </button>
    </div>`;
  openModal('opd-modal');
  // Init preview badge
  _syncDiscountPreview();
};

// Sync preview badge di modal saat slider berubah
window._syncDiscountPreview = function() {
  const pct = parseInt(document.getElementById('opd-discount-num')?.value || 0);
  const el = document.getElementById('opd-discount-preview-badge');
  if (!el) return;
  if (pct <= 0) { el.innerHTML = ''; return; }
  let msg = '', color = '#A855F7';
  if (pct === 100) { msg = '✅ Gratis sepenuhnya'; color = '#10B981'; }
  else if (pct >= 75) { msg = `🔥 Diskon besar ${pct}%`; color = '#EF4444'; }
  else if (pct >= 50) { msg = `🏷️ Diskon ${pct}%`; color = '#F59E0B'; }
  else { msg = `🏷️ Diskon ${pct}%`; color = '#A855F7'; }
  el.innerHTML = `<span style="font-size:12px;font-weight:700;color:${color};">${msg}</span>`;
};

window.editOPD = function(id) {
  const opd = _opdList.find(o => o.id === id);
  if (opd) window.openOPDModal(opd);
};

window.saveOPD = async function(id) {
  const discountRaw = parseInt(document.getElementById('opd-discount-num')?.value || 0);
  const discountPct = Math.min(100, Math.max(0, isNaN(discountRaw) ? 0 : discountRaw));

  const payload = {
    name:                document.getElementById('opd-name').value.trim(),
    contact_person:      document.getElementById('opd-pic').value.trim() || null,
    phone:               document.getElementById('opd-phone').value.trim() || null,
    email:               document.getElementById('opd-email').value.trim() || null,
    discount_percentage: discountPct,
    is_active:           document.getElementById('opd-active').value === 'true',
  };
  if (!payload.name) { showToast('Nama OPD wajib diisi.', 'warning'); return; }
  try {
    if (id) {
      await window._opdAPI.updateOPD(id, payload);
      showToast('OPD berhasil diperbarui! ✅', 'success');
    } else {
      await window._opdAPI.createOPD(payload);
      showToast('OPD berhasil ditambahkan! ✅', 'success');
    }
    closeModal('opd-modal');
    await _loadOPDList(window._opdAPI);
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error');
  }
};

window.deleteOPD = async function(id, name) {
  if (!confirm(`Hapus OPD "${name}"? Tindakan ini tidak dapat dibatalkan.`)) return;
  try {
    await window._opdAPI.deleteOPD(id);
    showToast('OPD dihapus.', 'warning');
    await _loadOPDList(window._opdAPI);
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error');
  }
};
