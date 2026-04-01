// ─────────────────────────────────────────────────────
// REPORTS VIEW — Cetak Laporan Lengkap SIPELOR BEDAS
// ─────────────────────────────────────────────────────

let _repType = 'summary';
let _repFrom = '';
let _repTo   = '';
let _repData = null;
let _repGenerating = false;

async function renderReports(api, container) {
  const today = new Date();
  if (!_repFrom) _repFrom = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split('T')[0];
  if (!_repTo)   _repTo   = today.toISOString().split('T')[0];

  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Cetak Laporan</div>
      <div class="page-subtitle">Buat, pratinjau, dan cetak laporan operasional SIPELOR BEDAS.</div>
    </div>
    <div class="flex gap-2">
      <button class="btn btn-outline btn-sm" id="btn-export-csv-rep" onclick="exportReportCSV()">
        <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        Export CSV
      </button>
      <button class="btn btn-primary btn-sm" onclick="printReport()">
        <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
        Cetak / Print
      </button>
    </div>
  </div>

  <!-- Report Config Card -->
  <div class="card" style="margin-bottom:20px;">
    <div class="card-body">
      <div class="report-config-grid">

        <!-- Report Type -->
        <div class="form-group" style="margin-bottom:0;">
          <label class="form-label">Jenis Laporan</label>
          <select class="form-control form-select" id="rep-type" onchange="onRepTypeChange(this.value)">
            <option value="summary"  ${_repType==='summary' ?'selected':''}>📊 Ringkasan Eksekutif</option>
            <option value="bookings" ${_repType==='bookings'?'selected':''}>📋 Laporan Pemesanan</option>
            <option value="revenue"  ${_repType==='revenue' ?'selected':''}>💰 Laporan Pendapatan</option>
            <option value="reviews"  ${_repType==='reviews' ?'selected':''}>⭐ Laporan Review</option>
          </select>
        </div>

        <!-- Date From -->
        <div class="form-group" style="margin-bottom:0;">
          <label class="form-label">Dari Tanggal</label>
          <input type="date" class="form-control" id="rep-from" value="${_repFrom}"
            onchange="_repFrom=this.value" style="padding:9px 12px;" />
        </div>

        <!-- Date To -->
        <div class="form-group" style="margin-bottom:0;">
          <label class="form-label">Sampai Tanggal</label>
          <input type="date" class="form-control" id="rep-to" value="${_repTo}"
            onchange="_repTo=this.value" style="padding:9px 12px;" />
        </div>

        <!-- Generate Button -->
        <div class="form-group" style="margin-bottom:0;display:flex;align-items:flex-end;">
          <button class="btn btn-gradient" style="width:100%;" onclick="generateReport()">
            <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
            Buat Laporan
          </button>
        </div>
      </div>

      <!-- Quick Date Presets -->
      <div style="margin-top:14px;display:flex;flex-wrap:wrap;gap:8px;align-items:center;">
        <span style="font-size:12px;color:var(--text-muted);font-weight:600;">Periode Cepat:</span>
        ${['Hari Ini','Minggu Ini','Bulan Ini','Bulan Lalu','3 Bulan','6 Bulan','Tahun Ini'].map((label, i) =>
          `<button class="btn btn-outline btn-sm" style="font-size:11px;padding:4px 10px;"
            onclick="setRepPreset(${i})">${label}</button>`
        ).join('')}
      </div>
    </div>
  </div>

  <!-- Preview Area -->
  <div id="report-preview-wrap">
    <div class="page-loader"><span class="spinner"></span><span style="margin-top:8px;font-size:13px;">Membuat laporan...</span></div>
  </div>`;

  window._reportAPI = api;
  generateReport();
}

/* ── Preset Date Ranges ─────────────────────────────── */
window.setRepPreset = function(idx) {
  const now = new Date();
  const y = now.getFullYear(), m = now.getMonth();
  const fmt = d => d.toISOString().split('T')[0];
  const presets = [
    // Hari Ini
    [fmt(now), fmt(now)],
    // Minggu Ini (Mon–Sun)
    [fmt(new Date(now - ((now.getDay()||7)-1)*86400000)), fmt(new Date(now.setDate(now.getDate()+(7-(now.getDay()||7)))))],
    // Bulan Ini
    [fmt(new Date(y,m,1)), fmt(new Date(y,m+1,0))],
    // Bulan Lalu
    [fmt(new Date(y,m-1,1)), fmt(new Date(y,m,0))],
    // 3 Bulan
    [fmt(new Date(y,m-2,1)), fmt(new Date(y,m+1,0))],
    // 6 Bulan
    [fmt(new Date(y,m-5,1)), fmt(new Date(y,m+1,0))],
    // Tahun Ini
    [fmt(new Date(y,0,1)), fmt(new Date(y,11,31))],
  ];
  const now2 = new Date(); // re-create since we mutated above for week calc
  const p = presets[idx];
  _repFrom = p[0]; _repTo = p[1];
  const f = document.getElementById('rep-from');
  const t = document.getElementById('rep-to');
  if (f) f.value = _repFrom;
  if (t) t.value = _repTo;
  generateReport();
};

window.onRepTypeChange = function(val) {
  _repType = val;
};

/* ── Generate Report ─────────────────────────────────── */
window.generateReport = async function() {
  if (_repGenerating) return;
  _repGenerating = true;
  _repType = document.getElementById('rep-type')?.value || _repType;
  _repFrom = document.getElementById('rep-from')?.value || _repFrom;
  _repTo   = document.getElementById('rep-to')?.value   || _repTo;

  const wrap = document.getElementById('report-preview-wrap');
  if (!wrap) { _repGenerating = false; return; }
  wrap.innerHTML = `<div class="page-loader" style="padding:48px 0;"><span class="spinner"></span><span style="margin-top:10px;font-size:13px;color:var(--text-muted);">Mengambil data...</span></div>`;

  try {
    const api = window._reportAPI;
    let data = {};

    if (_repType === 'summary') {
      data = await _fetchSummaryData(api);
    } else if (_repType === 'bookings') {
      data = await _fetchBookingsData(api);
    } else if (_repType === 'revenue') {
      data = await _fetchRevenueData(api);
    } else if (_repType === 'reviews') {
      data = await _fetchReviewsData(api);
    }

    _repData = { type: _repType, from: _repFrom, to: _repTo, data, generatedAt: new Date() };
    wrap.innerHTML = _buildPreview(_repData);
  } catch (e) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div>
      <h3>Gagal membuat laporan</h3><p style="color:var(--text-muted);font-size:13px;">${e.message}</p>
      <button class="btn btn-outline btn-sm" style="margin-top:12px;" onclick="generateReport()">Coba Lagi</button></div>`;
  }
  _repGenerating = false;
};

