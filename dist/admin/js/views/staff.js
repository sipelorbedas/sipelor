// ─────────────────────────────────────────────────────
// STAFF VIEW
// ─────────────────────────────────────────────────────

let _sPage = 1, _sRole = '', _sSearch = '';

async function renderStaff(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Manajemen Staff</div>
      <div class="page-subtitle">Kelola akses staff dan peran (RBAC: Admin / Manager / Operator).</div>
    </div>
    <button class="btn btn-gradient" onclick="openStaffModal()">
      <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
      Tambah Staff
    </button>
  </div>

  <!-- Role cards -->
  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:24px;">
    ${roleInfoCard('👑','Admin','Akses penuh ke semua fitur dan konfigurasi sistem.','purple')}
    ${roleInfoCard('📊','Manager','Kelola lapangan, pemesanan, laporan analitik.','blue')}
    ${roleInfoCard('⚙️','Operator','Verifikasi pembayaran, konfirmasi booking harian.','green')}
  </div>

  <div class="card">
    <div class="table-controls">
      <div class="table-search">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
        <input type="text" placeholder="Cari nama atau email..." oninput="debounceStaffSearch(this.value)" />
      </div>
      <select class="form-control form-select" style="width:auto;padding:8px 36px 8px 12px;font-size:13px;" onchange="filterStaff('role',this.value)">
        <option value="">Semua Peran</option>
        <option value="admin">Admin</option>
        <option value="manager">Manager</option>
        <option value="operator">Operator</option>
      </select>
    </div>

    <div class="table-wrap" id="staff-table-wrap">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
    <div id="staff-pagination"></div>
  </div>

  <!-- Staff Modal -->
  <div class="modal-overlay" id="staff-modal">
    <div class="modal">
      <div class="modal-header">
        <div class="modal-title" id="staff-modal-title">Tambah Staff</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('staff-modal')">✕</button>
      </div>
      <div class="modal-body">
        <form id="staff-form" onsubmit="submitStaffForm(event)">
          <div class="form-group">
            <label class="form-label">Nama Lengkap<span class="req">*</span></label>
            <input type="text" class="form-control" id="sf-name" placeholder="Nama staff" required />
          </div>
          <div class="form-group">
            <label class="form-label">Email<span class="req">*</span></label>
            <input type="email" class="form-control" id="sf-email" placeholder="staff@sipelor.com" required />
          </div>
          <div class="form-group" id="sf-password-group">
            <label class="form-label">Password<span class="req">*</span></label>
            <input type="password" class="form-control" id="sf-password" placeholder="Min. 6 karakter" autocomplete="new-password" />
            <div class="form-hint">Password untuk login ke panel admin. Minimal 6 karakter.</div>
          </div>
          <div class="form-group">
            <label class="form-label">No. HP</label>
            <input type="tel" class="form-control" id="sf-phone" placeholder="08xxxxxxxxxx" />
          </div>
          <div class="form-group">
            <label class="form-label">Peran<span class="req">*</span></label>
            <select class="form-control form-select" id="sf-role" required>
              <option value="">Pilih Peran</option>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="operator">Operator</option>
            </select>
            <div class="form-hint" id="sf-role-hint"></div>
          </div>
          <div class="form-group">
            <label class="toggle">
              <input type="checkbox" id="sf-active" checked />
              <div class="toggle-track"><div class="toggle-thumb"></div></div>
              <span style="font-size:13px;font-weight:600;">Status Aktif</span>
            </label>
          </div>
          <input type="hidden" id="sf-id" />
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('staff-modal')">Batal</button>
        <button class="btn btn-gradient" onclick="document.getElementById('staff-form').requestSubmit()" id="staff-submit-btn">Simpan Staff</button>
      </div>
    </div>
  </div>`;

  loadStaffTable(api);
  window._staffAPI = api;

  // Role hint
  document.getElementById('sf-role')?.addEventListener('change', function() {
    const hints = {
      admin:    'Akses penuh: semua fitur, konfigurasi, manajemen staff.',
      manager:  'Kelola lapangan, approve booking, lihat semua laporan.',
      operator: 'Verifikasi pembayaran, konfirmasi booking, chat user.',
    };
    document.getElementById('sf-role-hint').textContent = hints[this.value] || '';
  });
}

async function loadStaffTable(api, page = _sPage) {
  _sPage = page;
  const wrap = document.getElementById('staff-table-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  const { data, count } = await api.getStaff({ page: _sPage, limit: 10, role: _sRole, search: _sSearch });

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">👥</div><h3>Belum ada staff</h3><p>Tambahkan anggota tim Anda.</p></div>`;
    document.getElementById('staff-pagination').innerHTML = '';
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>Staff</th>
        <th>Email</th>
        <th>No. HP</th>
        <th>Peran</th>
        <th>Status</th>
        <th>Login Terakhir</th>
        <th>Aksi</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(s => `
      <tr>
        <td>
          <div class="flex items-center gap-2">
            <div class="avatar-sm">${(s.name||'S')[0].toUpperCase()}</div>
            <div class="font-bold">${s.name}</div>
          </div>
        </td>
        <td style="color:var(--text-secondary);font-size:13px;">${s.email}</td>
        <td style="font-size:13px;">${s.phone || '—'}</td>
        <td>${staffRoleBadge(s.role)}</td>
        <td>
          <span class="badge ${s.is_active ? 'badge-success' : 'badge-gray'}">
            ${s.is_active ? 'Aktif' : 'Nonaktif'}
          </span>
        </td>
        <td style="font-size:12px;color:var(--text-muted);">${s.last_login ? fmtDateTime(s.last_login) : 'Belum pernah'}</td>
        <td>
          <div class="flex gap-2">
            <button class="btn btn-outline btn-sm btn-icon" title="Edit" onclick="openStaffModal(${JSON.stringify(s).replace(/"/g,'&quot;')})">✏️</button>
            <button class="btn btn-danger btn-sm btn-icon" title="Hapus" onclick="deleteStaff('${s.id}','${s.name}')">🗑️</button>
          </div>
        </td>
      </tr>`).join('')}
    </tbody>
  </table>`;

  const totalPages = Math.ceil(count / 10);
  document.getElementById('staff-pagination').innerHTML = renderPagination(_sPage, totalPages, count, 'loadStaffPage');
  window.loadStaffPage = (p) => loadStaffTable(api, p);
}

window.openStaffModal = function(staff = null) {
  const isEdit = !!staff;
  document.getElementById('staff-modal-title').textContent = isEdit ? 'Edit Staff' : 'Tambah Staff';
  document.getElementById('sf-id').value        = staff?.id || '';
  document.getElementById('sf-name').value      = staff?.name || '';
  document.getElementById('sf-email').value     = staff?.email || '';
  document.getElementById('sf-phone').value     = staff?.phone || '';
  document.getElementById('sf-role').value      = staff?.role || '';
  document.getElementById('sf-active').checked  = staff?.is_active !== false;

  // Password field: required only for new staff, hidden when editing
  const pwdGroup = document.getElementById('sf-password-group');
  const pwdInput = document.getElementById('sf-password');
  if (pwdGroup) pwdGroup.style.display = isEdit ? 'none' : '';
  if (pwdInput) {
    pwdInput.value    = '';
    pwdInput.required = !isEdit;
  }

  openModal('staff-modal');
};

window.submitStaffForm = async function(e) {
  e.preventDefault();
  const btn = document.getElementById('staff-submit-btn');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner spinner-sm"></span> Menyimpan...';

  const id       = document.getElementById('sf-id').value;
  const password = document.getElementById('sf-password')?.value?.trim() || '';

  // Validate password for new staff
  if (!id) {
    if (!password) {
      showToast('Password wajib diisi untuk staff baru.', 'error');
      btn.disabled = false; btn.textContent = 'Simpan Staff'; return;
    }
    if (password.length < 6) {
      showToast('Password minimal 6 karakter.', 'error');
      btn.disabled = false; btn.textContent = 'Simpan Staff'; return;
    }
  }

  const payload = {
    name:       document.getElementById('sf-name').value.trim(),
    email:      document.getElementById('sf-email').value.trim(),
    phone:      document.getElementById('sf-phone').value.trim() || null,
    role:       document.getElementById('sf-role').value,
    is_active:  document.getElementById('sf-active').checked,
    updated_at: new Date().toISOString(),
  };

  try {
    if (id) {
      // Edit: update staff record only (no auth change needed)
      await window._staffAPI.updateStaff(id, payload);
    } else {
      // Create: register auth user first using a temporary Supabase client
      // (separate instance so the current admin session is NOT affected)
      let userId = null;
      try {
        const tempClient = supabase.createClient(
          SIPELOR_ADMIN_CONFIG.SUPABASE_URL,
          SIPELOR_ADMIN_CONFIG.SUPABASE_ANON_KEY
        );
        const { data: authData, error: authErr } = await tempClient.auth.signUp({
          email:    payload.email,
          password: password,
          options:  { data: { full_name: payload.name, role: payload.role } },
        });
        if (authErr) throw new Error(authErr.message);
        userId = authData?.user?.id || null;
        if (!userId) throw new Error('UUID akun tidak diterima dari server.');
      } catch (authErr) {
        showToast('Gagal membuat akun: ' + authErr.message, 'error');
        btn.disabled = false; btn.textContent = 'Simpan Staff'; return;
      }

      await window._staffAPI.createStaff({
        ...payload,
        user_id:         userId,
        assigned_venues: [],
        created_at:      new Date().toISOString(),
      });
    }

    showToast(id ? 'Data staff diperbarui! ✅' : 'Staff berhasil ditambahkan! ✅', 'success');
    closeModal('staff-modal');
    loadStaffTable(window._staffAPI);
  } catch(err) {
    showToast('Gagal menyimpan: ' + err.message, 'error');
  }
  btn.disabled = false;
  btn.textContent = 'Simpan Staff';
};

window.deleteStaff = async function(id, name) {
  if (!confirm(`Hapus staff "${name}"?`)) return;
  try {
    await window._staffAPI.deleteStaff(id);
    showToast('Staff berhasil dihapus.', 'success');
    loadStaffTable(window._staffAPI);
  } catch(e) { showToast('Gagal menghapus: ' + e.message, 'error'); }
};

let _sSearchTimer;
window.debounceStaffSearch = function(val) {
  clearTimeout(_sSearchTimer);
  _sSearchTimer = setTimeout(() => { _sSearch = val; _sPage = 1; loadStaffTable(window._staffAPI); }, 400);
};
window.filterStaff = function(type, val) {
  if (type === 'role') _sRole = val;
  _sPage = 1; loadStaffTable(window._staffAPI);
};

function roleInfoCard(icon, title, desc, color) {
  return `<div class="card" style="padding:18px 20px;">
    <div style="font-size:28px;margin-bottom:8px;">${icon}</div>
    <div style="font-weight:800;font-size:15px;color:var(--text-primary);margin-bottom:4px;">${title}</div>
    <div style="font-size:12.5px;color:var(--text-secondary);">${desc}</div>
  </div>`;
}

function staffRoleBadge(role) {
  const m = { admin:'badge-purple', manager:'badge-info', operator:'badge-success' };
  const l = { admin:'Admin', manager:'Manager', operator:'Operator' };
  return `<span class="badge ${m[role]||'badge-gray'}">${l[role]||role}</span>`;
}
