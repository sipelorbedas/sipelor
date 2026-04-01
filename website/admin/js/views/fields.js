// ─────────────────────────────────────────────────────
// FIELDS VIEW
// ─────────────────────────────────────────────────────

let _fPage = 1, _fStatus = '', _fSearch = '';

// ── Image upload state ───────────────────────────────
// Each item: { type: 'file', file: File, preview: string } | { type: 'url', url: string }
let _fieldImages = [];
const FIELD_MAX_IMAGES = 6;

async function renderFields(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Manajemen Lapangan</div>
      <div class="page-subtitle">Kelola data lapangan olahraga DISPORA Kabupaten Bandung.</div>
    </div>
    <button class="btn btn-gradient" onclick="openFieldModal()">
      <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
      Tambah Lapangan
    </button>
  </div>

  <div class="card">
    <div class="table-controls">
      <div class="table-search">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
        <input type="text" placeholder="Cari nama lapangan..." oninput="debounceFieldSearch(this.value)" />
      </div>
      <select class="form-control form-select" style="width:auto;padding:8px 36px 8px 12px;font-size:13px;" onchange="filterField('status',this.value)">
        <option value="">Semua Status</option>
        <option value="available">Tersedia</option>
        <option value="booked">Terpakai</option>
        <option value="maintenance">Maintenance</option>
      </select>
    </div>

    <div class="table-wrap" id="fields-table-wrap">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
    <div id="fields-pagination"></div>
  </div>

  <!-- Field Modal -->
  <div class="modal-overlay" id="field-modal">
    <div class="modal modal-lg">
      <div class="modal-header">
        <div class="modal-title" id="field-modal-title">Tambah Lapangan</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('field-modal')">✕</button>
      </div>
      <div class="modal-body">
        <form id="field-form" onsubmit="submitFieldForm(event)">
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Nama Venue<span class="req">*</span></label>
              <input type="text" class="form-control" id="ff-venue-name" placeholder="cth: GOR Sabilulungan" required />
            </div>
            <div class="form-group">
              <label class="form-label">Jenis Olahraga<span class="req">*</span></label>
              <input type="text" class="form-control" id="ff-venue-type" placeholder="cth: Futsal, Badminton, Tenis..." required />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Area / Lantai<span class="req">*</span></label>
              <input type="text" class="form-control" id="ff-area" placeholder="cth: Lantai 1 / Hall A" required />
            </div>
            <div class="form-group">
              <label class="form-label">Harga (Rp)<span class="req">*</span></label>
              <input type="number" class="form-control" id="ff-price" placeholder="80000" min="0" step="1" required />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Satuan</label>
              <input type="text" class="form-control" id="ff-satuan" placeholder="cth: per jam, per hari, per sesi, per malam..." />
              <div style="font-size:11px;color:var(--text-muted);margin-top:4px;">
                💡 Satuan akan ditampilkan setelah harga, contoh: <strong>Rp 80.000 / per jam</strong>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Ukuran Lapangan</label>
              <input type="text" class="form-control" id="ff-ukuran" placeholder="cth: 16.8m x 24.95m" />
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Kapasitas</label>
            <input type="text" class="form-control" id="ff-kapasitas" placeholder="cth: 14 orang" />
          </div>

          <!-- ── Foto Lapangan (maks 6) ── -->
          <div class="form-group">
            <label class="form-label" style="display:flex;align-items:center;justify-content:space-between;">
              <span>Foto Lapangan</span>
              <span style="font-weight:400;font-size:11px;color:var(--text-muted);text-transform:none;letter-spacing:0;" id="ff-img-counter">0 / ${FIELD_MAX_IMAGES} foto</span>
            </label>
            <div id="ff-image-grid" style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:6px;"></div>
            <input type="file" id="ff-image-input" accept="image/*" multiple style="display:none;" onchange="handleFieldImageSelect(event)" />
            <div style="font-size:11px;color:var(--text-muted);margin-top:6px;">
              📸 Foto akan tampil sebagai <strong>carousel</strong> di aplikasi. Format JPG, PNG, WebP — maks 20 MB/foto.
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Deskripsi</label>
            <textarea class="form-control" id="ff-description" rows="2" placeholder="Deskripsi singkat lapangan..."></textarea>
          </div>
          <div class="form-group">
            <label class="form-label">Status</label>
            <select class="form-control form-select" id="ff-status">
              <option value="available">Tersedia</option>
              <option value="booked">Terpakai</option>
              <option value="maintenance">Maintenance</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Fasilitas</label>
            <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:4px;">
              ${facilityCheck('ff-parkir','tempat_parkir','🚗 Parkir')}
              ${facilityCheck('ff-mushola','mushola','🕌 Mushola')}
              ${facilityCheck('ff-cctv','cctv','📹 CCTV')}
              ${facilityCheck('ff-tunggu','ruang_tunggu','🪑 Ruang Tunggu')}
              ${facilityCheck('ff-ganti','ruang_ganti','🚿 Ruang Ganti')}
            </div>
          </div>
          <input type="hidden" id="ff-id" />
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('field-modal')">Batal</button>
        <button class="btn btn-gradient" onclick="document.getElementById('field-form').requestSubmit()" id="field-submit-btn">Simpan Lapangan</button>
      </div>
    </div>
  </div>`;

  loadFieldsTable(api);
  window._fieldAPI = api;
}

async function loadFieldsTable(api, page = _fPage) {
  _fPage = page;
  const wrap = document.getElementById('fields-table-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  const { data, count } = await api.getFields({ page: _fPage, limit: 10, status: _fStatus, search: _fSearch });

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">🏟️</div><h3>Belum ada lapangan</h3><p>Tambah lapangan baru untuk mulai.</p></div>`;
    document.getElementById('fields-pagination').innerHTML = '';
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>Nama Venue</th>
        <th>Jenis</th>
        <th>Area</th>
        <th>Harga</th>
        <th>Foto</th>
        <th>Fasilitas</th>
        <th>Status</th>
        <th>Aksi</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(f => {
        const imgs = Array.isArray(f.image_urls) ? f.image_urls : (f.image_urls ? [f.image_urls] : []);
        const thumb = imgs.length > 0
          ? `<div style="display:flex;gap:4px;align-items:center;">
               <img src="${imgs[0]}" style="width:44px;height:32px;object-fit:cover;border-radius:4px;border:1px solid var(--border);" onerror="this.style.display='none'" />
               ${imgs.length > 1 ? `<span style="font-size:11px;color:var(--text-muted);">+${imgs.length - 1}</span>` : ''}
             </div>`
          : `<span style="font-size:11px;color:var(--text-muted);">—</span>`;
        return `
        <tr>
          <td>
            <div class="font-bold">${f.venue_name}</div>
            ${f.ukuran_lapangan ? `<div class="text-sm text-muted">${f.ukuran_lapangan}</div>` : ''}
          </td>
          <td><span class="badge badge-info">${f.venue_type}</span></td>
          <td>${f.area}</td>
          <td style="font-weight:700;color:var(--success);">${fmtRp(f.price_per_hour)}<span style="font-weight:400;color:var(--text-muted);font-size:11px;"> / ${f.satuan || 'per jam'}</span></td>
          <td>${thumb}</td>
          <td>
            <div class="flex gap-2" style="flex-wrap:wrap;">
              ${f.tempat_parkir ? '<span title="Parkir" style="font-size:16px;">🚗</span>' : ''}
              ${f.mushola       ? '<span title="Mushola" style="font-size:16px;">🕌</span>' : ''}
              ${f.cctv          ? '<span title="CCTV" style="font-size:16px;">📹</span>' : ''}
              ${f.ruang_tunggu  ? '<span title="Ruang Tunggu" style="font-size:16px;">🪑</span>' : ''}
              ${f.ruang_ganti   ? '<span title="Ruang Ganti" style="font-size:16px;">🚿</span>' : ''}
            </div>
          </td>
          <td>${fieldStatusBadge(f.status)}</td>
          <td>
            <div class="flex gap-2">
              <button class="btn btn-outline btn-sm btn-icon" title="Edit" onclick="openFieldModal(${JSON.stringify(f).replace(/"/g,'&quot;')})">✏️</button>
              <button class="btn btn-danger btn-sm btn-icon" title="Hapus" onclick="deleteField('${f.id}','${f.venue_name}')">🗑️</button>
            </div>
          </td>
        </tr>`;
      }).join('')}
    </tbody>
  </table>`;

  const totalPages = Math.ceil(count / 10);
  document.getElementById('fields-pagination').innerHTML = renderPagination(_fPage, totalPages, count, 'loadFieldsPage');
  window.loadFieldsPage = (p) => loadFieldsTable(api, p);
}

window.openFieldModal = function(field = null) {
  document.getElementById('field-modal-title').textContent = field ? 'Edit Lapangan' : 'Tambah Lapangan';
  document.getElementById('ff-id').value          = field?.id || '';
  document.getElementById('ff-venue-name').value  = field?.venue_name || '';
  document.getElementById('ff-venue-type').value  = field?.venue_type || '';
  document.getElementById('ff-area').value         = field?.area || '';
  document.getElementById('ff-price').value        = field?.price_per_hour || '';
  document.getElementById('ff-satuan').value       = field?.satuan || '';
  document.getElementById('ff-ukuran').value       = field?.ukuran_lapangan || '';
  document.getElementById('ff-kapasitas').value    = field?.kapasitas || '';
  document.getElementById('ff-description').value  = field?.description || '';
  document.getElementById('ff-status').value       = field?.status || 'available';
  document.getElementById('ff-parkir').checked     = !!field?.tempat_parkir;
  document.getElementById('ff-mushola').checked    = !!field?.mushola;
  document.getElementById('ff-cctv').checked       = !!field?.cctv;
  document.getElementById('ff-tunggu').checked     = !!field?.ruang_tunggu;
  document.getElementById('ff-ganti').checked      = !!field?.ruang_ganti;

  // Pre-populate existing images
  _fieldImages = [];
  const existingUrls = Array.isArray(field?.image_urls)
    ? field.image_urls
    : (field?.image_urls ? [field.image_urls] : []);
  existingUrls.forEach(url => { if (url) _fieldImages.push({ type: 'url', url }); });
  _renderFieldImageGrid();

  openModal('field-modal');
};

/* ── Image Grid Renderer ──────────────────────────── */
function _renderFieldImageGrid() {
  const grid    = document.getElementById('ff-image-grid');
  const counter = document.getElementById('ff-img-counter');
  if (!grid) return;

  const slots = [];

  // Render existing / preview slots
  _fieldImages.forEach((img, i) => {
    const src = img.type === 'url' ? img.url : img.preview;
    slots.push(`
      <div style="position:relative;aspect-ratio:4/3;border-radius:var(--radius);overflow:hidden;border:1.5px solid var(--border);background:#000;">
        <img src="${src}" alt="Foto ${i + 1}"
          style="width:100%;height:100%;object-fit:cover;display:block;"
          onerror="this.style.display='none'" />
        <div style="position:absolute;bottom:4px;left:6px;background:rgba(0,0,0,0.55);border-radius:4px;padding:1px 6px;font-size:10px;color:#fff;font-weight:600;">${i + 1}</div>
        <button type="button" onclick="removeFieldImage(${i})"
          title="Hapus foto"
          style="position:absolute;top:4px;right:4px;background:rgba(220,38,38,0.85);border:none;border-radius:50%;width:22px;height:22px;color:#fff;cursor:pointer;font-size:13px;line-height:22px;text-align:center;padding:0;">✕</button>
      </div>`);
  });

  // Add-slot button (if still under max)
  if (_fieldImages.length < FIELD_MAX_IMAGES) {
    slots.push(`
      <div onclick="document.getElementById('ff-image-input').click()"
        style="aspect-ratio:4/3;border:2px dashed var(--border);border-radius:var(--radius);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;cursor:pointer;background:var(--bg-page);transition:border-color var(--transition),background var(--transition);"
        onmouseenter="this.style.borderColor='var(--primary-light)';this.style.background='var(--bg-hover)'"
        onmouseleave="this.style.borderColor='var(--border)';this.style.background='var(--bg-page)'">
        <svg width="24" height="24" fill="none" stroke="var(--primary-light)" stroke-width="1.5" viewBox="0 0 24 24">
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <circle cx="8.5" cy="8.5" r="1.5"/>
          <polyline points="21 15 16 10 5 21"/>
        </svg>
        <span style="font-size:11px;color:var(--text-muted);font-weight:600;">Tambah Foto</span>
      </div>`);
  }

  grid.innerHTML = slots.join('');
  if (counter) counter.textContent = `${_fieldImages.length} / ${FIELD_MAX_IMAGES} foto`;
}

/* ── File Select Handler ──────────────────────────── */
window.handleFieldImageSelect = function(e) {
  const files = Array.from(e.target.files || []);
  const remaining = FIELD_MAX_IMAGES - _fieldImages.length;
  const toAdd = files.slice(0, remaining);

  if (files.length > remaining) {
    showToast(`Maks ${FIELD_MAX_IMAGES} foto. ${files.length - remaining} file diabaikan.`, 'warning');
  }

  let processed = 0;
  toAdd.forEach(file => {
    if (file.size > 20 * 1024 * 1024) {
      showToast(`"${file.name}" terlalu besar (maks 20 MB).`, 'warning');
      processed++;
      if (processed === toAdd.length) _renderFieldImageGrid();
      return;
    }
    const reader = new FileReader();
    reader.onload = ev => {
      _fieldImages.push({ type: 'file', file, preview: ev.target.result });
      processed++;
      if (processed === toAdd.length) _renderFieldImageGrid();
    };
    reader.readAsDataURL(file);
  });

  // Reset input so same file can be re-selected
  e.target.value = '';
};

window.removeFieldImage = function(index) {
  _fieldImages.splice(index, 1);
  _renderFieldImageGrid();
};

/* ── Submit ───────────────────────────────────────── */
window.submitFieldForm = async function(e) {
  e.preventDefault();
  const btn = document.getElementById('field-submit-btn');
  btn.disabled = true;

  try {
    // Upload new file images first
    const finalUrls = [];
    const newFiles  = _fieldImages.filter(i => i.type === 'file');
    const existing  = _fieldImages.filter(i => i.type === 'url').map(i => i.url);

    if (newFiles.length > 0) {
      btn.innerHTML = `<span class="spinner spinner-sm"></span> Mengupload ${newFiles.length} foto...`;
      for (const img of newFiles) {
        const result = await window._fieldAPI.uploadFieldImage(img.file);
        finalUrls.push(result.publicUrl);
      }
    }

    btn.innerHTML = '<span class="spinner spinner-sm"></span> Menyimpan...';

    // Preserve order: existing URLs first, then newly uploaded
    const allImageUrls = [...existing, ...finalUrls];

    const payload = {
      venue_name:      document.getElementById('ff-venue-name').value.trim(),
      venue_type:      document.getElementById('ff-venue-type').value,
      area:            document.getElementById('ff-area').value.trim(),
      price_per_hour:  parseInt(document.getElementById('ff-price').value),
      satuan:          document.getElementById('ff-satuan').value.trim() || null,
      ukuran_lapangan: document.getElementById('ff-ukuran').value.trim() || null,
      kapasitas:       document.getElementById('ff-kapasitas').value.trim() || null,
      description:     document.getElementById('ff-description').value.trim() || null,
      status:          document.getElementById('ff-status').value,
      image_urls:      allImageUrls.length > 0 ? allImageUrls : null,
      tempat_parkir:   document.getElementById('ff-parkir').checked,
      mushola:         document.getElementById('ff-mushola').checked,
      cctv:            document.getElementById('ff-cctv').checked,
      ruang_tunggu:    document.getElementById('ff-tunggu').checked,
      ruang_ganti:     document.getElementById('ff-ganti').checked,
      updated_at:      new Date().toISOString(),
    };

    const id = document.getElementById('ff-id').value;
    if (id) await window._fieldAPI.updateField(id, payload);
    else     await window._fieldAPI.createField({ ...payload, created_at: new Date().toISOString() });

    showToast(id ? 'Lapangan berhasil diperbarui! ✅' : 'Lapangan berhasil ditambahkan! ✅', 'success');
    closeModal('field-modal');
    loadFieldsTable(window._fieldAPI);
  } catch(err) {
    showToast('Gagal menyimpan: ' + err.message, 'error');
  }

  btn.disabled = false;
  btn.textContent = 'Simpan Lapangan';
};

window.deleteField = async function(id, name) {
  if (!confirm(`Hapus lapangan "${name}"? Data yang sudah terhapus tidak bisa dikembalikan.`)) return;
  try {
    await window._fieldAPI.deleteField(id);
    showToast('Lapangan berhasil dihapus.', 'success');
    loadFieldsTable(window._fieldAPI);
  } catch(e) { showToast('Gagal menghapus: ' + e.message, 'error'); }
};

let _fSearchTimer;
window.debounceFieldSearch = function(val) {
  clearTimeout(_fSearchTimer);
  _fSearchTimer = setTimeout(() => { _fSearch = val; _fPage = 1; loadFieldsTable(window._fieldAPI); }, 400);
};
window.filterField = function(type, val) {
  if (type === 'status') _fStatus = val;
  _fPage = 1; loadFieldsTable(window._fieldAPI);
};

function facilityCheck(id, name, label) {
  return `<label style="display:flex;align-items:center;gap:8px;font-size:13px;cursor:pointer;">
    <input type="checkbox" id="${id}" name="${name}" style="width:15px;height:15px;accent-color:var(--primary);cursor:pointer;" />
    ${label}
  </label>`;
}

function fieldStatusBadge(s) {
  const m = { available:'badge-success', booked:'badge-warning', maintenance:'badge-danger' };
  const l = { available:'Tersedia', booked:'Terpakai', maintenance:'Maintenance' };
  return `<span class="badge ${m[s]||'badge-gray'}">${l[s]||s}</span>`;
}