/* ── Data Fetchers ──────────────────────────────────── */
async function _fetchSummaryData(api) {
  const [stats, byStatus, monthly, fields] = await Promise.all([
    api.getDashboardStats(),
    api.getBookingsByStatus(),
    api.getMonthlyRevenue(12),
    api.getFields({ limit: 100 }),
  ]);
  const revenue12 = monthly.reduce((s, m) => s + m.revenue, 0);
  return { stats, byStatus, monthly, fields: fields.data || [], revenue12 };
}

async function _fetchBookingsData(api) {
  const { data, count } = await api.getBookings({
    page: 1, limit: 500,
    dateFrom: _repFrom, dateTo: _repTo,
  });
  return { bookings: data || [], count };
}

async function _fetchRevenueData(api) {
  const monthly = await api.getMonthlyRevenue(12);
  const annual  = await api.getAnnualRevenue();
  const fields  = await api.getFields({ limit: 100 });
  return { monthly, annual, fields: fields.data || [] };
}

async function _fetchReviewsData(api) {
  const { data, count } = await api.getReviews({ page: 1, limit: 500 });
  const ratings = [1,2,3,4,5].map(r => ({
    rating: r,
    count: (data || []).filter(rv => rv.rating === r).length,
  }));
  const avg = data?.length
    ? (data.reduce((s, r) => s + (r.rating || 0), 0) / data.length).toFixed(1)
    : '—';
  return { reviews: data || [], count, ratings, avg };
}

/* ── Preview Builder ─────────────────────────────────── */
function _buildPreview(rep) {
  const { type, from, to, data, generatedAt } = rep;
  const typeLabel = { summary:'Ringkasan Eksekutif', bookings:'Laporan Pemesanan', revenue:'Laporan Pendapatan', reviews:'Laporan Review' }[type];
  const periodStr = `${fmtDate(from)} s/d ${fmtDate(to)}`;

  return `
  <div class="report-paper">
    <!-- Paper Header -->
    <div class="report-paper-header">
      <div class="rph-left">
        <div class="rph-logo">🏟️</div>
        <div>
          <div class="rph-org">PEMERINTAH KABUPATEN BANDUNG</div>
          <div class="rph-dept">DINAS KEPEMUDAAN DAN OLAHRAGA</div>
          <div class="rph-sys">SIPELOR BEDAS — Sistem Pemesanan Lapangan Olahraga</div>
        </div>
      </div>
      <div class="rph-right">
        <div class="rph-type">${typeLabel.toUpperCase()}</div>
        <div class="rph-period">Periode: ${periodStr}</div>
        <div class="rph-gen">Dibuat: ${generatedAt.toLocaleDateString('id-ID', {day:'numeric',month:'long',year:'numeric',hour:'2-digit',minute:'2-digit'})}</div>
      </div>
    </div>
    <div class="report-paper-divider"></div>

    <!-- Paper Body -->
    <div class="report-paper-body">
      ${type === 'summary'  ? _renderSummaryPreview(data)  : ''}
      ${type === 'bookings' ? _renderBookingsPreview(data)  : ''}
      ${type === 'revenue'  ? _renderRevenuePreview(data)   : ''}
      ${type === 'reviews'  ? _renderReviewsPreview(data)   : ''}
    </div>

    <!-- Paper Footer -->
    <div class="report-paper-footer">
      <span>Admin: <strong>${currentUser?.name || '—'}</strong></span>
      <span>Dicetak dari SIPELOR BEDAS Admin Panel</span>
      <span>${generatedAt.toLocaleString('id-ID')}</span>
    </div>
  </div>`;
}

