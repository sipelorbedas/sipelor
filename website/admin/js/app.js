// =============================================
// SIPELOR BEDAS — Admin SPA Core
// Router · Auth Guard · Navigation · Utilities
// =============================================

/* ── State ──────────────────────────────────── */
let supabaseClient  = null;
let currentUser     = null;
let currentView     = 'dashboard';
let api             = null;
let _pendingCount   = 0;

/* ── Init ───────────────────────────────────── */
document.addEventListener('DOMContentLoaded', async () => {
  // Init Supabase
  try {
    const url = SIPELOR_ADMIN_CONFIG.SUPABASE_URL;
    const key = SIPELOR_ADMIN_CONFIG.SUPABASE_ANON_KEY;
    if (url && url !== 'YOUR_SUPABASE_URL' && key && key !== 'YOUR_SUPABASE_ANON_KEY') {
      supabaseClient = supabase.createClient(url, key);
    }
  } catch(e) { console.warn('[SIPELOR] Supabase init error:', e); }

  api = new AdminAPI(supabaseClient);

  // Auth check
  await checkAuth();
});

async function checkAuth() {
  if (!supabaseClient) {
    // No Supabase, no demo → back to login
    window.location.href = 'login.html';
    return;
  }

  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) { window.location.href = 'login.html'; return; }

  const { data: profile } = await supabaseClient
    .from('profiles').select('*').eq('id', session.user.id).single();
  const role = profile?.role || '';

  if (!['admin','superadmin','manager','operator','wasit','opd'].includes(role)) {
    await supabaseClient.auth.signOut();
    window.location.href = 'login.html';
    return;
  }

  currentUser = {
    id:     session.user.id,
    email:  session.user.email,
    name:   profile?.full_name || session.user.email.split('@')[0],
    role:   role,
    avatar: (profile?.full_name || 'A')[0].toUpperCase(),
  };
  bootApp();
}

function bootApp() {
  renderShell();

  // OPD role: hide everything except Turnamen & Cup, force route to tournament
  if (currentUser.role === 'opd') {
    applyOPDRestrictions();
    navigate('tournament');
  } else {
    // Route to hash or dashboard
    const hash = location.hash.replace('#','') || 'dashboard';
    navigate(hash);
  }

  // Pending badge (bookings)
  refreshPendingCount();
  setInterval(refreshPendingCount, 60000);
  // Chat unread badge
  refreshChatUnreadCount();
  setInterval(refreshChatUnreadCount, 30000);
  // Global realtime subscription — update badge saat user kirim pesan
  if (supabaseClient) {
    supabaseClient
      .channel('global_chat_notifications')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'chat_messages' }, () => {
        refreshChatUnreadCount();
      })
      .subscribe();

    // Realtime — tampilkan dot merah di nav Pemesanan saat ada booking baru masuk
    supabaseClient
      .channel('global_booking_notifications')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'bookings' }, () => {
        refreshPendingCount();
        if (currentView !== 'bookings') {
          const dot = document.getElementById('nav-dot-bookings');
          if (dot) dot.style.display = '';
        }
      })
      .subscribe();
  }
}

async function refreshPendingCount() {
  const stats = await api.getDashboardStats();
  _pendingCount = stats.pendingPayments || 0;
  const badge = document.getElementById('nav-badge-bookings');
  if (badge) {
    badge.textContent = _pendingCount;
    badge.style.display = _pendingCount > 0 ? '' : 'none';
  }
}

async function refreshChatUnreadCount() {
  try {
    const convs = await api.getChatConversations();
    const total = convs.reduce((s, c) => s + (c.unreadCount || 0), 0);
    updateChatUnreadBadge(total);
  } catch (_) { /* silent */ }
}

window.updateChatUnreadBadge = function(count) {
  // Sidebar — badge di nav item Chat
  const sidebarBadge = document.getElementById('nav-badge-chat');
  if (sidebarBadge) {
    sidebarBadge.textContent = count > 99 ? '99+' : count;
    sidebarBadge.style.display = count > 0 ? '' : 'none';
  }
  // Topbar — titik merah di ikon notifikasi
  const topbarBadge = document.getElementById('topbar-notif-badge');
  if (topbarBadge) {
    topbarBadge.style.display = count > 0 ? '' : 'none';
  }
};

