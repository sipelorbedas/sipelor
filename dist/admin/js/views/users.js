// ─────────────────────────────────────────────────────
// USERS VIEW
// ─────────────────────────────────────────────────────

let _uPage = 1, _uSearch = '';

async function renderUsers(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Data Pengguna</div>
      <div class="page-subtitle">Daftar seluruh pengguna yang terdaftar di SIPELOR BEDAS.</div>
    </div>
  </div>

  <div class="card">
    <div class="table-controls">
      <div class="table-search">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
        <input type="text" placeholder="Cari nama atau email..." oninput="debounceUserSearch(this.value)" />
      </div>
    </div>

    <div class="table-wrap" id="users-table-wrap">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
    <div id="users-pagination"></div>
  </div>`;

  loadUsersTable(api);
  window._userAPI = api;
}

async function loadUsersTable(api, page = _uPage) {
  _uPage = page;
  const wrap = document.getElementById('users-table-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  const { data, count } = await api.getUsers({ page: _uPage, limit: 10, search: _uSearch });

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">👥</div><h3>Belum ada pengguna</h3></div>`;
    document.getElementById('users-pagination').innerHTML = '';
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>Pengguna</th>
        <th>Email</th>
        <th>No. HP</th>
        <th>Bergabung</th>
        <th>Login Terakhir</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(u => `
      <tr>
        <td>
          <div class="flex items-center gap-2">
            <div class="avatar-sm">${(u.full_name || u.email || 'U')[0].toUpperCase()}</div>
            <div class="font-bold">${u.full_name || '—'}</div>
          </div>
        </td>
        <td style="color:var(--text-secondary);font-size:13px;">${u.email || '—'}</td>
        <td style="font-size:13px;">${u.phone || '—'}</td>
        <td style="font-size:12px;color:var(--text-muted);">${fmtDate(u.created_at)}</td>
        <td style="font-size:12px;color:var(--text-muted);">${u.last_sign_in_at ? fmtDateTime(u.last_sign_in_at) : '—'}</td>
        <td><span class="badge badge-success">Aktif</span></td>
      </tr>`).join('')}
    </tbody>
  </table>`;

  const totalPages = Math.ceil(count / 10);
  document.getElementById('users-pagination').innerHTML = renderPagination(_uPage, totalPages, count, 'loadUsersPage');
  window.loadUsersPage = (p) => loadUsersTable(api, p);
}

let _uSearchTimer;
window.debounceUserSearch = function(val) {
  clearTimeout(_uSearchTimer);
  _uSearchTimer = setTimeout(() => { _uSearch = val; _uPage = 1; loadUsersTable(window._userAPI); }, 400);
};