/* ── Preview: Summary ────────────────────────────────── */
function _renderSummaryPreview(d) {
  const total = (d.byStatus.confirmed || 0) + (d.byStatus.completed || 0) +
                (d.byStatus.pending || 0) + (d.byStatus.cancelled || 0);
  const pct = n => total ? Math.round((n / total) * 100) : 0;

  return `
  <div class="rep-section-title">Indikator Kinerja Utama</div>
  <div class="rep-kpi-grid">
    ${_kpi('💰', 'Total Pendapatan', fmtRp(d.stats.totalRevenue),'var(--success)')}
    ${_kpi('📋', 'Total Pemesanan',  d.stats.totalBookings,'var(--primary)')}
    ${_kpi('👥', 'Total Pengguna',   d.stats.totalUsers,'var(--info)')}
    ${_kpi('🏟️', 'Lapangan Aktif',   d.stats.totalFields,'var(--warning)')}
    ${_kpi('⏳', 'Menunggu Verif.',  d.stats.pendingPayments,'var(--danger)')}
    ${_kpi('📈', 'Pendapatan 12Bln', fmtRp(d.revenue12),'var(--primary)')}
  </div>

  <div class="rep-section-title" style="margin-top:24px;">Distribusi Status Pemesanan</div>
  <table class="rep-table">
    <thead><tr><th>Status</th><th>Jumlah</th><th>Persentase</th><th>Visualisasi</th></tr></thead>
    <tbody>
      ${_statusTableRow('✅ Dikonfirmasi', d.byStatus.confirmed, pct(d.byStatus.confirmed), '#10B981')}
      ${_statusTableRow('🏁 Selesai',       d.byStatus.completed, pct(d.byStatus.completed), '#3B82F6')}
      ${_statusTableRow('⏳ Menunggu',      d.byStatus.pending,   pct(d.byStatus.pending),   '#F59E0B')}
      ${_statusTableRow('❌ Dibatalkan',    d.byStatus.cancelled, pct(d.byStatus.cancelled), '#EF4444')}
      <tr class="rep-table-total"><td><strong>TOTAL</strong></td><td><strong>${total}</strong></td><td><strong>100%</strong></td><td></td></tr>
    </tbody>
  </table>

  <div class="rep-section-title" style="margin-top:24px;">Tren Pendapatan 12 Bulan Terakhir</div>
  <table class="rep-table">
    <thead><tr><th>Bulan</th><th>Pendapatan</th><th>Pemesanan</th><th>Visualisasi</th></tr></thead>
    <tbody>
      ${d.monthly.map(m => {
        const maxRev = Math.max(...d.monthly.map(x => x.revenue), 1);
        const barW = Math.round((m.revenue / maxRev) * 100);
        return `<tr>
          <td>${m.month}</td>
          <td style="font-weight:600;color:var(--success);">${fmtRp(m.revenue)}</td>
          <td>${m.bookings}</td>
          <td><div style="height:8px;background:var(--bg-hover);border-radius:4px;overflow:hidden;">
            <div style="height:100%;width:${barW}%;background:var(--primary);border-radius:4px;"></div>
          </div></td>
        </tr>`;
      }).join('')}
    </tbody>
  </table>

  <div class="rep-section-title" style="margin-top:24px;">Daftar Lapangan</div>
  <table class="rep-table">
    <thead><tr><th>Nama Lapangan</th><th>Jenis</th><th>Area</th><th>Harga/Jam</th><th>Status</th></tr></thead>
    <tbody>
      ${d.fields.map(f => `<tr>
        <td style="font-weight:600;">${f.venue_name}</td>
        <td>${f.venue_type}</td>
        <td>${f.area || '—'}</td>
        <td style="color:var(--success);font-weight:600;">${fmtRp(f.price_per_hour)}</td>
        <td>${f.status === 'available' ? '<span style="color:#10B981;font-weight:700;">● Tersedia</span>' :
              f.status === 'maintenance' ? '<span style="color:#F59E0B;font-weight:700;">● Maintenance</span>' :
              '<span style="color:#EF4444;font-weight:700;">● Booked</span>'}</td>
      </tr>`).join('')}
    </tbody>
  </table>`;
}

/* ── Preview: Bookings ───────────────────────────────── */
function _renderBookingsPreview(d) {
  const bookings = d.bookings || [];
  const totalRev = bookings.filter(b => b.payment_status === 'verified')
    .reduce((s, b) => s + (b.total_amount || 0), 0);
  const byStatus = {
    confirmed: bookings.filter(b => b.status === 'confirmed').length,
    completed: bookings.filter(b => b.status === 'completed').length,
    pending:   bookings.filter(b => b.status === 'pending').length,
    cancelled: bookings.filter(b => b.status === 'cancelled').length,
  };

  return `
  <div class="rep-kpi-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:20px;">
    ${_kpi('📋','Total Pemesanan',  bookings.length, 'var(--primary)')}
    ${_kpi('💰','Total Pendapatan', fmtRp(totalRev), 'var(--success)')}
    ${_kpi('✅','Dikonfirmasi',     byStatus.confirmed + byStatus.completed, 'var(--success)')}
    ${_kpi('❌','Dibatalkan',        byStatus.cancelled, 'var(--danger)')}
  </div>

  <div class="rep-section-title">Detail Pemesanan${bookings.length > 0 ? ` (${bookings.length} data)` : ''}</div>
  ${bookings.length === 0
    ? `<div style="text-align:center;padding:32px;color:var(--text-muted);">Tidak ada data pemesanan pada periode ini.</div>`
    : `<table class="rep-table">
        <thead>
          <tr>
            <th style="width:110px;">ID Pemesanan</th>
            <th>Pengguna</th>
            <th>Lapangan</th>
            <th>Tanggal</th>
            <th>Jam</th>
            <th>Total</th>
            <th>Status</th>
            <th>Pembayaran</th>
          </tr>
        </thead>
        <tbody>
          ${bookings.slice(0, 200).map(b => `<tr>
            <td style="font-size:11px;font-weight:700;color:var(--primary);">${b.booking_id}</td>
            <td>${b.user_name || '—'}</td>
            <td style="font-size:12px;">${b.fields?.venue_name || '—'}</td>
            <td style="white-space:nowrap;font-size:12px;">${fmtDate(b.booking_date)}</td>
            <td style="font-size:12px;white-space:nowrap;">${fmtTime(b.start_time)}–${fmtTime(b.end_time)}</td>
            <td style="font-weight:700;color:var(--success);white-space:nowrap;">${fmtRp(b.total_amount)}</td>
            <td><span style="font-size:11px;font-weight:700;color:${
              b.status==='completed'?'#3B82F6':b.status==='confirmed'?'#10B981':
              b.status==='pending'?'#F59E0B':'#EF4444'};">${
              b.status==='completed'?'Selesai':b.status==='confirmed'?'Konfirmasi':
              b.status==='pending'?'Menunggu':'Batal'}</span></td>
            <td><span style="font-size:11px;font-weight:700;color:${
              b.payment_status==='verified'?'#10B981':b.payment_status==='rejected'?'#EF4444':'#F59E0B'};">${
              b.payment_status==='verified'?'✓ Lunas':b.payment_status==='rejected'?'✕ Ditolak':'⏳ Proses'}</span></td>
          </tr>`).join('')}
        </tbody>
      </table>
      ${bookings.length > 200 ? `<div style="text-align:center;padding:10px;font-size:12px;color:var(--text-muted);">Menampilkan 200 dari ${bookings.length} data. Export CSV untuk data lengkap.</div>` : ''}`
  }`;
}