/* ── Shell Render ───────────────────────────── */
function renderShell() {
  const initials = (currentUser.name || 'A').split(' ').map(w => w[0]).join('').toUpperCase().substring(0,2);

  document.getElementById('app').innerHTML = `
  <div class="app-shell">
    <!-- Sidebar -->
    <aside class="sidebar" id="sidebar">
      <div class="sidebar-logo">
        <div class="logo-icon">🏟️</div>
        <div class="logo-text">
          <div class="logo-title">SIPELOR</div>
          <div class="logo-sub">Admin Panel</div>
        </div>
      </div>

      <nav class="sidebar-nav">
        <div class="nav-section-title">Menu Utama</div>

        <div class="nav-item" data-view="tournament" onclick="navigate('tournament')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>
          </span>
          <span class="nav-label">Turnamen & Cup</span>
        </div>

        <div class="nav-item active" data-view="dashboard" onclick="navigate('dashboard')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
          </span>
          <span class="nav-label">Dashboard</span>
        </div>

        <div class="nav-item" data-view="bookings" onclick="navigate('bookings')">
          <span class="nav-icon" style="position:relative;">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/><path d="M9 12h6M9 16h4"/></svg>
            <span class="nav-dot" id="nav-dot-bookings" style="display:none;"></span>
          </span>
          <span class="nav-label">Pemesanan</span>
          <span class="nav-badge" id="nav-badge-bookings" style="display:none;">0</span>
        </div>

        <div class="nav-item" data-view="fields" onclick="navigate('fields')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          </span>
          <span class="nav-label">Lapangan</span>
        </div>

        <div class="nav-item" data-view="carousel" onclick="navigate('carousel')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 3h-4l-2 4h8l-2-4z"/><circle cx="8" cy="14" r="1"/><circle cx="12" cy="14" r="1"/><circle cx="16" cy="14" r="1"/></svg>
          </span>
          <span class="nav-label">Carousel Banner</span>
        </div>

        <div class="nav-item" data-view="popup" onclick="navigate('popup')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M3 9h18M9 21V9"/></svg>
          </span>
          <span class="nav-label">Popup Banner</span>
        </div>

        <div class="nav-item" data-view="users" onclick="navigate('users')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          </span>
          <span class="nav-label">Pengguna</span>
        </div>

        <div class="nav-section-title">Manajemen</div>

        <div class="nav-item" data-view="staff" onclick="navigate('staff')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/><path d="M12 12v9M8 17l4-4 4 4"/></svg>
          </span>
          <span class="nav-label">Staff</span>
        </div>

        <div class="nav-item" data-view="opd" onclick="navigate('opd')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 14v3M12 14v3M16 14v3"/></svg>
          </span>
          <span class="nav-label">OPD / Pimpinan</span>
        </div>

        <div class="nav-item" data-view="analytics" onclick="navigate('analytics')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
          </span>
          <span class="nav-label">Analitik</span>
        </div>

        <div class="nav-item" data-view="chat" onclick="navigate('chat')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          </span>
          <span class="nav-label">Chat</span>
          <span class="nav-badge" id="nav-badge-chat" style="display:none;">0</span>
        </div>

        <div class="nav-section-title">Sistem</div>

        <div class="nav-item" data-view="reports" onclick="navigate('reports')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
          </span>
          <span class="nav-label">Cetak Laporan</span>
        </div>

        <div class="nav-item" data-view="reviews" onclick="navigate('reviews')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          </span>
          <span class="nav-label">Review</span>
        </div>

        <div class="nav-item" data-view="audit" onclick="navigate('audit')">
          <span class="nav-icon">
            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          </span>
          <span class="nav-label">Audit Log</span>
        </div>
      </nav>

      <div class="sidebar-footer">
        <div class="sidebar-user" onclick="toggleUserMenu()">
          <div class="user-avatar">${initials}</div>
          <div class="user-info">
            <div class="user-name">${currentUser.name}</div>
            <div class="user-role">${capitalize(currentUser.role)}</div>
          </div>
        </div>
      </div>
    </aside>

    <!-- Main -->
    <div class="main-content" id="main-content">
      <!-- Topbar -->
      <header class="topbar">
        <button class="topbar-toggle" onclick="toggleSidebar()" title="Toggle Sidebar">
          <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
        </button>

        <div class="topbar-breadcrumb">
          <span>SIPELOR</span>
          <span class="crumb-sep">/</span>
          <span class="crumb-current" id="breadcrumb-current">Dashboard</span>
        </div>

        <div class="topbar-search">
          <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
          <input type="text" placeholder="Cari..." id="global-search" />
        </div>

        <div class="topbar-actions">
          <button class="topbar-btn" id="topbar-notif-btn" title="Notifikasi Pesan Baru" onclick="navigate('chat')">
            <svg width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            <span class="badge" id="topbar-notif-badge" style="display:none;"></span>
          </button>

          <div class="dropdown-wrapper">
            <button class="topbar-user" onclick="toggleDropdown('user-dropdown')">
              <div class="avatar">${initials}</div>
              <span class="name">${currentUser.name.split(' ')[0]}</span>
              <svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>
            </button>
            <div class="dropdown-menu" id="user-dropdown">
              <div class="dropdown-item" onclick="navigate('audit')">
                <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/></svg>
                Audit Log
              </div>
              <div class="dropdown-divider"></div>
              <div class="dropdown-item danger" onclick="handleLogout()">
                <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                Keluar
              </div>
            </div>
          </div>
        </div>
      </header>

      <!-- Page Body -->
      <main class="page-body" id="page-content"></main>
    </div>
  </div>

  <!-- Toast Container -->
  <div class="toast-container" id="toast-container"></div>`;

  // Global click → close dropdowns
  document.addEventListener('click', e => {
    if (!e.target.closest('.dropdown-wrapper')) {
      document.querySelectorAll('.dropdown-menu.open').forEach(d => d.classList.remove('open'));
    }
    if (!e.target.closest('.modal') && !e.target.closest('[onclick]')) {
      // don't auto-close modal on backdrop in this simple impl
    }
  });
}

