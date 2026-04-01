// =============================================
// SIPELOR BEDAS — Carousel Banners View
// Manajemen gambar/banner di home screen
// =============================================

/* ── State ────────────────────────────────── */
let _carouselBanners   = [];
let _carouselEditId    = null;
let _carouselImageFile = null;
let _carouselDeleteId  = null;

/* ── Entry Point ──────────────────────────── */
async function renderCarousel(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">🎠 Carousel Banner</div>
      <div class="page-subtitle">Kelola gambar/banner yang tampil di halaman utama aplikasi.</div>
    </div>
    <button class="btn btn-gradient" onclick="openCarouselModal()">
      <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
      Tambah Banner
    </button>
  </div>

  <!-- Info Banner -->
  <div style="background:var(--primary-bg);border:1px solid var(--border);border-left:4px solid var(--primary-light);border-radius:var(--radius-lg);padding:14px 18px;margin-bottom:20px;display:flex;gap:12px;align-items:flex-start;">
    <svg width="18" height="18" fill="none" stroke="var(--primary)" stroke-width="2" viewBox="0 0 24 24" style="flex-shrink:0;margin-top:2px;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    <div style="font-size:13px;color:var(--text-secondary);line-height:1.6;">
      Banner dengan <strong style="color:var(--primary)">gambar</strong> akan tampil sebagai cover foto penuh.
      Banner tanpa gambar menggunakan <strong style="color:var(--primary)">desain gradient</strong> otomatis.
      Hanya banner berstatus <strong style="color:var(--success)">Aktif</strong> yang tampil di aplikasi.
    </div>
  </div>

  <!-- Banner List Card -->
  <div class="card">
    <div id="carousel-list">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
  </div>

  <!-- ═══════════════════════════════════════
       MODAL — Tambah / Edit Banner
  ═══════════════════════════════════════ -->
  <div class="modal-overlay" id="carousel-modal">
    <div class="modal" style="max-width:540px;">
      <div class="modal-header">
        <div class="modal-title" id="carousel-modal-title">Tambah Banner</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('carousel-modal')">✕</button>
      </div>
      <div class="modal-body">
        <form id="carousel-form" onsubmit="submitCarouselForm(event)">

          <!-- Upload Gambar -->
          <div class="form-group">
            <label class="form-label">Gambar Banner <span style="font-weight:400;text-transform:none;letter-spacing:0;color:var(--text-muted);">(opsional)</span></label>
            <div id="carousel-upload-area"
              onclick="document.getElementById('carousel-file-input').click()"
              style="border:2px dashed var(--border);border-radius:var(--radius-lg);padding:20px;text-align:center;cursor:pointer;transition:border-color var(--transition),background var(--transition);background:var(--bg-page);"
              onmouseenter="this.style.borderColor='var(--primary-light)';this.style.background='var(--bg-hover)'"
              onmouseleave="this.style.borderColor='var(--border)';this.style.background='var(--bg-page)'">
              <div id="carousel-upload-preview" style="display:none;margin-bottom:10px;">
                <img id="carousel-preview-img" src="" alt="Preview"
                  style="max-height:300px;border-radius:var(--radius);object-fit:contain;width:100%;height:auto;display:block;background:transparent;" />
              </div>
              <div id="carousel-upload-placeholder">
                <svg width="28" height="28" fill="none" stroke="var(--primary-light)" stroke-width="1.5" viewBox="0 0 24 24" style="margin:0 auto 8px;display:block;"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                <p style="font-size:13px;color:var(--text-secondary);margin:0;font-weight:600;">Klik untuk upload gambar</p>
                <p style="font-size:11.5px;color:var(--text-muted);margin:4px 0 0;">JPG, PNG, WebP — maks 20 MB</p>
              </div>
              <input type="file" id="carousel-file-input" accept="image/*" style="display:none;" onchange="handleCarouselImageSelect(event)" />
            </div>
            <div id="carousel-current-image" style="display:none;margin-top:6px;">
              <span style="font-size:12px;color:var(--success);font-weight:600;">
                <svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" style="vertical-align:middle;margin-right:4px;"><polyline points="20 6 9 17 4 12"/></svg>
                Gambar tersimpan. Upload file baru untuk mengganti.
              </span>
            </div>
          </div>

          <!-- Judul -->
          <div class="form-group">
            <label class="form-label">Judul Banner <span class="req">*</span></label>
            <input type="text" class="form-control" id="carousel-title"
              placeholder="Contoh: Diskon Sewa Lapangan" required maxlength="80" />
          </div>

          <!-- Subjudul -->
          <div class="form-group">
            <label class="form-label">Subjudul</label>
            <input type="text" class="form-control" id="carousel-subtitle"
              placeholder="Contoh: Hemat hingga 30%" maxlength="100" />
          </div>

          <!-- Teks Badge -->
          <div class="form-group">
            <label class="form-label">Teks Badge</label>
            <input type="text" class="form-control" id="carousel-badge"
              placeholder="Contoh: DISKON 30%" maxlength="30" />
          </div>

          <!-- Warna Gradient -->
          <div class="form-group">
            <label class="form-label">Warna Gradient <span style="font-weight:400;text-transform:none;letter-spacing:0;color:var(--text-muted);">(dipakai jika tanpa gambar)</span></label>
            <div class="form-row">
              <div>
                <label style="font-size:11.5px;color:var(--text-muted);display:block;margin-bottom:6px;font-weight:600;">Warna Awal</label>
                <div style="display:flex;gap:8px;align-items:center;">
                  <input type="color" id="carousel-grad-start" value="#D946EF"
                    style="width:42px;height:38px;border-radius:var(--radius-sm);border:1.5px solid var(--border);cursor:pointer;padding:2px;background:none;" />
                  <input type="text" id="carousel-grad-start-hex" class="form-control" value="#D946EF"
                    maxlength="7" style="font-family:monospace;font-size:13px;" oninput="syncCarouselColor('start')" />
                </div>
              </div>
              <div>
                <label style="font-size:11.5px;color:var(--text-muted);display:block;margin-bottom:6px;font-weight:600;">Warna Akhir</label>
                <div style="display:flex;gap:8px;align-items:center;">
                  <input type="color" id="carousel-grad-end" value="#F97316"
                    style="width:42px;height:38px;border-radius:var(--radius-sm);border:1.5px solid var(--border);cursor:pointer;padding:2px;background:none;" />
                  <input type="text" id="carousel-grad-end-hex" class="form-control" value="#F97316"
                    maxlength="7" style="font-family:monospace;font-size:13px;" oninput="syncCarouselColor('end')" />
                </div>
              </div>
            </div>
            <!-- Preview Gradient -->
            <div id="carousel-grad-preview"
              style="margin-top:10px;height:32px;border-radius:var(--radius);background:linear-gradient(135deg,#D946EF,#F97316);transition:background 0.3s;"></div>
          </div>

          <!-- Urutan + Status -->
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Urutan Tampil</label>
              <input type="number" class="form-control" id="carousel-sort" value="0" min="0" max="99" />
            </div>
            <div class="form-group">
              <label class="form-label">Status</label>
              <select class="form-control form-select" id="carousel-active">
                <option value="true">Aktif</option>
                <option value="false">Nonaktif</option>
              </select>
            </div>
          </div>

          <!-- URL Tautan -->
          <div class="form-group">
            <label class="form-label">URL Tautan <span style="font-weight:400;text-transform:none;letter-spacing:0;color:var(--text-muted);">(opsional)</span></label>
            <input type="url" class="form-control" id="carousel-link" placeholder="https://..." />
          </div>

        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('carousel-modal')">Batal</button>
        <button class="btn btn-gradient" id="carousel-submit-btn"
          onclick="document.getElementById('carousel-form').requestSubmit()">
          <span id="carousel-submit-label">Simpan Banner</span>
        </button>
      </div>
    </div>
  </div>

  <!-- ═══════════════════════════════════════
       MODAL — Konfirmasi Hapus
  ═══════════════════════════════════════ -->
  <div class="modal-overlay" id="carousel-delete-modal">
    <div class="modal" style="max-width:420px;">
      <div class="modal-header">
        <div class="modal-title">Hapus Banner?</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('carousel-delete-modal')">✕</button>
      </div>
      <div class="modal-body">
        <p style="color:var(--text-secondary);margin-bottom:6px;">
          Banner <strong id="carousel-delete-name" style="color:var(--text-primary);"></strong> akan dihapus secara permanen
          beserta file gambarnya. Tindakan ini tidak dapat dibatalkan.
        </p>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('carousel-delete-modal')">Batal</button>
        <button class="btn btn-danger" id="carousel-delete-confirm-btn" onclick="confirmDeleteCarousel()">Hapus</button>
      </div>
    </div>
  </div>`;

  // Pasang listener color picker → sync hex input
  document.getElementById('carousel-grad-start')?.addEventListener('input', e => {
    const hexEl = document.getElementById('carousel-grad-start-hex');
    if (hexEl) hexEl.value = e.target.value;
    _updateCarouselGradientPreview();
  });
  document.getElementById('carousel-grad-end')?.addEventListener('input', e => {
    const hexEl = document.getElementById('carousel-grad-end-hex');
    if (hexEl) hexEl.value = e.target.value;
    _updateCarouselGradientPreview();
  });

  await _loadCarouselBanners(api);
  window._carouselAPI = api;
}

/* ── Load & Render List ───────────────────── */
async function _loadCarouselBanners(api) {
  const listEl = document.getElementById('carousel-list');
  if (!listEl) return;

  listEl.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  try {
    _carouselBanners = await api.getCarouselBanners();
    _renderCarouselList();
  } catch (e) {
    listEl.innerHTML = `<div class="empty-state"><p style="color:var(--danger);">Gagal memuat banner: ${e.message}</p></div>`;
  }
}

function _renderCarouselList() {
  const el = document.getElementById('carousel-list');
  if (!el) return;

  if (!_carouselBanners.length) {
    el.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">🖼️</div>
        <h3>Belum Ada Banner</h3>
        <p>Tambah banner pertama untuk ditampilkan di home screen aplikasi.</p>
      </div>`;
    return;
  }

  el.innerHTML = `
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th width="64">Preview</th>
          <th>Judul & Subjudul</th>
          <th width="110">Badge</th>
          <th width="72" style="text-align:center;">Urutan</th>
          <th width="90">Status</th>
          <th width="110">Dibuat</th>
          <th width="120">Aksi</th>
        </tr>
      </thead>
      <tbody>
        ${_carouselBanners.map(b => _carouselRow(b)).join('')}
      </tbody>
    </table>
  </div>`;
}