/* ── Preview: Revenue ────────────────────────────────── */
function _renderRevenuePreview(d) {
  const totalRevYear = d.annual.reduce((s, m) => s + m.revenue, 0);
  const totalRev12   = d.monthly.reduce((s, m) => s + m.revenue, 0);
  const peakMonth    = d.monthly.reduce((max, m) => m.revenue > max.revenue ? m : max, d.monthly[0] || { month:'—', revenue:0 });
  const avgPerMonth  = totalRev12 / (d.monthly.filter(m => m.revenue > 0).length || 1);

  return `
  <div class="rep-kpi-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:20px;">
    ${_kpi('💰','Total Tahun Ini',   fmtRp(totalRevYear), 'var(--success)')}
    ${_kpi('📈','Total 12 Bulan',    fmtRp(totalRev12),   'var(--primary)')}
    ${_kpi('📊','Rata-rata/Bulan',   fmtRp(Math.round(avgPerMonth)), 'var(--info)')}
    ${_kpi('🏆','Bulan Terbaik',     peakMonth.month,     'var(--warning)')}
  </div>

  <div class="rep-section-title">Pendapatan Per Bulan (12 Bulan Terakhir)</div>
  <table class="rep-table">
    <thead><tr><th>Bulan</th><th style="text-align:right;">Pendapatan</th><th>Vol. Pemesanan</th><th>Kontribusi</th></tr></thead>
    <tbody>
      ${d.monthly.map(m => {
        const pct = totalRev12 ? Math.round((m.revenue / totalRev12) * 100) : 0;
        return `<tr ${m.month === peakMonth.month ? 'style="background:var(--success-bg);"' : ''}>
          <td style="font-weight:600;">${m.month} ${m.month === peakMonth.month ? '🏆' : ''}</td>
          <td style="text-align:right;font-weight:700;color:var(--success);">${fmtRp(m.revenue)}</td>
          <td>${m.bookings}</td>
          <td>
            <div style="display:flex;align-items:center;gap:8px;">
              <div style="flex:1;height:8px;background:var(--bg-hover);border-radius:4px;overflow:hidden;">
                <div style="height:100%;width:${pct}%;background:var(--primary);border-radius:4px;"></div>
              </div>
              <span style="font-size:11px;font-weight:700;min-width:30px;">${pct}%</span>
            </div>
          </td>
        </tr>`;
      }).join('')}
      <tr class="rep-table-total">
        <td><strong>TOTAL</strong></td>
        <td style="text-align:right;"><strong>${fmtRp(totalRev12)}</strong></td>
        <td><strong>${d.monthly.reduce((s,m)=>s+m.bookings,0)}</strong></td>
        <td><strong>100%</strong></td>
      </tr>
    </tbody>
  </table>

  <div class="rep-section-title" style="margin-top:24px;">Harga Lapangan (Potensi Pendapatan)</div>
  <table class="rep-table">
    <thead><tr><th>Lapangan</th><th>Jenis</th><th>Harga/Jam</th><th>Status</th></tr></thead>
    <tbody>
      ${d.fields.map(f => `<tr>
        <td style="font-weight:600;">${f.venue_name}</td>
        <td>${f.venue_type}</td>
        <td style="font-weight:700;color:var(--success);">${fmtRp(f.price_per_hour)}</td>
        <td>${f.status === 'available' ? '✅ Tersedia' : f.status === 'maintenance' ? '🔧 Maintenance' : '📅 Booked'}</td>
      </tr>`).join('')}
    </tbody>
  </table>`;
}

/* ── Preview: Reviews ────────────────────────────────── */
function _renderReviewsPreview(d) {
  return `
  <div class="rep-kpi-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:20px;">
    ${_kpi('⭐','Rata-rata Rating', d.avg + '/5', 'var(--warning)')}
    ${_kpi('📝','Total Review',     d.count, 'var(--primary)')}
    ${_kpi('👍','Rating Bintang 5', d.ratings.find(r=>r.rating===5)?.count || 0, 'var(--success)')}
  </div>

  <div class="rep-section-title">Distribusi Rating</div>
  <table class="rep-table" style="margin-bottom:20px;">
    <thead><tr><th>Rating</th><th>Jumlah</th><th>Persentase</th><th>Visualisasi</th></tr></thead>
    <tbody>
      ${[5,4,3,2,1].map(r => {
        const item = d.ratings.find(x => x.rating === r) || { count: 0 };
        const pct  = d.count ? Math.round((item.count / d.count) * 100) : 0;
        return `<tr>
          <td>${'⭐'.repeat(r)} (${r})</td>
          <td style="font-weight:700;">${item.count}</td>
          <td>${pct}%</td>
          <td><div style="height:8px;background:var(--bg-hover);border-radius:4px;overflow:hidden;">
            <div style="height:100%;width:${pct}%;background:var(--warning);border-radius:4px;"></div>
          </div></td>
        </tr>`;
      }).join('')}
    </tbody>
  </table>

  <div class="rep-section-title">Daftar Review</div>
  ${d.reviews.length === 0
    ? `<div style="text-align:center;padding:32px;color:var(--text-muted);">Belum ada review.</div>`
    : `<table class="rep-table">
        <thead><tr><th>Pengguna</th><th>Rating</th><th>Komentar</th><th>Lapangan</th><th>Tanggal</th></tr></thead>
        <tbody>
          ${d.reviews.slice(0, 100).map(r => `<tr>
            <td style="font-weight:600;">${r.profiles?.full_name || '—'}</td>
            <td style="white-space:nowrap;">${'⭐'.repeat(Math.min(r.rating||0,5))} (${r.rating})</td>
            <td style="font-size:12px;max-width:240px;">${r.comment || '<em style="color:var(--text-muted)">—</em>'}</td>
            <td style="font-size:12px;">${r.bookings?.fields?.venue_name || r.venue_name || '—'}</td>
            <td style="font-size:12px;white-space:nowrap;color:var(--text-muted);">${fmtDate(r.created_at)}</td>
          </tr>`).join('')}
        </tbody>
      </table>`}`;
}