/* ── Router ─────────────────────────────────── */
const VIEWS = {
  dashboard:  { title: 'Dashboard',        fn: (a, c) => renderDashboard(a, c) },
  tournament: { title: 'Turnamen',         fn: (a, c) => renderTournament(a, c) },
  bookings:   { title: 'Pemesanan',        fn: (a, c) => renderBookings(a, c) },
  fields:    { title: 'Lapangan',          fn: (a, c) => renderFields(a, c) },
  carousel:  { title: 'Carousel Banner',   fn: (a, c) => renderCarousel(a, c) },
  popup:     { title: 'Popup Banner',      fn: (a, c) => renderPopup(a, c) },
  staff:     { title: 'Staff',             fn: (a, c) => renderStaff(a, c) },
  opd:       { title: 'OPD / Pimpinan',   fn: (a, c) => renderOPD(a, c) },
  analytics: { title: 'Analitik',          fn: (a, c) => renderAnalytics(a, c) },
  reports:   { title: 'Cetak Laporan',     fn: (a, c) => renderReports(a, c) },
  reviews:   { title: 'Review',            fn: (a, c) => renderReviews(a, c) },
  audit:     { title: 'Audit Log',         fn: (a, c) => renderAudit(a, c) },
  users:     { title: 'Pengguna',          fn: (a, c) => renderUsers(a, c) },
  chat:      { title: 'Chat',              fn: (a, c) => renderChat(a, c) },
};

window.navigate = function(view) {
  // OPD role can only access Turnamen & Cup
  if (currentUser && currentUser.role === 'opd' && view !== 'tournament') {
    view = 'tournament';
  }

  const v = VIEWS[view];
  if (!v) { navigate('dashboard'); return; }

  currentView = view;
  location.hash = view;

  // Update nav
  document.querySelectorAll('.nav-item').forEach(n => {
    n.classList.toggle('active', n.dataset.view === view);
  });

  // Update breadcrumb
  const bc = document.getElementById('breadcrumb-current');
  if (bc) bc.textContent = v.title;

  // Clear new-booking dot when admin opens Pemesanan
  if (view === 'bookings') {
    const dot = document.getElementById('nav-dot-bookings');
    if (dot) dot.style.display = 'none';
  }

  // Render page
  const content = document.getElementById('page-content');
  if (content) v.fn(api, content);

  // Close any open dropdown
  document.querySelectorAll('.dropdown-menu.open').forEach(d => d.classList.remove('open'));
  // Scroll top
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

/* ── OPD Restrictions ───────────────────────── */
function applyOPDRestrictions() {
  // Hide all nav items except "Turnamen & Cup"
  document.querySelectorAll('.nav-item').forEach(item => {
    if (item.dataset.view !== 'tournament') {
      item.style.display = 'none';
    }
  });
  // Hide nav section titles (no longer meaningful with one item)
  document.querySelectorAll('.nav-section-title').forEach(el => {
    el.style.display = 'none';
  });
}

/* ── Sidebar Toggle ─────────────────────────── */
window.toggleSidebar = function() {
  const sb = document.getElementById('sidebar');
  const mc = document.getElementById('main-content');
  sb?.classList.toggle('collapsed');
};

/* ── Dropdown ───────────────────────────────── */
window.toggleDropdown = function(id) {
  const el = document.getElementById(id);
  if (!el) return;
  const wasOpen = el.classList.contains('open');
  document.querySelectorAll('.dropdown-menu.open').forEach(d => d.classList.remove('open'));
  if (!wasOpen) el.classList.add('open');
};

/* ── Modal ──────────────────────────────────── */
window.openModal = function(id) {
  document.getElementById(id)?.classList.add('open');
  document.body.style.overflow = 'hidden';
};
window.closeModal = function(id) {
  document.getElementById(id)?.classList.remove('open');
  document.body.style.overflow = '';
};

/* ── Logout ─────────────────────────────────── */
window.handleLogout = async function() {
  if (!confirm('Keluar dari panel admin?')) return;
  if (supabaseClient) await supabaseClient.auth.signOut();
  window.location.href = 'login.html';
};

window.toggleUserMenu = function() {
  toggleDropdown('user-dropdown');
};

/* ── Toast ──────────────────────────────────── */
window.showToast = function(message, type = 'info', duration = 3500) {
  const container = document.getElementById('toast-container')
    || (() => { const el = document.createElement('div'); el.id = 'toast-container'; el.className = 'toast-container'; document.body.appendChild(el); return el; })();
  const icons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${icons[type] || 'ℹ️'}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(20px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 350);
  }, duration);
};

