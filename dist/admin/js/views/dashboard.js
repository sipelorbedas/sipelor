// ─────────────────────────────────────────────────────
// DASHBOARD VIEW
// ─────────────────────────────────────────────────────

async function renderDashboard(api, container) {
  container.innerHTML = `<div class="page-loader"><span class="spinner spinner-lg"></span><span>Memuat dashboard...</span></div>`;

  const [stats, recent, monthly, byStatus, annualMonthly] = await Promise.all([
    api.getDashboardStats(),
    api.getRecentBookings(7),
    api.getMonthlyRevenue(7),
    api.getBookingsByStatus(),
    api.getAnnualRevenue(),
  ]);

  const annualTotal  = annualMonthly.reduce((s, m) => s + m.revenue, 0);
  const annualTarget = api.getAnnualTarget();
  const annualPct    = annualTarget > 0 ? Math.min((annualTotal / annualTarget) * 100, 100) : 0;

  // Store for edit/save callbacks
  window._api         = api;
  window._annualTotal = annualTotal;

  const pendingBadge = stats.pendingPayments > 0
    ? `<span class="badge badge-warning" style="font-size:11px">${stats.pendingPayments} menunggu</span>` : '';

  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Dashboard</div>
      <div class="page-subtitle">Selamat datang kembali! Berikut ringkasan aktivitas SIPELOR BEDAS.</div>
    </div>
    <div class="flex gap-2 items-center">
      ${pendingBadge}
      <button class="btn btn-gradient btn-sm" onclick="navigate('bookings')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 5v14M5 12l7 7 7-7"/></svg>
        Lihat Semua Pemesanan
      </button>
    </div>
  </div>

  <!-- Stat Cards -->
  <div class="stats-grid">
    ${statCard('📋', 'Total Pemesanan', stats.totalBookings.toLocaleString('id-ID'), 'purple',
        '<svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M18 15l-6-6-6 6"/></svg> +12 bulan ini', 'up')}
    ${statCard('💰', 'Pendapatan Bulan ini', fmtRp(stats.totalRevenue), 'green',
        '<svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M18 15l-6-6-6 6"/></svg> +8.5% vs bulan lalu', 'up')}
    ${statCard('🏟️', 'Total Lapangan', stats.totalFields.toString(), 'orange',
        `<span style="color:var(--text-muted)">Aktif & tersedia</span>`, 'neutral')}
    ${statCard('👥', 'Total Pengguna', stats.totalUsers.toLocaleString('id-ID'), 'blue',
        '<svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M18 15l-6-6-6 6"/></svg> +23 minggu ini', 'up')}
  </div>

  <!-- Annual Revenue + Target Cards -->
  <div class="grid-2" style="margin-bottom:20px;">
    ${annualRevenueCard(annualMonthly, annualTotal)}
    ${annualTargetCard(annualTotal, annualTarget, annualPct)}
  </div>

  <!-- Charts + Recent -->
  <div class="grid-2" style="margin-bottom:20px;">
    <div class="card col-span-2" style="min-width:0;">
      <div class="card-header">
        <div>
          <div class="card-title">Grafik Pendapatan</div>
          <div class="card-subtitle">7 bulan terakhir</div>
        </div>
        <div class="flex gap-2">
          <button class="btn btn-outline btn-sm" id="chart-toggle-revenue" onclick="toggleChartView('revenue')">Revenue</button>
          <button class="btn btn-outline btn-sm" id="chart-toggle-bookings" onclick="toggleChartView('bookings')">Pemesanan</button>
        </div>
      </div>
      <div class="card-body">
        <div class="chart-container">
          <canvas id="chart-revenue"></canvas>
        </div>
      </div>
    </div>
  </div>

  <div class="grid-2">
    <!-- Recent Bookings -->
    <div class="card">
      <div class="card-header">
        <div>
          <div class="card-title">Pemesanan Terbaru</div>
          <div class="card-subtitle">Perlu tindakan segera</div>
        </div>
        <button class="btn btn-ghost btn-sm" onclick="navigate('bookings')">Lihat semua →</button>
      </div>
      <div class="card-body" style="padding:0;">
        <ul class="recent-list" style="padding:0 18px;">
          ${recent.map(b => `
          <li class="recent-item">
            <div class="recent-avatar">${(b.user_name || b.booking_id || 'U')[0].toUpperCase()}</div>
            <div class="recent-info">
              <div class="recent-name">${b.user_name || 'Pengguna'}</div>
              <div class="recent-meta">${b.fields?.venue_name || '—'} · ${fmtDate(b.booking_date)}</div>
            </div>
            <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;">
              <div class="recent-amount">${fmtRp(b.total_amount)}</div>
              ${bookingStatusBadge(b.status)}
            </div>
          </li>`).join('')}
        </ul>
      </div>
    </div>

    <!-- Status + Quick actions -->
    <div style="display:flex;flex-direction:column;gap:18px;">
      <!-- Booking Status Pie -->
      <div class="card" style="flex:1;">
        <div class="card-header">
          <div class="card-title">Status Pemesanan</div>
        </div>
        <div class="card-body" style="display:flex;align-items:center;gap:20px;">
          <div class="chart-container sm" style="width:160px;flex-shrink:0;">
            <canvas id="chart-status"></canvas>
          </div>
          <div style="flex:1;">
            ${legendItem('Dikonfirmasi', byStatus.confirmed, 'var(--success)')}
            ${legendItem('Selesai',      byStatus.completed, 'var(--info)')}
            ${legendItem('Menunggu',     byStatus.pending,   'var(--warning)')}
            ${legendItem('Dibatalkan',   byStatus.cancelled, 'var(--danger)')}
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="card">
        <div class="card-header">
          <div class="card-title">Aksi Cepat</div>
        </div>
        <div class="card-body" style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">
          ${quickAction('📋','Kelola Pemesanan','bookings','btn-primary')}
          ${quickAction('🏟️','Tambah Lapangan','fields','btn-success')}
          ${quickAction('👥','Kelola Staff','staff','btn-outline')}
          ${quickAction('📊','Laporan Analitik','analytics','btn-outline')}
          ${quickAction('⭐','Moderasi Review','reviews','btn-outline')}
          ${quickAction('📝','Audit Log','audit','btn-outline')}
        </div>
      </div>
    </div>
  </div>`;

  // ── Draw Charts ─────────────────────────────────────
  window._monthlyData = monthly;
  window._chartMode   = 'revenue';
  drawRevenueChart(monthly, 'revenue');

  // Pie chart — status
  const pie = document.getElementById('chart-status');
  if (pie && window.Chart) {
    const total = Object.values(byStatus).reduce((a, b) => a + b, 0) || 1;
    new Chart(pie, {
      type: 'doughnut',
      data: {
        labels: ['Dikonfirmasi','Selesai','Menunggu','Dibatalkan'],
        datasets: [{
          data: [byStatus.confirmed, byStatus.completed, byStatus.pending, byStatus.cancelled],
          backgroundColor: ['#10B981','#3B82F6','#F59E0B','#EF4444'],
          borderWidth: 0,
          hoverOffset: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        cutout: '70%',
        plugins: { legend: { display: false }, tooltip: { callbacks: {
          label: ctx => ` ${ctx.label}: ${ctx.parsed} (${Math.round(ctx.parsed/total*100)}%)`
        }}},
      },
    });
  }
}

function drawRevenueChart(data, mode) {
  const ctx = document.getElementById('chart-revenue');
  if (!ctx || !window.Chart) return;
  if (window._revenueChart) { window._revenueChart.destroy(); }

  const isRevenue = mode === 'revenue';
  const label  = isRevenue ? 'Pendapatan (Rp)' : 'Jumlah Pemesanan';
  const values = data.map(d => isRevenue ? d.revenue : d.bookings);
  const grad   = ctx.getContext('2d').createLinearGradient(0, 0, 0, 300);
  grad.addColorStop(0, 'rgba(124,58,237,0.25)');
  grad.addColorStop(1, 'rgba(124,58,237,0)');

  window._revenueChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: data.map(d => d.month),
      datasets: [{
        label,
        data: values,
        backgroundColor: isRevenue ? grad : 'rgba(59,130,246,0.7)',
        borderColor:     isRevenue ? '#7C3AED' : '#3B82F6',
        borderWidth: 2,
        borderRadius: 8,
        borderSkipped: false,
      }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { callbacks: {
        label: ctx => isRevenue ? ` ${fmtRp(ctx.parsed.y)}` : ` ${ctx.parsed.y} pemesanan`
      }}},
      scales: {
        x: { grid: { display: false }, border: { display: false } },
        y: {
          beginAtZero: true, border: { display: false },
          grid: { color: '#F0F2F8' },
          ticks: { callback: v => isRevenue ? `Rp${(v/1000).toFixed(0)}k` : v },
        },
      },
    },
  });
}

window.toggleChartView = function(mode) {
  window._chartMode = mode;
  drawRevenueChart(window._monthlyData, mode);
  document.getElementById('chart-toggle-revenue')?.classList.toggle('btn-primary', mode === 'revenue');
  document.getElementById('chart-toggle-revenue')?.classList.toggle('btn-outline', mode !== 'revenue');
  document.getElementById('chart-toggle-bookings')?.classList.toggle('btn-primary', mode === 'bookings');
  document.getElementById('chart-toggle-bookings')?.classList.toggle('btn-outline', mode !== 'bookings');
};

// ── Helpers ──────────────────────────────────────────
function statCard(icon, label, value, color, changeHtml, dir) {
  return `
  <div class="stat-card">
    <div class="stat-icon ${color}">${icon}</div>
    <div class="stat-info">
      <div class="stat-label">${label}</div>
      <div class="stat-value">${value}</div>
      <div class="stat-change ${dir}">${changeHtml}</div>
    </div>
  </div>`;
}

function legendItem(label, count, color) {
  return `
  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
    <div style="display:flex;align-items:center;gap:8px;font-size:13px;">
      <span style="width:10px;height:10px;border-radius:50%;background:${color};flex-shrink:0;display:inline-block;"></span>
      ${label}
    </div>
    <span style="font-weight:700;font-size:13px;">${count}</span>
  </div>`;
}

function quickAction(icon, label, view, btnClass) {
  return `<button class="btn ${btnClass} btn-sm" style="flex-direction:column;gap:6px;padding:14px 8px;height:auto;" onclick="navigate('${view}')">
    <span style="font-size:20px;">${icon}</span>
    <span style="font-size:11px;font-weight:600;">${label}</span>
  </button>`;
}

// ── Annual Revenue Card ───────────────────────────────────
function annualRevenueCard(monthlyData, total) {
  const year     = new Date().getFullYear();
  const nowMonth = new Date().getMonth(); // 0-based
  const maxRev   = Math.max(...monthlyData.map(m => m.revenue), 1);
  const hasMons  = monthlyData.filter(m => m.revenue > 0);
  const avgRev   = hasMons.length > 0
    ? Math.round(hasMons.reduce((s, m) => s + m.revenue, 0) / hasMons.length) : 0;
  const bestMonth = monthlyData.reduce((b, m) => m.revenue > b.revenue ? m : b, monthlyData[0]);

  const bars = monthlyData.map((m, i) => {
    const h       = Math.max(Math.round((m.revenue / maxRev) * 56), m.revenue > 0 ? 3 : 0);
    const cls     = i === nowMonth ? ' current' : i > nowMonth ? ' future' : '';
    const lblCls  = i === nowMonth ? ' current' : '';
    return `<div class="mbar-col" title="${m.month}: ${fmtRp(m.revenue)}">
      <div class="mbar-outer"><div class="mbar-fill${cls}" style="height:${h}px;"></div></div>
      <div class="mbar-lbl${lblCls}">${m.month.slice(0, 3)}</div>
    </div>`;
  }).join('');

  return `
  <div class="card">
    <div class="card-header" style="background:linear-gradient(135deg,rgba(16,185,129,0.06) 0%,transparent 100%);">
      <div>
        <div class="card-title">💵 Total Pendapatan ${year}</div>
        <div class="card-subtitle">Akumulasi pendapatan terverifikasi tahun ini</div>
      </div>
      <span class="badge badge-success" style="font-size:12px;">${year}</span>
    </div>
    <div class="card-body">
      <div style="font-size:28px;font-weight:800;color:var(--success);margin-bottom:6px;">${fmtRp(total)}</div>
      <div style="display:flex;gap:20px;flex-wrap:wrap;margin-bottom:16px;">
        <div>
          <div style="font-size:10px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.4px;">Rata-rata / Bln</div>
          <div style="font-size:13px;font-weight:700;color:var(--text-primary);">${fmtRp(avgRev)}</div>
        </div>
        ${bestMonth.revenue > 0 ? `<div>
          <div style="font-size:10px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.4px;">Bulan Terbaik</div>
          <div style="font-size:13px;font-weight:700;color:var(--text-primary);">${bestMonth.month} · ${fmtRp(bestMonth.revenue)}</div>
        </div>` : ''}
        <div>
          <div style="font-size:10px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.4px;">Bulan Tercatat</div>
          <div style="font-size:13px;font-weight:700;color:var(--text-primary);">${hasMons.length} / 12</div>
        </div>
      </div>
      <div class="monthly-bars-wrap">${bars}</div>
    </div>
  </div>`;
}

// ── Annual Target Card ────────────────────────────────────
function annualTargetCard(total, target, pct) {
  const year          = new Date().getFullYear();
  const remaining     = Math.max(0, target - total);
  const pctColor      = pct >= 100 ? 'var(--success)' : pct >= 75 ? 'var(--info)' : pct >= 50 ? 'var(--warning)' : 'var(--danger)';
  const pctBadgeCls   = pct >= 100 ? 'badge-success' : pct >= 75 ? 'badge-info' : pct >= 50 ? 'badge-warning' : 'badge-danger';
  const pctDisplay    = pct.toFixed(1);

  return `
  <div class="card" id="target-card">
    <div class="card-header">
      <div>
        <div class="card-title">🎯 Target Pendapatan Tahunan</div>
        <div class="card-subtitle">Target tahun ${year} · Dapat diedit</div>
      </div>
      <button class="btn btn-outline btn-sm" onclick="window.editAnnualTarget()" id="target-edit-btn">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
        Edit
      </button>
    </div>
    <div class="card-body">
      <!-- Display mode -->
      <div id="target-display-mode">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:14px;">
          <div id="target-amount-display" style="font-size:26px;font-weight:800;color:var(--text-primary);">${fmtRp(target)}</div>
          <span class="badge ${pctBadgeCls}" id="target-pct-badge" style="font-size:13px;padding:5px 12px;">${pctDisplay}%</span>
        </div>
        <div style="margin-bottom:12px;">
          <div style="display:flex;justify-content:space-between;font-size:12px;font-weight:600;color:var(--text-secondary);margin-bottom:6px;">
            <span>Pencapaian</span>
            <span id="target-progress-label">${fmtRp(total)} dari ${fmtRp(target)}</span>
          </div>
          <div class="target-progress-track">
            <div class="target-progress-fill" id="target-progress-fill" style="width:${Math.min(pct,100)}%;background:${pctColor};"></div>
          </div>
        </div>
        <div style="display:flex;justify-content:space-between;align-items:center;font-size:12.5px;">
          <span style="color:var(--text-secondary);">
            ${pct >= 100
              ? '<span style="color:var(--success);font-weight:700;">🎉 Target Tercapai!</span>'
              : `Sisa: <strong id="target-remaining">${fmtRp(remaining)}</strong>`}
          </span>
          <span style="color:var(--text-muted);font-size:11px;">💾 Tersimpan di perangkat ini</span>
        </div>
      </div>
      <!-- Edit mode -->
      <div id="target-edit-mode" style="display:none;">
        <div class="form-label" style="margin-bottom:6px;">Nominal Target (Rp)</div>
        <input type="number" id="target-input" class="form-control"
          placeholder="Contoh: 120000000" value="${target}"
          style="font-size:16px;font-weight:700;margin-bottom:8px;"
          onkeydown="if(event.key==='Enter')window.saveAnnualTarget();if(event.key==='Escape')window.cancelEditTarget();">
        <div style="font-size:11.5px;color:var(--text-muted);margin-bottom:14px;">Target disimpan di browser ini dan berlaku untuk semua sesi admin.</div>
        <div style="display:flex;gap:10px;">
          <button class="btn btn-success btn-sm" onclick="window.saveAnnualTarget()">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 6L9 17l-5-5"/></svg>
            Simpan Target
          </button>
          <button class="btn btn-outline btn-sm" onclick="window.cancelEditTarget()">Batal</button>
        </div>
      </div>
    </div>
  </div>`;
}

// ── Target edit / save / cancel ───────────────────────────
window.editAnnualTarget = function() {
  document.getElementById('target-display-mode').style.display = 'none';
  document.getElementById('target-edit-mode').style.display   = 'block';
  document.getElementById('target-edit-btn').style.display    = 'none';
  const inp = document.getElementById('target-input');
  if (inp) { inp.focus(); inp.select(); }
};

window.cancelEditTarget = function() {
  document.getElementById('target-display-mode').style.display = 'block';
  document.getElementById('target-edit-mode').style.display   = 'none';
  document.getElementById('target-edit-btn').style.display    = '';
};

window.saveAnnualTarget = function() {
  const raw    = document.getElementById('target-input')?.value || '';
  const amount = parseInt(String(raw).replace(/\D/g, ''), 10);
  if (!amount || amount <= 0) {
    document.getElementById('target-input')?.classList.add('error');
    return;
  }
  document.getElementById('target-input')?.classList.remove('error');
  window._api?.setAnnualTarget(amount);

  const total        = window._annualTotal || 0;
  const pct          = Math.min((total / amount) * 100, 100);
  const rem          = Math.max(0, amount - total);
  const pctColor     = pct >= 100 ? 'var(--success)' : pct >= 75 ? 'var(--info)' : pct >= 50 ? 'var(--warning)' : 'var(--danger)';
  const pctBadgeCls  = pct >= 100 ? 'badge-success' : pct >= 75 ? 'badge-info' : pct >= 50 ? 'badge-warning' : 'badge-danger';

  const amtEl  = document.getElementById('target-amount-display');
  const lblEl  = document.getElementById('target-progress-label');
  const fill   = document.getElementById('target-progress-fill');
  const badge  = document.getElementById('target-pct-badge');
  const remEl  = document.getElementById('target-remaining');

  if (amtEl)  amtEl.textContent  = fmtRp(amount);
  if (lblEl)  lblEl.textContent  = `${fmtRp(total)} dari ${fmtRp(amount)}`;
  if (fill)  { fill.style.width = `${pct}%`; fill.style.background = pctColor; }
  if (badge) { badge.textContent = `${pct.toFixed(1)}%`; badge.className = `badge ${pctBadgeCls}`; badge.style.cssText = 'font-size:13px;padding:5px 12px;'; }
  if (remEl)  remEl.textContent  = fmtRp(rem);

  window.cancelEditTarget();
  window.showToast('Target pendapatan tahunan berhasil disimpan! 🎯', 'success');
};