/* ── Helper Widgets ──────────────────────────────────── */
function _kpi(icon, label, value, color) {
  return `<div class="rep-kpi-card">
    <div class="rep-kpi-icon" style="color:${color};">${icon}</div>
    <div class="rep-kpi-value" style="color:${color};">${value}</div>
    <div class="rep-kpi-label">${label}</div>
  </div>`;
}

function _statusTableRow(label, count, pct, color) {
  return `<tr>
    <td>${label}</td>
    <td style="font-weight:700;">${count}</td>
    <td>${pct}%</td>
    <td><div style="height:8px;background:var(--bg-hover);border-radius:4px;overflow:hidden;">
      <div style="height:100%;width:${pct}%;background:${color};border-radius:4px;"></div>
    </div></td>
  </tr>`;
}

/* ── Print Window ────────────────────────────────────── */
window.printReport = function() {
  if (!_repData) { showToast('Buat laporan terlebih dahulu.', 'warning'); return; }
  const { type, from, to, data, generatedAt } = _repData;
  const typeLabel = { summary:'Ringkasan Eksekutif', bookings:'Laporan Pemesanan', revenue:'Laporan Pendapatan', reviews:'Laporan Review' }[type];
  const adminName = currentUser?.name || 'Admin';

  const html = _buildPrintHtml({ type, typeLabel, from, to, data, generatedAt, adminName });
  const win  = window.open('', '_blank', 'width=900,height=700');
  if (!win) { showToast('Pop-up diblokir browser. Izinkan pop-up untuk mencetak.', 'warning'); return; }
  win.document.write(html);
  win.document.close();
  win.onload = () => { win.focus(); win.print(); };
};

function _buildPrintHtml({ type, typeLabel, from, to, data, generatedAt, adminName }) {
  const periodStr = `${_fmtPrintDate(from)} s/d ${_fmtPrintDate(to)}`;

  let bodyContent = '';
  if (type === 'summary')  bodyContent = _printSummary(data);
  if (type === 'bookings') bodyContent = _printBookings(data);
  if (type === 'revenue')  bodyContent = _printRevenue(data);
  if (type === 'reviews')  bodyContent = _printReviews(data);

  return `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8"/>
  <title>Laporan ${typeLabel} — SIPELOR BEDAS</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: Arial, Helvetica, sans-serif; font-size: 11pt; color: #111; line-height: 1.5; padding: 20mm 18mm; }
    .header { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 12px; border-bottom: 3px solid #7C3AED; margin-bottom: 18px; }
    .header-left { display: flex; align-items: center; gap: 12px; }
    .logo-box { width: 52px; height: 52px; background: linear-gradient(135deg,#D946EF,#F97316); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 26px; }
    .org-name { font-size: 8.5pt; font-weight: 700; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }
    .dept-name { font-size: 11pt; font-weight: 800; color: #1A1535; }
    .sys-name  { font-size: 9pt; color: #7C3AED; font-weight: 600; }
    .header-right { text-align: right; }
    .rep-type   { font-size: 16pt; font-weight: 900; color: #1A1535; text-transform: uppercase; }
    .rep-period { font-size: 10pt; color: #555; margin-top: 4px; }
    .rep-num    { font-size: 9pt; color: #888; margin-top: 2px; }
    h2 { font-size: 12pt; font-weight: 800; color: #1A1535; border-bottom: 1.5px solid #E8EDF5; padding-bottom: 6px; margin: 18px 0 10px; }
    .kpi-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 10px; margin-bottom: 16px; }
    .kpi-card { border: 1.5px solid #E8EDF5; border-radius: 8px; padding: 12px 14px; background: #FAFAFA; }
    .kpi-label { font-size: 9pt; color: #666; margin-bottom: 2px; }
    .kpi-value { font-size: 16pt; font-weight: 900; }
    table { width: 100%; border-collapse: collapse; margin-top: 6px; font-size: 10pt; }
    th { background: #7C3AED; color: #fff; padding: 7px 8px; text-align: left; font-size: 9.5pt; font-weight: 700; }
    td { padding: 6px 8px; border-bottom: 1px solid #E8EDF5; vertical-align: top; }
    tr:nth-child(even) td { background: #F9F8FF; }
    .total-row td { background: #EDE8FF !important; font-weight: 700; border-top: 2px solid #7C3AED; }
    .bar-wrap { height: 7px; background: #E8EDF5; border-radius: 4px; overflow: hidden; min-width: 80px; }
    .bar-fill { height: 100%; border-radius: 4px; }
    .footer { border-top: 1px solid #ccc; margin-top: 24px; padding-top: 8px; display: flex; justify-content: space-between; font-size: 8.5pt; color: #888; }
    .badge-ok    { color: #059669; font-weight: 700; }
    .badge-warn  { color: #D97706; font-weight: 700; }
    .badge-err   { color: #DC2626; font-weight: 700; }
    .badge-info  { color: #2563EB; font-weight: 700; }
    @page { size: A4; margin: 10mm; }
    @media print {
      body { padding: 0; }
      .no-print { display: none !important; }
    }
  </style>
</head>
<body>
  <!-- Header -->
  <div class="header">
    <div class="header-left">
      <div class="logo-box">🏟️</div>
      <div>
        <div class="org-name">Pemerintah Kabupaten Bandung</div>
        <div class="dept-name">Dinas Kepemudaan dan Olahraga</div>
        <div class="sys-name">SIPELOR BEDAS — Sistem Pemesanan Lapangan Olahraga</div>
      </div>
    </div>
    <div class="header-right">
      <div class="rep-type">${typeLabel}</div>
      <div class="rep-period">Periode: ${periodStr}</div>
      <div class="rep-num">No. Dok: RPT-${generatedAt.getFullYear()}${String(generatedAt.getMonth()+1).padStart(2,'0')}-${type.toUpperCase()}</div>
    </div>
  </div>

  ${bodyContent}

  <!-- Footer -->
  <div class="footer">
    <span>Admin: <strong>${adminName}</strong></span>
    <span>SIPELOR BEDAS — Admin Panel</span>
    <span>Dicetak: ${generatedAt.toLocaleString('id-ID')}</span>
  </div>

  <div class="no-print" style="text-align:center;margin-top:20px;">
    <button onclick="window.print()" style="padding:10px 24px;background:#7C3AED;color:#fff;border:none;border-radius:8px;font-size:14px;cursor:pointer;">🖨️ Cetak Sekarang</button>
    <button onclick="window.close()" style="padding:10px 24px;background:#eee;color:#333;border:none;border-radius:8px;font-size:14px;cursor:pointer;margin-left:10px;">✕ Tutup</button>
  </div>
</body></html>`;
}

