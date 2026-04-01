// =============================================
// SIPELOR BEDAS — Helpers & Utilities
// Dibaca setelah SIPELOR_CONFIG di-inject via PHP
// =============================================

let supabaseClient = null;

function initSupabase() {
  const url = SIPELOR_CONFIG?.SUPABASE_URL || '';
  const key = SIPELOR_CONFIG?.SUPABASE_ANON_KEY || '';
  if (!url || !key || url === 'YOUR_SUPABASE_URL') {
    console.warn('⚠️ Supabase belum dikonfigurasi. Isi SUPABASE_URL dan SUPABASE_ANON_KEY di file .env');
    return null;
  }
  try {
    supabaseClient = window.supabase.createClient(url, key);
    console.log('✅ Supabase client initialized');
    return supabaseClient;
  } catch (e) {
    console.error('❌ Supabase init failed:', e);
    return null;
  }
}

// Auto-init saat helpers.js dimuat
document.addEventListener('DOMContentLoaded', () => {
  initSupabase();
});

async function getCurrentUser() {
  if (!supabaseClient) return null;
  try {
    const { data: { user } } = await supabaseClient.auth.getUser();
    return user;
  } catch { return null; }
}

// Format angka ke Rupiah
function formatRupiah(amount) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// Format tanggal ke Bahasa Indonesia
function formatDateID(dateStr) {
  const date = new Date(dateStr + 'T00:00:00');
  return date.toLocaleDateString('id-ID', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

// Toast notification
function showToast(message, type = 'info', duration = 3500) {
  const container = document.getElementById('toast-container') || (() => {
    const el = document.createElement('div');
    el.id = 'toast-container';
    el.className = 'toast-container';
    document.body.appendChild(el);
    return el;
  })();
  const icons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${icons[type] || 'ℹ️'}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(20px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

function showLoading(text = 'Memuat...') {
  if (document.getElementById('loading-overlay')) return;
  const overlay = document.createElement('div');
  overlay.id = 'loading-overlay';
  overlay.className = 'loading-overlay';
  overlay.innerHTML = `<div class="loading-spinner"></div><p class="loading-text">${text}</p>`;
  document.body.appendChild(overlay);
}

function hideLoading() {
  document.getElementById('loading-overlay')?.remove();
}

function simulateDelay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Update navbar berdasarkan status auth
async function updateNavbarAuth() {
  const user = await getCurrentUser() || JSON.parse(localStorage.getItem('sipelor_demo_user') || 'null');
  const loginBtn = document.getElementById('nav-login-btn');
  const userMenu = document.getElementById('nav-user-menu');
  if (user && loginBtn && userMenu) {
    loginBtn.style.display = 'none';
    userMenu.style.display = 'flex';
    const nameEl = document.getElementById('nav-user-name');
    if (nameEl) nameEl.textContent = user.user_metadata?.full_name || user.name || user.email?.split('@')[0] || 'User';
  }
}

async function handleLogout() {
  if (supabaseClient) await supabaseClient.auth.signOut();
  localStorage.removeItem('sipelor_demo_user');
  localStorage.removeItem('sipelor_booking_draft');
  window.location.href = '/';
}
