// ─────────────────────────────────────────────────────
// POPUP BANNER VIEW
// Kelola popup/iklan yang muncul setelah user login
// ─────────────────────────────────────────────────────

let _popupBanners   = [];
let _popupEditId    = null;
let _popupImageFile = null;
let _popupDeleteId  = null;

async function renderPopup(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">🪟 Popup Banner</div>
      <div class="page-subtitle">Kelola popup/iklan yang muncul otomatis setelah pengguna login ke aplikasi.</div>
    </div>
    <button class="btn btn-gradient" onclick="openPopupModal()">
      <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
      Tambah Popup
    </button>
  </div>

  <!-- Info -->
  <div style="background:var(--primary-bg);border:1px solid var(--border);border-left:4px solid var(--primary-light);border-radius:var(--radius-lg);padding:14px 18px;margin-bottom:20px;display:flex;gap:12px;align-items:flex-start;">
    <svg width="18" height="18" fill="none" stroke="var(--primary)" stroke-width="2" viewBox="0 0 24 24" style="flex-shrink:0;margin-top:2px;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    <div style="font-size:13px;color:var(--text-secondary);line-height:1.6;">
      Popup muncul <strong style="color:var(--primary)">sekali per hari</strong> setelah pengguna login.
      Jika ada <strong style="color:var(--primary)">link URL</strong>, pengguna akan diarahkan ke link tersebut saat gambar diklik.
      Hanya popup berstatus <strong style="color:var(--success)">Aktif</strong> yang tampil.
      Jika ada lebih dari satu aktif, popup <strong>terbaru</strong> yang ditampilkan.
    </div>
  </div>

  <!-- List -->
  <div class="card">
    <div id="popup-list">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
  </div>

  <!-- Modal Tambah/Edit -->
  <div class="modal-overlay" id="popup-modal">
    <div class="modal" style="max-width:520px;">
      <div class="modal-header">
        <div class="modal-title" id="popup-modal-title">Tambah Popup</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('popup-modal')">✕</button>
      </div>
      <div class="modal-body">

        <!-- Upload Gambar -->
        <div class="form-group">
          <label class="form-label">Gambar Popup <span class="req">*</span></label>
          <div id="popup-upload-area"
            onclick="document.getElementById('popup-file-input').click()"
            style="border:2px dashed var(--border);border-radius:var(--radius-lg);padding:20px;text-align:center;cursor:pointer;transition:border-color var(--transition),background var(--transition);background:var(--bg-page);"
            onmouseenter="this.style.borderColor='var(--primary-light)';this.style.background='var(--bg-hover)'"
            onmouseleave="this.style.borderColor='var(--border)';this.style.background='var(--bg-page)'">
            <div id="popup-upload-preview" style="display:none;margin-bottom:10px;">
              <img id="popup-preview-img" src="" alt="Preview"
                style="max-height:280px;border-radius:var(--radius);object-fit:contain;width:100%;display:block;" />
            </div>
            <div id="popup-upload-placeholder">
              <svg width="28" height="28" fill="none" stroke="var(--primary-light)" stroke-width="1.5" viewBox="0 0 24 24" style="margin:0 auto 8px;display:block;"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
              <p style="font-size:13px;color:var(--text-secondary);margin:0;font-weight:600;">Klik untuk upload gambar</p>
              <p style="font-size:11.5px;color:var(--text-muted);margin:4px 0 0;">JPG, PNG, WebP — maks 10 MB<br>Rasio 1:1 atau 3:4 direkomendasikan</p>
            </div>
            <input type="file" id="popup-file-input" accept="image/*" style="display:none;" onchange="handlePopupImageSelect(event)" />
          </div>
          <div id="popup-current-image" style="display:none;margin-top:6px;">
            <span style="font-size:12px;color:var(--success);font-weight:600;">
              <svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" style="vertical-align:middle;margin-right:4px;"><polyline points="20 6 9 17 4 12"/></svg>
              Gambar tersimpan. Upload baru untuk mengganti.
            </span>
          </div>
        </div>

        <!-- URL Tautan -->
        <div class="form-group">
          <label class="form-label">
            URL Tautan
            <span style="font-weight:400;text-transform:none;letter-spacing:0;color:var(--text-muted);"> (opsional — diklik saat pengguna tap gambar)</span>
          </label>
          <input type="url" class="form-control" id="popup-link"
            placeholder="https://contoh.com/promo" />
        </div>

        <!-- Status -->
        <div class="form-group" style="margin-bottom:0;">
          <label class="form-label">Status</label>
          <select class="form-control form-select" id="popup-active">
            <option value="true">Aktif — tampil di aplikasi</option>
            <option value="false">Nonaktif — tersembunyi</option>
          </select>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('popup-modal')">Batal</button>
        <button class="btn btn-gradient" id="popup-submit-btn" onclick="submitPopupForm()">
          <span id="popup-submit-label">Simpan Popup</span>
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Konfirmasi Hapus -->
  <div class="modal-overlay" id="popup-delete-modal">
    <div class="modal" style="max-width:400px;">
      <div class="modal-header">
        <div class="modal-title">Hapus Popup?</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('popup-delete-modal')">✕</button>
      </div>
      <div class="modal-body">
        <p style="color:var(--text-secondary);">
          Popup ini akan dihapus permanen beserta file gambarnya. Tindakan ini tidak dapat dibatalkan.
        </p>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('popup-delete-modal')">Batal</button>
        <button class="btn btn-danger" id="popup-delete-btn" onclick="confirmDeletePopup()">Hapus</button>
      </div>
    </div>
  </div>`;

  await _loadPopupList(api);
  window._popupAPI = api;
}

/* ── Load & Render ──────────────────────────── */
async function _loadPopupList(api) {
  const el = document.getElementById('popup-list');
  if (!el) return;
  el.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;
  try {
    _popupBanners = await api.getPopupBanners();
    _renderPopupList();
  } catch (e) {
    el.innerHTML = `<div class="empty-state"><p style="color:var(--danger);">Gagal memuat: ${e.message}</p></div>`;
  }
}

function _renderPopupList() {
  const el = document.getElementById('popup-list');
  if (!el) return;

  if (!_popupBanners.length) {
    el.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">🪟</div>
        <h3>Belum Ada Popup</h3>
        <p>Tambah popup untuk ditampilkan ke pengguna setelah login.</p>
      </div>`;
    return;
  }

  el.innerHTML = `
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th width="100">Preview</th>
          <th>Link URL</th>
          <th width="110">Status</th>
          <th width="130">Dibuat</th>
          <th width="110">Aksi</th>
        </tr>
      </thead>
      <tbody>
        ${_popupBanners.map(p => `
        <tr>
          <td>
            <div style="width:80px;height:56px;border-radius:var(--radius);overflow:hidden;border:1px solid var(--border);background:var(--bg-page);display:flex;align-items:center;justify-content:center;">
              ${p.image_url
                ? `<img src="${_pEsc(p.image_url)}" alt="popup" style="width:100%;height:100%;object-fit:cover;" />`
                : `<span style="font-size:20px;opacity:.4;">🖼️</span>`}
            </div>
          </td>
          <td style="font-size:13px;max-width:300px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
            ${p.link_url
              ? `<a href="${_pEsc(p.link_url)}" target="_blank" style="color:var(--info);word-break:break-all;">${_pEscHtml(p.link_url)}</a>`
              : `<span style="color:var(--text-muted);">— tanpa link —</span>`}
          </td>
          <td>
            ${p.is_active
              ? `<span class="badge badge-success">Aktif</span>`
              : `<span class="badge badge-gray">Nonaktif</span>`}
          </td>
          <td style="font-size:12px;color:var(--text-muted);">${fmtDateTime(p.created_at)}</td>
          <td>
            <div class="flex gap-2">
              <button class="btn btn-outline btn-sm" onclick="openPopupModal('${p.id}')" title="Edit">
                <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                Edit
              </button>
              <button class="btn btn-danger btn-sm btn-icon" onclick="_openPopupDeleteModal('${p.id}')" title="Hapus">
                <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>
              </button>
            </div>
          </td>
        </tr>`).join('')}
      </tbody>
    </table>
  </div>`;
}