/* ── Pagination Helper ──────────────────────── */
function renderPagination(page, totalPages, totalCount, callbackName) {
  if (totalPages <= 1) return '';
  const start = 1;
  const end   = Math.min(totalPages, totalCount);
  const pages = [];
  for (let p = Math.max(1, page - 2); p <= Math.min(totalPages, page + 2); p++) {
    pages.push(p);
  }
  const btns = pages.map(p =>
    `<button class="page-btn ${p === page ? 'active' : ''}" onclick="${callbackName}(${p})">${p}</button>`
  ).join('');
  return `<div class="pagination">
    <span>Menampilkan ${((page-1)*10)+1}–${Math.min(page*10, totalCount)} dari ${totalCount} data</span>
    <div class="page-btns">
      <button class="page-btn" onclick="${callbackName}(${Math.max(1, page-1)})" ${page===1?'disabled':''}>‹</button>
      ${btns}
      <button class="page-btn" onclick="${callbackName}(${Math.min(totalPages, page+1)})" ${page===totalPages?'disabled':''}>›</button>
    </div>
  </div>`;
}

/* ── Global Formatters ──────────────────────── */
function fmtRp(amount) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount || 0);
}

function fmtDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr.includes('T') ? dateStr : dateStr + 'T00:00:00');
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
}

function fmtDateTime(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

/**
 * Format waktu dari berbagai format Supabase / PostgreSQL:
 *  - "HH:MM:SS"   → "HH:MM"
 *  - "HH:MM"      → "HH:MM"
 *  - ISO datetime → extract jam:menit
 *  - null/undefined → "—"
 */
function fmtTime(timeStr) {
  if (!timeStr) return '—';
  // Full ISO datetime (e.g. "2024-01-15T08:00:00+07:00")
  if (timeStr.includes('T')) {
    const d = new Date(timeStr);
    return isNaN(d) ? '—' : d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  }
  // PostgreSQL TIME type: "08:00:00" → "08:00"
  if (/^\d{1,2}:\d{2}:\d{2}$/.test(timeStr)) return timeStr.substring(0, 5);
  // Already "HH:MM"
  if (/^\d{1,2}:\d{2}$/.test(timeStr)) return timeStr;
  return timeStr;
}

function capitalize(str) {
  return str ? str.charAt(0).toUpperCase() + str.slice(1) : '';
}

/* ── Status Badge Helpers ───────────────────── */
function bookingStatusBadge(status) {
  const map = {
    pending:   ['badge-warning', 'Menunggu'],
    confirmed: ['badge-success', 'Dikonfirmasi'],
    completed: ['badge-info',    'Selesai'],
    cancelled: ['badge-danger',  'Dibatalkan'],
  };
  const [cls, label] = map[status] || ['badge-gray', status];
  return `<span class="badge ${cls}">${label}</span>`;
}

function paymentStatusBadge(status) {
  const map = {
    pending:  ['badge-warning', '⏳ Menunggu'],
    verified: ['badge-success', '✓ Terverifikasi'],
    rejected: ['badge-danger',  '✕ Ditolak'],
  };
  const [cls, label] = map[status] || ['badge-gray', status];
  return `<span class="badge ${cls}">${label}</span>`;
}
