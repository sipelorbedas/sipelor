// ─────────────────────────────────────────────────────
// REVIEWS VIEW
// ─────────────────────────────────────────────────────

let _rPage = 1, _rRating = '', _rSearch = '';

async function renderReviews(api, container) {
  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">Moderasi Review</div>
      <div class="page-subtitle">Monitor dan moderasi ulasan pengguna terhadap lapangan olahraga.</div>
    </div>
  </div>

  <div class="card">
    <div class="table-controls">
      <div class="table-search">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
        <input type="text" placeholder="Cari komentar..." oninput="debounceReviewSearch(this.value)" />
      </div>
      <select class="form-control form-select" style="width:auto;padding:8px 36px 8px 12px;font-size:13px;" onchange="filterReview('rating',this.value)">
        <option value="">Semua Rating</option>
        <option value="5">⭐⭐⭐⭐⭐ (5)</option>
        <option value="4">⭐⭐⭐⭐ (4)</option>
        <option value="3">⭐⭐⭐ (3)</option>
        <option value="2">⭐⭐ (2)</option>
        <option value="1">⭐ (1)</option>
      </select>
    </div>

    <div class="table-wrap" id="reviews-table-wrap">
      <div class="page-loader"><span class="spinner"></span></div>
    </div>
    <div id="reviews-pagination"></div>
  </div>`;

  loadReviewsTable(api);
  window._reviewAPI = api;
}

async function loadReviewsTable(api, page = _rPage) {
  _rPage = page;
  const wrap = document.getElementById('reviews-table-wrap');
  if (!wrap) return;
  wrap.innerHTML = `<div class="page-loader"><span class="spinner"></span></div>`;

  let data = [], count = 0;
  try {
    const res = await api.getReviews({ page: _rPage, limit: 10, rating: _rRating, search: _rSearch });
    data  = res.data  || [];
    count = res.count || 0;
  } catch (e) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⚠️</div><h3>Gagal memuat review</h3><p style="color:var(--text-muted);font-size:13px;">${e.message || 'Terjadi kesalahan.'}</p></div>`;
    document.getElementById('reviews-pagination').innerHTML = '';
    return;
  }

  if (!data.length) {
    wrap.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⭐</div><h3>Belum ada review</h3><p>Belum ada ulasan yang diberikan pengguna.</p></div>`;
    document.getElementById('reviews-pagination').innerHTML = '';
    return;
  }

  wrap.innerHTML = `
  <table>
    <thead>
      <tr>
        <th>Pengguna</th>
        <th>Lapangan</th>
        <th>Rating</th>
        <th>Komentar</th>
        <th>Tanggal</th>
        <th>Aksi</th>
      </tr>
    </thead>
    <tbody>
      ${data.map(r => {
        const userName  = r.profiles?.full_name || '—';
        const userEmail = r.profiles?.email     || '';
        const venueName = r.bookings?.fields?.venue_name || r.venue_name || '—';
        const initial   = (r.profiles?.full_name || 'U')[0].toUpperCase();
        const stars     = Number.isInteger(r.rating) && r.rating > 0
          ? '⭐'.repeat(Math.min(r.rating, 5))
          : '—';
        const safeComment = (r.comment || '').replace(/`/g, '&#96;').replace(/\$/g, '&#36;');
        return `
        <tr>
          <td>
            <div class="flex items-center gap-2">
              <div class="avatar-sm">${initial}</div>
              <div>
                <div class="font-medium" style="font-size:13px;">${userName}</div>
                <div class="text-sm text-muted">${userEmail}</div>
              </div>
            </div>
          </td>
          <td style="font-size:13px;">${venueName}</td>
          <td>
            <div class="stars">${stars}</div>
            <div style="font-size:11px;color:var(--text-muted);">${r.rating || '—'}/5</div>
          </td>
          <td style="max-width:240px;">
            <div style="font-size:13px;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;">
              ${safeComment || '<em style="color:var(--text-muted)">Tidak ada komentar</em>'}
            </div>
          </td>
          <td style="font-size:12px;color:var(--text-muted);white-space:nowrap;">${fmtDateTime(r.created_at)}</td>
          <td>
            <button class="btn btn-danger btn-sm btn-icon" title="Hapus review" onclick="deleteReview('${r.id}')">🗑️</button>
          </td>
        </tr>`;
      }).join('')}
    </tbody>
  </table>`;

  const totalPages = Math.ceil(count / 10);
  document.getElementById('reviews-pagination').innerHTML = renderPagination(_rPage, totalPages, count, 'loadReviewsPage');
  window.loadReviewsPage = (p) => loadReviewsTable(api, p);
}

window.deleteReview = async function(id) {
  if (!confirm('Hapus review ini? Tindakan tidak bisa dibatalkan.')) return;
  try {
    await window._reviewAPI.deleteReview(id);
    showToast('Review berhasil dihapus.', 'success');
    loadReviewsTable(window._reviewAPI);
  } catch(e) { showToast('Gagal menghapus: ' + e.message, 'error'); }
};

let _rSearchTimer;
window.debounceReviewSearch = function(val) {
  clearTimeout(_rSearchTimer);
  _rSearchTimer = setTimeout(() => { _rSearch = val; _rPage = 1; loadReviewsTable(window._reviewAPI); }, 400);
};
window.filterReview = function(type, val) {
  if (type === 'rating') _rRating = val;
  _rPage = 1; loadReviewsTable(window._reviewAPI);
};