function _carouselRow(b) {
  const previewBg = b.image_url
    ? `background:url('${_escAttr(b.image_url)}') center/cover no-repeat;`
    : `background:linear-gradient(135deg,${b.gradient_start || '#D946EF'},${b.gradient_end || '#F97316'});`;

  const statusBadge = b.is_active
    ? `<span class="badge badge-success">Aktif</span>`
    : `<span class="badge badge-gray">Nonaktif</span>`;

  return `
  <tr>
    <td>
      <div style="width:56px;height:38px;border-radius:var(--radius);${previewBg}border:1px solid var(--border);flex-shrink:0;"></div>
    </td>
    <td>
      <div class="font-bold">${_escHtml(b.title)}</div>
      ${b.subtitle ? `<div class="text-sm text-muted">${_escHtml(b.subtitle)}</div>` : ''}
    </td>
    <td>
      ${b.badge_text
        ? `<span class="badge badge-purple">${_escHtml(b.badge_text)}</span>`
        : `<span class="text-muted text-sm">—</span>`}
    </td>
    <td style="text-align:center;font-weight:700;">${b.sort_order ?? 0}</td>
    <td>${statusBadge}</td>
    <td class="text-sm text-muted">${fmtDate(b.created_at)}</td>
    <td>
      <div class="flex gap-2">
        <button class="btn btn-outline btn-sm" onclick="openCarouselModal('${b.id}')" title="Edit">
          <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          Edit
        </button>
        <button class="btn btn-danger btn-sm btn-icon" onclick="openDeleteCarouselModal('${b.id}')" title="Hapus">
          <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>
        </button>
      </div>
    </td>
  </tr>`;
}