/* ── Print Content Builders ──────────────────────────── */
function _printSummary(d) {
  const total = (d.byStatus.confirmed||0)+(d.byStatus.completed||0)+(d.byStatus.pending||0)+(d.byStatus.cancelled||0);
  const pct   = n => total ? Math.round((n/total)*100) : 0;
  const maxRev = Math.max(...d.monthly.map(m => m.revenue), 1);

  return `
  <h2>Indikator Kinerja Utama</h2>
  <div class="kpi-grid">
    <div class="kpi-card"><div class="kpi-label">Total Pendapatan</div><div class="kpi-value" style="color:#059669;">${fmtRp(d.stats.totalRevenue)}</div></div>
    <div class="kpi-card"><div class="kpi-label">Total Pemesanan</div><div class="kpi-value" style="color:#7C3AED;">${d.stats.totalBookings}</div></div>
    <div class="kpi-card"><div class="kpi-label">Total Pengguna</div><div class="kpi-value" style="color:#2563EB;">${d.stats.totalUsers}</div></div>
    <div class="kpi-card"><div class="kpi-label">Lapangan Aktif</div><div class="kpi-value" style="color:#D97706;">${d.stats.totalFields}</div></div>
    <div class="kpi-card"><div class="kpi-label">Menunggu Verifikasi</div><div class="kpi-value" style="color:#DC2626;">${d.stats.pendingPayments}</div></div>
    <div class="kpi-card"><div class="kpi-label">Pendapatan 12 Bulan</div><div class="kpi-value" style="color:#059669;">${fmtRp(d.revenue12)}</div></div>
  </div>

  <h2>Distribusi Status Pemesanan</h2>
  <table><thead><tr><th>Status</th><th>Jumlah</th><th>Persentase</th><th>Visualisasi</th></tr></thead>
  <tbody>
    <tr><td>✅ Dikonfirmasi</td><td>${d.byStatus.confirmed}</td><td>${pct(d.byStatus.confirmed)}%</td><td><div class="bar-wrap"><div class="bar-fill" style="width:${pct(d.byStatus.confirmed)}%;background:#10B981;"></div></div></td></tr>
    <tr><td>🏁 Selesai</td><td>${d.byStatus.completed}</td><td>${pct(d.byStatus.completed)}%</td><td><div class="bar-wrap"><div class="bar-fill" style="width:${pct(d.byStatus.completed)}%;background:#3B82F6;"></div></div></td></tr>
    <tr><td>⏳ Menunggu</td><td>${d.byStatus.pending}</td><td>${pct(d.byStatus.pending)}%</td><td><div class="bar-wrap"><div class="bar-fill" style="width:${pct(d.byStatus.pending)}%;background:#F59E0B;"></div></div></td></tr>
    <tr><td>❌ Dibatalkan</td><td>${d.byStatus.cancelled}</td><td>${pct(d.byStatus.cancelled)}%</td><td><div class="bar-wrap"><div class="bar-fill" style="width:${pct(d.byStatus.cancelled)}%;background:#EF4444;"></div></div></td></tr>
    <tr class="total-row"><td>TOTAL</td><td>${total}</td><td>100%</td><td></td></tr>
  </tbody></table>

  <h2>Tren Pendapatan 12 Bulan Terakhir</h2>
  <table><thead><tr><th>Bulan</th><th>Pendapatan</th><th>Pemesanan</th><th>Visualisasi</th></tr></thead>
  <tbody>
    ${d.monthly.map(m => {
      const w = Math.round((m.revenue/maxRev)*100);
      return `<tr><td>${m.month}</td><td style="color:#059669;font-weight:700;">${fmtRp(m.revenue)}</td><td>${m.bookings}</td>
        <td><div class="bar-wrap"><div class="bar-fill" style="width:${w}%;background:#7C3AED;"></div></div></td></tr>`;
    }).join('')}
  </tbody></table>

  <h2>Daftar Lapangan</h2>
  <table><thead><tr><th>Nama Lapangan</th><th>Jenis</th><th>Area</th><th>Harga/Jam</th><th>Status</th></tr></thead>
  <tbody>
    ${d.fields.map(f => `<tr>
      <td style="font-weight:700;">${f.venue_name}</td><td>${f.venue_type}</td><td>${f.area||'—'}</td>
      <td style="font-weight:700;color:#059669;">${fmtRp(f.price_per_hour)}</td>
      <td class="${f.status==='available'?'badge-ok':f.status==='maintenance'?'badge-warn':'badge-err'}">${
        f.status==='available'?'✅ Tersedia':f.status==='maintenance'?'🔧 Maintenance':'📅 Booked'}</td>
    </tr>`).join('')}
  </tbody></table>`;
}