/* ── Open Modal ─────────────────────────────── */
window.openPopupModal = function(id = null) {
  _popupEditId    = id;
  _popupImageFile = null;

  const titleEl = document.getElementById('popup-modal-title');
  const labelEl = document.getElementById('popup-submit-label');
  if (titleEl) titleEl.textContent = id ? 'Edit Popup' : 'Tambah Popup';
  if (labelEl) labelEl.textContent = id ? 'Simpan Perubahan' : 'Simpan Popup';

  // Reset UI
  document.getElementById('popup-file-input').value = '';
  document.getElementById('popup-upload-preview').style.display = 'none';
  document.getElementById('popup-upload-placeholder').style.display = '';
  document.getElementById('popup-current-image').style.display = 'none';
  document.getElementById('popup-link').value = '';
  document.getElementById('popup-active').value = 'true';

  if (id) {
    const p = _popupBanners.find(x => x.id === id);
    if (p) {
      document.getElementById('popup-link').value   = p.link_url  || '';
      document.getElementById('popup-active').value = p.is_active ? 'true' : 'false';
      if (p.image_url) {
        const imgEl = document.getElementById('popup-preview-img');
        if (imgEl) imgEl.src = p.image_url;
        document.getElementById('popup-upload-preview').style.display  = '';
        document.getElementById('popup-upload-placeholder').style.display = 'none';
        document.getElementById('popup-current-image').style.display   = '';
      }
    }
  }

  openModal('popup-modal');
};