/* ── Gradient Preview ─────────────────────── */
function _updateCarouselGradientPreview() {
  const start = document.getElementById('carousel-grad-start')?.value || '#D946EF';
  const end   = document.getElementById('carousel-grad-end')?.value   || '#F97316';
  const el    = document.getElementById('carousel-grad-preview');
  if (el) el.style.background = `linear-gradient(135deg,${start},${end})`;
}

window.syncCarouselColor = function(which) {
  const hexEl   = document.getElementById(`carousel-grad-${which}-hex`);
  const colorEl = document.getElementById(`carousel-grad-${which}`);
  const hex = hexEl?.value || '';
  if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
    if (colorEl) colorEl.value = hex;
    _updateCarouselGradientPreview();
  }
};

/* ── Open / Close Modals ──────────────────── */
window.openCarouselModal = function(id = null) {
  _carouselEditId    = id;
  _carouselImageFile = null;

  // Reset judul & label tombol
  const titleEl = document.getElementById('carousel-modal-title');
  const labelEl = document.getElementById('carousel-submit-label');
  if (titleEl) titleEl.textContent = id ? 'Edit Banner' : 'Tambah Banner';
  if (labelEl) labelEl.textContent = id ? 'Simpan Perubahan' : 'Simpan Banner';

  // Reset form & preview
  const form    = document.getElementById('carousel-form');
  const prevEl  = document.getElementById('carousel-upload-preview');
  const phEl    = document.getElementById('carousel-upload-placeholder');
  const curImgEl = document.getElementById('carousel-current-image');
  if (form) form.reset();
  if (prevEl)   prevEl.style.display   = 'none';
  if (phEl)     phEl.style.display     = '';
  if (curImgEl) curImgEl.style.display = 'none';

  if (id) {
    // Edit mode — isi data lama
    const b = _carouselBanners.find(x => x.id === id);
    if (b) {
      _setVal('carousel-title',    b.title || '');
      _setVal('carousel-subtitle', b.subtitle || '');
      _setVal('carousel-badge',    b.badge_text || '');
      _setVal('carousel-sort',     b.sort_order ?? 0);
      _setVal('carousel-active',   b.is_active ? 'true' : 'false');
      _setVal('carousel-link',     b.link_url || '');

      const gs = b.gradient_start || '#D946EF';
      const ge = b.gradient_end   || '#F97316';
      _setColorPair('carousel-grad-start', gs);
      _setColorPair('carousel-grad-end',   ge);
      _updateCarouselGradientPreview();

      if (b.image_url) {
        const prevImg = document.getElementById('carousel-preview-img');
        if (prevImg)  prevImg.src = b.image_url;
        if (prevEl)   prevEl.style.display   = '';
        if (phEl)     phEl.style.display     = 'none';
        if (curImgEl) curImgEl.style.display = '';
      }
    }
  } else {
    // Add mode — default gradient
    _setColorPair('carousel-grad-start', '#D946EF');
    _setColorPair('carousel-grad-end',   '#F97316');
    _updateCarouselGradientPreview();
  }

  openModal('carousel-modal');
};