function _printBookings(d) {
  const bookings = d.bookings || [];
  const totalRev = bookings.filter(b=>b.payment_status==='verified').reduce((s,b)=>s+(b.total_amount||0),0);
  return `
  <div class="kpi-grid">
    <div class="kpi-card"><div class="kpi-label">Total Pemesanan</div><div class="kpi-value" style="color:#7C3AED;">${bookings.length}</div></div>
    <div class="kpi-card"><div class="kpi-label">Pendapatan Terverifikasi</div><div class="kpi-value" style="color:#059669;">${fmtRp(totalRev)}</div></div>
    <div class="kpi-card"><div class="kpi-label">Dikonfirmasi + Selesai</div><div class="kpi-value" style="color:#059669;">${bookings.filter(b=>['confirmed','completed'].includes(b.status)).length}</div></div>
  </div>
  <h2>Detail Pemesanan${bookings.length>0?' ('+bookings.length+' data)':''}</h2>
  ${bookings.length === 0
    ? '<p style="text-align:center;padding:20px;color:#888;">Tidak ada data pada periode ini.</p>'
    : `<table><thead><tr><th>ID</th><th>Pengguna</th><th>Lapangan</th><th>Tanggal</th><th>Jam</th><th>Total</th><th>Status</th><th>Bayar</th></tr></thead>
      <tbody>${bookings.map(b=>`<tr>
        <td style="font-size:9pt;font-weight:700;color:#7C3AED;">${b.booking_id}</td>
        <td>${b.user_name||'—'}</td>
        <td style="font-size:9.5pt;">${b.fields?.venue_name||'—'}</td>
        <td style="white-space:nowrap;font-size:9.5pt;">${fmtDate(b.booking_date)}</td>
        <td style="font-size:9pt;white-space:nowrap;">${fmtTime(b.start_time)}–${fmtTime(b.end_time)}</td>
        <td style="font-weight:700;color:#059669;white-space:nowrap;">${fmtRp(b.total_amount)}</td>
        <td class="${b.status==='completed'||b.status==='confirmed'?'badge-ok':b.status==='pending'?'badge-warn':'badge-err'}">${
          b.status==='completed'?'Selesai':b.status==='confirmed'?'Konfirmasi':b.status==='pending'?'Menunggu':'Batal'}</td>
        <td class="${b.payment_status==='verified'?'badge-ok':b.payment_status==='rejected'?'badge-err':'badge-warn'}">${
          b.payment_status==='verified'?'✓ Lunas':b.payment_status==='rejected'?'✕ Tolak':'⏳'}</td>
      </tr>`).join('')}</tbody></table>`}`;
}

function _printRevenue(d) {
  const total = d.monthly.reduce((s,m)=>s+m.revenue,0);
  const maxRev = Math.max(...d.monthly.map(m=>m.revenue),1);
  return `
  <div class="kpi-grid">
    <div class="kpi-card"><div class="kpi-label">Total 12 Bulan</div><div class="kpi-value" style="color:#059669;">${fmtRp(total)}</div></div>
    <div class="kpi-card"><div class="kpi-label">Rata-rata/Bulan</div><div class="kpi-value" style="color:#7C3AED;">${fmtRp(Math.round(total/(d.monthly.filter(m=>m.revenue>0).length||1)))}</div></div>
    <div class="kpi-card"><div class="kpi-label">Bulan Terbaik</div><div class="kpi-value" style="color:#D97706;">${d.monthly.reduce((max,m)=>m.revenue>max.revenue?m:max,d.monthly[0]||{month:'—',revenue:0}).month}</div></div>
  </div>
  <h2>Pendapatan Per Bulan (12 Bulan Terakhir)</h2>
  <table><thead><tr><th>Bulan</th><th>Pendapatan</th><th>Pemesanan</th><th>Kontribusi</th><th>Visualisasi</th></tr></thead>
  <tbody>
    ${d.monthly.map(m=>{
      const pct=total?Math.round((m.revenue/total)*100):0;
      const w=Math.round((m.revenue/maxRev)*100);
      return `<tr><td style="font-weight:700;">${m.month}</td>
        <td style="font-weight:700;color:#059669;">${fmtRp(m.revenue)}</td>
        <td>${m.bookings}</td><td style="font-weight:700;">${pct}%</td>
        <td><div class="bar-wrap"><div class="bar-fill" style="width:${w}%;background:#7C3AED;"></div></div></td></tr>`;
    }).join('')}
    <tr class="total-row"><td>TOTAL</td><td>${fmtRp(total)}</td><td>${d.monthly.reduce((s,m)=>s+m.bookings,0)}</td><td>100%</td><td></td></tr>
  </tbody></table>
  <h2>Daftar Lapangan & Tarif</h2>
  <table><thead><tr><th>Lapangan</th><th>Jenis</th><th>Tarif/Jam</th><th>Status</th></tr></thead>
  <tbody>${d.fields.map(f=>`<tr>
    <td style="font-weight:700;">${f.venue_name}</td><td>${f.venue_type}</td>
    <td style="font-weight:700;color:#059669;">${fmtRp(f.price_per_hour)}</td>
    <td class="${f.status==='available'?'badge-ok':f.status==='maintenance'?'badge-warn':'badge-err'}">${
      f.status==='available'?'✅ Tersedia':f.status==='maintenance'?'🔧 Maintenance':'📅 Booked'}</td>
  </tr>`).join('')}</tbody></table>`;
}

