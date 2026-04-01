// ─────────────────────────────────────────────────────
// AUDIT LOG VIEW
// ─────────────────────────────────────────────────────

let _aPage = 1, _aAction = '';

async function renderAudit(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Audit Log</div>
      <div class="page-subtitle">Rekam jejak seluruh aktivitas admin untuk keamanan dan compliance.</div>
    </div>
    <button class="btn btn-outline btn-sm" onclick="exportAuditLog()">📥 Export Log</button>
  </div>

  <div class="card">
    <div class="table-controls">
      <select class="form-control form-select" style="width:auto;padding:8px 36px 8px 12px;font-size:13px;" onchange="filterAudit('action',this.value)">
        <option value="">Semua Aksi</option>
        <option value="booking_approved">Booking Dikonfirmasi</option>
        <option value="booking_rejected">Booking Ditolak</option>
        <option value="payment_verified">Pembayaran Diverifikasi</option>
        <option value="field_updated">Lapangan Diperbarui</option>
        <option value="staff_added">Staff Ditambahkan</option>
        <option value="review_deleted">Review Dihapus</option>
        <option value="user_login">Login Admin</option>
      </select>
    </div>

    <div class="table-wrap" id="audit-table-wrap">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
    <div id="audit-pagination"></div>
  </div>`;

  loadAuditTable(api);
  window._auditAPI = api;
}

async function loadAuditTable(api, page = _aPage) {
  _aPage = page;
  const wrap = document.getElementById('audit-table-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  const { data, count } = await api.getAuditLogs({ page: _aPage, limit: 15, action: _aAction });

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">📝</div><h3>Belum ada log</h3></div>`;
    document.getElementById('audit-pagination').innerHTML = '';
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>Waktu</th>
        <th>Admin</th>
        <th>Aksi</th>
        <th>Entitas</th>
        <th>Detail</th>
        <th>IP Address</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(log => `
      <tr>
        <td style="font-size:12px;color:var(--text-muted);white-space:nowrap;">${fmtDateTime(log.created_at)}</td>
        <td>
          <div class="flex items-center gap-2">
            <div class="avatar-sm" style="width:26px;height:26px;font-size:11px;">${(log.profiles?.full_name || 'A')[0]}</div>
            <div style="font-size:13px;font-weight:600;">${log.profiles?.full_name || '—'}</div>
          </div>
        </td>
        <td>${auditActionBadge(log.action)}</td>
        <td style="font-size:12px;color:var(--text-muted);">${log.entity_type || '—'}</td>
        <td style="font-size:12px;max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="${safeJson(log.details)}">${safeJson(log.details)}</td>
        <td style="font-family:monospace;font-size:12px;color:var(--text-muted);">${log.ip_address || '—'}</td>
      </tr>`).join('')}
    </tbody>
  </table>`;

  const totalPages = Math.ceil(count / 15);
  document.getElementById('audit-pagination').innerHTML = renderPagination(_aPage, totalPages, count, 'loadAuditPage');
  window.loadAuditPage = (p) => loadAuditTable(api, p);
}

window.filterAudit = function(type, val) {
  if (type === 'action') _aAction = val;
  _aPage = 1; loadAuditTable(window._auditAPI);
};

window.exportAuditLog = function() {
  showToast('Mengekspor audit log...', 'info');
};

function auditActionBadge(action) {
  const map = {
    booking_approved: ['badge-success','✓ Konfirmasi Booking'],
    booking_rejected: ['badge-danger', '✕ Tolak Booking'],
    payment_verified: ['badge-success','💳 Verifikasi Bayar'],
    field_updated:    ['badge-info',   '✏️ Update Lapangan'],
    staff_added:      ['badge-purple', '👤 Tambah Staff'],
    review_deleted:   ['badge-warning','🗑️ Hapus Review'],
    user_login:       ['badge-gray',   '🔑 Login Admin'],
  };
  const [cls, label] = map[action] || ['badge-gray', action];
  return `<span class="badge ${cls}">${label}</span>`;
}

function safeJson(str) {
  if (!str) return '—';
  try {
    const obj = typeof str === 'string' ? JSON.parse(str) : str;
    return JSON.stringify(obj).substring(0, 80);
  } catch { return String(str).substring(0, 80); }
}