/* ── Image File Select ────────────────────── */
window.handleCarouselImageSelect = function(e) {
  const file = e.target.files?.[0];
  if (!file) return;
  if (file.size > 20 * 1024 * 1024) {
    showToast('Ukuran gambar maksimal 20 MB', 'error');
    return;
  }
  _carouselImageFile = file;
  const reader = new FileReader();
  reader.onload = ev => {
    const prevImg = document.getElementById('carousel-preview-img');
    const prevEl  = document.getElementById('carousel-upload-preview');
    const phEl    = document.getElementById('carousel-upload-placeholder');
    if (prevImg) prevImg.src = ev.target.result;
    if (prevEl)  prevEl.style.display = '';
    if (phEl)    phEl.style.display   = 'none';
  };
  reader.readAsDataURL(file);
};

/* ── Submit Form ──────────────────────────── */
window.submitCarouselForm = async function(e) {
  e.preventDefault();

  const btn   = document.getElementById('carousel-submit-btn');
  const label = document.getElementById('carousel-submit-label');
  if (btn) btn.disabled = true;

  try {
    let imageUrl = null;

    // Upload gambar baru jika dipilih
    if (_carouselImageFile) {
      if (label) label.innerHTML = '<span class="spinner spinner-sm"></span>&nbsp;Mengupload...';
      const result = await window._carouselAPI.uploadCarouselImage(_carouselImageFile);
      imageUrl = result.publicUrl;
    }

    if (label) label.innerHTML = '<span class="spinner spinner-sm"></span>&nbsp;Menyimpan...';

    const payload = {
      title:          (document.getElementById('carousel-title')?.value || '').trim(),
      subtitle:       (document.getElementById('carousel-subtitle')?.value || '').trim(),
      badge_text:     (document.getElementById('carousel-badge')?.value || '').trim(),
      gradient_start: document.getElementById('carousel-grad-start')?.value || '#D946EF',
      gradient_end:   document.getElementById('carousel-grad-end')?.value   || '#F97316',
      sort_order:     parseInt(document.getElementById('carousel-sort')?.value || '0', 10),
      is_active:      document.getElementById('carousel-active')?.value === 'true',
      link_url:       (document.getElementById('carousel-link')?.value || '').trim() || null,
    };

    // Sertakan image_url hanya jika ada gambar baru yang diupload
    // (saat edit tanpa gambar baru, biarkan image_url tidak berubah)
    if (imageUrl !== null) {
      payload.image_url = imageUrl;
    } else if (!_carouselEditId) {
      payload.image_url = null; // banner baru tanpa gambar
    }

    if (_carouselEditId) {
      await window._carouselAPI.updateCarouselBanner(_carouselEditId, payload);
      showToast('Banner berhasil diperbarui ✅', 'success');
    } else {
      await window._carouselAPI.createCarouselBanner(payload);
      showToast('Banner baru berhasil ditambahkan ✅', 'success');
    }

    closeModal('carousel-modal');
    await _loadCarouselBanners(window._carouselAPI);

  } catch (err) {
    console.error('[Carousel] submit error:', err);
    showToast('Gagal menyimpan: ' + err.message, 'error');
  } finally {
    if (btn) btn.disabled = false;
    if (label) label.textContent = _carouselEditId ? 'Simpan Perubahan' : 'Simpan Banner';
    _carouselImageFile = null;
  }
};