/* ── Image Select ───────────────────────────── */
window.handlePopupImageSelect = function(e) {
  const file = e.target.files?.[0];
  if (!file) return;
  if (file.size > 10 * 1024 * 1024) {
    showToast('Ukuran gambar maksimal 10 MB', 'error');
    return;
  }
  _popupImageFile = file;
  const reader = new FileReader();
  reader.onload = ev => {
    const imgEl = document.getElementById('popup-preview-img');
    if (imgEl) imgEl.src = ev.target.result;
    document.getElementById('popup-upload-preview').style.display  = '';
    document.getElementById('popup-upload-placeholder').style.display = 'none';
  };
  reader.readAsDataURL(file);
};

/* ── Submit ─────────────────────────────────── */
window.submitPopupForm = async function() {
  // Validasi: harus ada gambar (baru atau existing)
  const isEdit     = !!_popupEditId;
  const existing   = isEdit ? _popupBanners.find(x => x.id === _popupEditId) : null;
  const hasImage   = _popupImageFile || (isEdit && existing?.image_url);
  if (!hasImage) {
    showToast('Gambar popup wajib diupload.', 'warning');
    return;
  }

  const btn   = document.getElementById('popup-submit-btn');
  const label = document.getElementById('popup-submit-label');
  if (btn) btn.disabled = true;

  try {
    let imageUrl = null;

    if (_popupImageFile) {
      if (label) label.innerHTML = '<span class="spinner spinner-sm"></span>&nbsp;Mengupload...';
      const result = await window._popupAPI.uploadPopupImage(_popupImageFile);
      imageUrl = result.publicUrl;
    }

    if (label) label.innerHTML = '<span class="spinner spinner-sm"></span>&nbsp;Menyimpan...';

    const payload = {
      link_url:  (document.getElementById('popup-link')?.value || '').trim() || null,
      is_active: document.getElementById('popup-active')?.value === 'true',
    };
    if (imageUrl !== null) payload.image_url = imageUrl;

    if (isEdit) {
      await window._popupAPI.updatePopupBanner(_popupEditId, payload);
      showToast('Popup berhasil diperbarui ✅', 'success');
    } else {
      await window._popupAPI.createPopupBanner({ ...payload, image_url: imageUrl });
      showToast('Popup berhasil ditambahkan ✅', 'success');
    }

    closeModal('popup-modal');
    await _loadPopupList(window._popupAPI);
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error');
  } finally {
    if (btn) btn.disabled = false;
    if (label) label.textContent = isEdit ? 'Simpan Perubahan' : 'Simpan Popup';
    _popupImageFile = null;
  }
};

/* ── Delete ─────────────────────────────────── */
window._openPopupDeleteModal = function(id) {
  _popupDeleteId = id;
  openModal('popup-delete-modal');
};

window.confirmDeletePopup = async function() {
  if (!_popupDeleteId) return;
  const btn = document.getElementById('popup-delete-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner spinner-sm"></span>&nbsp;Menghapus...'; }
  try {
    const p = _popupBanners.find(x => x.id === _popupDeleteId);
    await window._popupAPI.deletePopupBanner(_popupDeleteId, p?.image_url || null);
    showToast('Popup dihapus.', 'info');
    closeModal('popup-delete-modal');
    await _loadPopupList(window._popupAPI);
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error');
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Hapus'; }
    _popupDeleteId = null;
  }
};

/* ── Helpers ────────────────────────────────── */
function _pEscHtml(str) {
  return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function _pEsc(str) {
  return String(str || '').replace(/'/g,"&#39;").replace(/"/g,'&quot;');
}
