// ─────────────────────────────────────────────────────
// ANALYTICS VIEW
// ─────────────────────────────────────────────────────

async function renderAnalytics(api, container) {
  container.innerHTML = `<div class="page-loader"><span class="spinner spinner-lg"></span><span>Memuat analitik...</span></div>`;

  const [monthly12, byStatus, fields] = await Promise.all([
    api.getMonthlyRevenue(12),
    api.getBookingsByStatus(),
    api.getFields({ limit: 100 }),
  ]);

  const totalRevenue = monthly12.reduce((s, m) => s + m.revenue, 0);
  const totalBookings = monthly12.reduce((s, m) => s + m.bookings, 0);
  const avgRevPerMonth = totalRevenue / (monthly12.filter(m => m.revenue > 0).length || 1);
  const peakMonth = monthly12.reduce((max, m) => m.revenue > max.revenue ? m : max, monthly12[0] || { month: '—', revenue: 0 });

  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Analitik & Laporan</div>
      <div class="page-subtitle">Ringkasan performa bisnis SIPELOR BEDAS.</div>
    </div>
    <button class="btn btn-outline btn-sm" onclick="printAnalytics()">🖨️ Cetak Laporan</button>
  </div>

  <!-- KPI Row -->
  <div class="metric-row">
    ${metricChip('💰', fmtRp(totalRevenue), 'Total Pendapatan (12 bln)')}
    ${metricChip('📋', totalBookings.toString(), 'Total Pemesanan')}
    ${metricChip('📈', fmtRp(Math.round(avgRevPerMonth)), 'Rata-rata/Bulan')}
    ${metricChip('🏆', peakMonth.month, 'Bulan Terbaik')}
  </div>

  <!-- Revenue Trend -->
  <div class="card mb-4" style="margin-bottom:20px;">
    <div class="card-header">
      <div>
        <div class="card-title">Tren Pendapatan — 12 Bulan Terakhir</div>
        <div class="card-subtitle">Total: ${fmtRp(totalRevenue)}</div>
      </div>
    </div>
    <div class="card-body">
      <div class="chart-container lg"><canvas id="an-revenue-chart"></canvas></div>
    </div>
  </div>

  <div class="grid-2" style="margin-bottom:20px;">
    <!-- Booking by Status -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">Distribusi Status Pemesanan</div>
      </div>
      <div class="card-body" style="display:flex;align-items:center;gap:24px;">
        <div class="chart-container sm" style="width:180px;flex-shrink:0;">
          <canvas id="an-status-chart"></canvas>
        </div>
        <div style="flex:1;">
          ${statusRow('✅','Dikonfirmasi', byStatus.confirmed, 'var(--success)')}
          ${statusRow('🏁','Selesai',      byStatus.completed, 'var(--info)')}
          ${statusRow('⏳','Menunggu',     byStatus.pending,   'var(--warning)')}
          ${statusRow('❌','Dibatalkan',   byStatus.cancelled, 'var(--danger)')}
        </div>
      </div>
    </div>

    <!-- Booking Trend Line -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">Volume Pemesanan per Bulan</div>
      </div>
      <div class="card-body">
        <div class="chart-container sm"><canvas id="an-booking-chart"></canvas></div>
      </div>
    </div>
  </div>

  <!-- Field Utilization -->
  <div class="card">
    <div class="card-header">
      <div class="card-title">Status Lapangan Saat Ini</div>
      <div class="card-subtitle">${fields.data?.length || 0} lapangan terdaftar</div>
    </div>
    <div class="card-body">
      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:14px;">
        ${(fields.data || []).map(f => `
        <div style="background:var(--bg-page);border-radius:var(--radius);padding:14px;border:1px solid var(--border);">
          <div style="font-weight:700;font-size:13px;margin-bottom:4px;">${f.venue_name}</div>
          <div style="font-size:12px;color:var(--text-muted);margin-bottom:8px;">${f.venue_type} · ${f.area}</div>
          ${fieldStatusBadge(f.status)}
          <div style="font-size:12px;font-weight:600;color:var(--success);margin-top:6px;">${fmtRp(f.price_per_hour)}/jam</div>
        </div>`).join('')}
      </div>
    </div>
  </div>`;

  // ── Draw Charts ──────────────────────────────────────
  // Revenue trend (line)
  const revCtx = document.getElementById('an-revenue-chart');
  if (revCtx && window.Chart) {
    const grad = revCtx.getContext('2d').createLinearGradient(0, 0, 0, 380);
    grad.addColorStop(0, 'rgba(124,58,237,0.30)');
    grad.addColorStop(1, 'rgba(124,58,237,0)');
    new Chart(revCtx, {
      type: 'line',
      data: {
        labels: monthly12.map(m => m.month),
        datasets: [{
          label: 'Pendapatan',
          data: monthly12.map(m => m.revenue),
          fill: true,
          backgroundColor: grad,
          borderColor: '#7C3AED',
          borderWidth: 3,
          tension: 0.4,
          pointBackgroundColor: '#7C3AED',
          pointRadius: 4,
          pointHoverRadius: 7,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => ` ${fmtRp(ctx.parsed.y)}` }}},
        scales: {
          x: { grid: { display: false }, border: { display: false } },
          y: { beginAtZero: true, border: { display: false }, grid: { color: '#F0F2F8' }, ticks: { callback: v => `Rp${(v/1000000).toFixed(1)}jt` }},
        },
      },
    });
  }

  // Status pie
  const statusCtx = document.getElementById('an-status-chart');
  if (statusCtx && window.Chart) {
    new Chart(statusCtx, {
      type: 'doughnut',
      data: {
        labels: ['Dikonfirmasi','Selesai','Menunggu','Dibatalkan'],
        datasets: [{
          data: [byStatus.confirmed, byStatus.completed, byStatus.pending, byStatus.cancelled],
          backgroundColor: ['#10B981','#3B82F6','#F59E0B','#EF4444'],
          borderWidth: 0, hoverOffset: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        cutout: '68%',
        plugins: { legend: { display: false }},
      },
    });
  }

  // Booking volume (bar)
  const bkCtx = document.getElementById('an-booking-chart');
  if (bkCtx && window.Chart) {
    new Chart(bkCtx, {
      type: 'bar',
      data: {
        labels: monthly12.map(m => m.month),
        datasets: [{
          label: 'Pemesanan',
          data: monthly12.map(m => m.bookings),
          backgroundColor: 'rgba(59,130,246,0.75)',
          borderColor: '#3B82F6',
          borderWidth: 2,
          borderRadius: 6,
        }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false }},
        scales: {
          x: { grid: { display: false }, border: { display: false } },
          y: { beginAtZero: true, border: { display: false }, grid: { color: '#F0F2F8' }},
        },
      },
    });
  }
}

window.printAnalytics = function() {
  window.print();
};

function metricChip(icon, value, label) {
  return `<div class="metric-chip">
    <div style="font-size:22px;margin-bottom:4px;">${icon}</div>
    <div class="mc-value">${value}</div>
    <div class="mc-label">${label}</div>
  </div>`;
}

function statusRow(icon, label, count, color) {
  const total = 100;
  return `<div style="margin-bottom:12px;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;">
      <span style="font-size:13px;">${icon} ${label}</span>
      <span style="font-weight:700;font-size:13px;">${count}</span>
    </div>
    <div style="height:6px;background:var(--border);border-radius:3px;overflow:hidden;">
      <div style="height:100%;width:${Math.min(count,100)}%;background:${color};border-radius:3px;transition:width 0.6s ease;"></div>
    </div>
  </div>`;
}