function _printReviews(d) {
  return `
  <div class="kpi-grid">
    <div class="kpi-card"><div class="kpi-label">Rata-rata Rating</div><div class="kpi-value" style="color:#D97706;">${d.avg}/5 ⭐</div></div>
    <div class="kpi-card"><div class="kpi-label">Total Review</div><div class="kpi-value" style="color:#7C3AED;">${d.count}</div></div>
    <div class="kpi-card"><div class="kpi-label">Rating 5 Bintang</div><div class="kpi-value" style="color:#059669;">${d.ratings.find(r=>r.rating===5)?.count||0}</div></div>
  </div>
  <h2>Distribusi Rating</h2>
  <table><thead><tr><th>Rating</th><th>Jumlah</th><th>Persentase</th><th>Visualisasi</th></tr></thead>
  <tbody>${[5,4,3,2,1].map(r=>{
    const item=d.ratings.find(x=>x.rating===r)||{count:0};
    const pct=d.count?Math.round((item.count/d.count)*100):0;
    return `<tr><td>${'⭐'.repeat(r)} (${r} bintang)</td><td style="font-weight:700;">${item.count}</td>
      <td>${pct}%</td><td><div class="bar-wrap"><div class="bar-fill" style="width:${pct}%;background:#F59E0B;"></div></div></td></tr>`;
  }).join('')}</tbody></table>
  <h2>Detail Review</h2>
  ${d.reviews.length===0?'<p style="text-align:center;padding:20px;color:#888;">Belum ada review.</p>':
  `<table><thead><tr><th>Pengguna</th><th>Rating</th><th>Komentar</th><th>Lapangan</th><th>Tanggal</th></tr></thead>
  <tbody>${d.reviews.slice(0,200).map(r=>`<tr>
    <td style="font-weight:700;">${r.profiles?.full_name||'—'}</td>
    <td style="white-space:nowrap;">${'⭐'.repeat(Math.min(r.rating||0,5))} (${r.rating})</td>
    <td style="font-size:9.5pt;">${r.comment||'—'}</td>
    <td style="font-size:9.5pt;">${r.bookings?.fields?.venue_name||r.venue_name||'—'}</td>
    <td style="font-size:9pt;white-space:nowrap;color:#888;">${fmtDate(r.created_at)}</td>
  </tr>`).join('')}</tbody></table>`}`;
}

/* ── CSV Export ──────────────────────────────────────── */
window.exportReportCSV = function() {
  if (!_repData) { showToast('Buat laporan terlebih dahulu.', 'warning'); return; }
  const { type, from, to, data } = _repData;
  let rows = [], filename = '';

  if (type === 'summary') {
    filename = `ringkasan_${from}_${to}.csv`;
    rows = [
      ['LAPORAN RINGKASAN EKSEKUTIF — SIPELOR BEDAS'],
      [`Periode: ${from} s/d ${to}`],
      [],
      ['INDIKATOR KINERJA'],
      ['Metrik','Nilai'],
      ['Total Pendapatan', data.stats.totalRevenue],
      ['Total Pemesanan', data.stats.totalBookings],
      ['Total Pengguna', data.stats.totalUsers],
      ['Lapangan Aktif', data.stats.totalFields],
      ['Menunggu Verifikasi', data.stats.pendingPayments],
      [],
      ['STATUS PEMESANAN'],
      ['Status','Jumlah'],
      ['Dikonfirmasi', data.byStatus.confirmed],
      ['Selesai', data.byStatus.completed],
      ['Menunggu', data.byStatus.pending],
      ['Dibatalkan', data.byStatus.cancelled],
      [],
      ['TREN PENDAPATAN'],
      ['Bulan','Pendapatan','Pemesanan'],
      ...data.monthly.map(m => [m.month, m.revenue, m.bookings]),
    ];
  } else if (type === 'bookings') {
    filename = `pemesanan_${from}_${to}.csv`;
    rows = [
      ['LAPORAN PEMESANAN — SIPELOR BEDAS'],
      [`Periode: ${from} s/d ${to}`],
      [],
      ['ID Pemesanan','Pengguna','Lapangan','Tanggal','Jam Mulai','Jam Selesai','Total','Status','Status Bayar'],
      ...(data.bookings||[]).map(b => [
        b.booking_id, b.user_name||'', b.fields?.venue_name||'',
        b.booking_date, b.start_time, b.end_time, b.total_amount,
        b.status, b.payment_status,
      ]),
    ];
  } else if (type === 'revenue') {
    filename = `pendapatan_${from}_${to}.csv`;
    rows = [
      ['LAPORAN PENDAPATAN — SIPELOR BEDAS'],
      [`Periode: ${from} s/d ${to}`],
      [],
      ['TREN PENDAPATAN'],
      ['Bulan','Pendapatan (Rp)','Jumlah Pemesanan'],
      ...data.monthly.map(m => [m.month, m.revenue, m.bookings]),
      [],
      ['LAPANGAN'],
      ['Nama Lapangan','Jenis','Area','Harga/Jam','Status'],
      ...(data.fields||[]).map(f => [f.venue_name, f.venue_type, f.area, f.price_per_hour, f.status]),
    ];
  } else if (type === 'reviews') {
    filename = `review_${from}_${to}.csv`;
    rows = [
      ['LAPORAN REVIEW — SIPELOR BEDAS'],
      [`Total Review: ${data.count}`, `Rata-rata Rating: ${data.avg}`],
      [],
      ['Pengguna','Email','Rating','Komentar','Lapangan','Tanggal'],
      ...(data.reviews||[]).map(r => [
        r.profiles?.full_name||'', r.profiles?.email||'',
        r.rating, r.comment||'',
        r.bookings?.fields?.venue_name||r.venue_name||'', r.created_at,
      ]),
    ];
  }

  const csvContent = rows.map(row =>
    row.map(cell => `"${String(cell||'').replace(/"/g,'""')}"`).join(',')
  ).join('\r\n');

  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast(`CSV berhasil diunduh: ${filename}`, 'success');
};

/* ── Utility ─────────────────────────────────────────── */
function _fmtPrintDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr + 'T00:00:00');
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
}