/* ── Delete ───────────────────────────────── */
window.openDeleteCarouselModal = function(id) {
  const b = _carouselBanners.find(x => x.id === id);
  if (!b) return;
  _carouselDeleteId = id;
  const nameEl = document.getElementById('carousel-delete-name');
  if (nameEl) nameEl.textContent = `"${b.title}"`;
  openModal('carousel-delete-modal');
};

window.confirmDeleteCarousel = async function() {
  if (!_carouselDeleteId) return;
  const btn = document.getElementById('carousel-delete-confirm-btn');
  if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner spinner-sm"></span>&nbsp;Menghapus...'; }

  try {
    const b = _carouselBanners.find(x => x.id === _carouselDeleteId);
    await window._carouselAPI.deleteCarouselBanner(_carouselDeleteId, b?.image_url || null);
    showToast('Banner berhasil dihapus', 'info');
    closeModal('carousel-delete-modal');
    await _loadCarouselBanners(window._carouselAPI);
  } catch (err) {
    showToast('Gagal menghapus: ' + err.message, 'error');
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Hapus'; }
    _carouselDeleteId = null;
  }
};

/* ── Helpers ──────────────────────────────── */
function _setVal(id, val) {
  const el = document.getElementById(id);
  if (el) el.value = val;
}

function _setColorPair(inputId, hex) {
  const colorEl = document.getElementById(inputId);
  const hexEl   = document.getElementById(inputId + '-hex');
  if (colorEl) colorEl.value = hex;
  if (hexEl)   hexEl.value   = hex;
}

function _escHtml(str) {
  return String(str || '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function _escAttr(str) {
  return String(str || '').replace(/'/g, '&#39;').replace(/"/g, '&quot;');
}
