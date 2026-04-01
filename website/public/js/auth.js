// =============================================
// SIPELOR BEDAS — Auth Handler
// Login, Register, Logout via Supabase
// =============================================

document.addEventListener('DOMContentLoaded', () => {
  // Handle tabs login/register
  const tabs = document.querySelectorAll('.auth-tab');
  const panels = document.querySelectorAll('.auth-form-panel');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.dataset.tab;
      tabs.forEach(t => t.classList.remove('active'));
      panels.forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById(`panel-${target}`)?.classList.add('active');
    });
  });

  // Cek jika sudah login
  checkAuthSessionOnAuthPage();

  // Login Form
  const loginForm = document.getElementById('login-form');
  if (loginForm) loginForm.addEventListener('submit', handleLogin);

  // Register Form
  const registerForm = document.getElementById('register-form');
  if (registerForm) registerForm.addEventListener('submit', handleRegister);

  // Password toggle
  document.querySelectorAll('.toggle-password').forEach(btn => {
    btn.addEventListener('click', () => {
      const input = btn.previousElementSibling;
      const isPassword = input.type === 'password';
      input.type = isPassword ? 'text' : 'password';
      btn.textContent = isPassword ? '🙈' : '👁️';
    });
  });

  // Update navbar auth state
  updateNavbarAuth();
});

async function checkAuthSessionOnAuthPage() {
  // Hanya redirect jika berada di halaman auth
  if (!document.getElementById('panel-login')) return;
  if (!supabaseClient) return;
  const user = await getCurrentUser();
  if (user) {
    const redirect = localStorage.getItem('auth_redirect') || '/booking';
    localStorage.removeItem('auth_redirect');
    window.location.href = redirect;
  }
}

async function handleLogin(e) {
  e.preventDefault();
  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  const btn = document.getElementById('login-btn');

  if (!email || !password) {
    showToast('Email dan password harus diisi!', 'error');
    return;
  }

  btn.disabled = true;
  btn.innerHTML = '<span class="loading-spinner" style="width:18px;height:18px;border-width:2px;display:inline-block;vertical-align:middle;margin-right:8px"></span>Masuk...';

  // Mode Demo (Supabase belum dikonfigurasi)
  if (!supabaseClient) {
    await simulateDelay(1500);
    if (email === 'demo@sipelor.com' && password === 'demo123') {
      localStorage.setItem('sipelor_demo_user', JSON.stringify({
        id: 'demo-user',
        email: email,
        name: 'Demo User',
        role: 'user',
      }));
      showToast('Login berhasil! Selamat datang 👋', 'success');
      const redirect = localStorage.getItem('auth_redirect') || '/booking';
      localStorage.removeItem('auth_redirect');
      setTimeout(() => { window.location.href = redirect; }, 1200);
    } else {
      showToast('Email atau password salah. (Demo: demo@sipelor.com / demo123)', 'error');
      btn.disabled = false;
      btn.textContent = 'Masuk';
    }
    return;
  }

  try {
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) throw error;
    showToast(`Selamat datang kembali, ${data.user.email.split('@')[0]}! 👋`, 'success');
    const redirect = localStorage.getItem('auth_redirect') || '/booking';
    localStorage.removeItem('auth_redirect');
    setTimeout(() => { window.location.href = redirect; }, 1200);
  } catch (err) {
    const messages = {
      'Invalid login credentials': 'Email atau password salah.',
      'Email not confirmed': 'Silakan verifikasi email Anda terlebih dahulu.',
      'Too many requests': 'Terlalu banyak percobaan. Coba lagi beberapa menit.',
    };
    showToast(messages[err.message] || err.message, 'error');
    btn.disabled = false;
    btn.textContent = 'Masuk';
  }
}

async function handleRegister(e) {
  e.preventDefault();
  const name     = document.getElementById('reg-name').value.trim();
  const email    = document.getElementById('reg-email').value.trim();
  const phone    = document.getElementById('reg-phone').value.trim();
  const password = document.getElementById('reg-password').value;
  const confirm  = document.getElementById('reg-confirm').value;
  const terms    = document.getElementById('reg-terms').checked;
  const btn      = document.getElementById('register-btn');

  if (!name || !email || !password || !confirm) { showToast('Semua field harus diisi!', 'error'); return; }
  if (password.length < 8) { showToast('Password minimal 8 karakter', 'error'); return; }
  if (password !== confirm) {
    showToast('Password tidak cocok!', 'error');
    document.getElementById('reg-confirm').classList.add('error');
    return;
  }
  if (!terms) { showToast('Anda harus menyetujui syarat & ketentuan', 'error'); return; }

  btn.disabled = true;
  btn.innerHTML = '<span class="loading-spinner" style="width:18px;height:18px;border-width:2px;display:inline-block;vertical-align:middle;margin-right:8px"></span>Mendaftar...';

  if (!supabaseClient) {
    await simulateDelay(1500);
    showToast('Akun berhasil dibuat! Silakan login.', 'success');
    document.querySelector('[data-tab="login"]')?.click();
    document.getElementById('login-email').value = email;
    btn.disabled = false;
    btn.textContent = 'Daftar Sekarang';
    return;
  }

  try {
    const { data, error } = await supabaseClient.auth.signUp({
      email,
      password,
      options: { data: { full_name: name, phone } },
    });
    if (error) throw error;
    if (data?.user?.confirmation_sent_at) {
      showToast('Cek email Anda untuk konfirmasi akun! 📧', 'success', 5000);
      document.querySelector('[data-tab="login"]')?.click();
    } else {
      showToast('Akun berhasil dibuat!', 'success');
      setTimeout(() => { window.location.href = '/booking'; }, 1200);
    }
  } catch (err) {
    const messages = { 'User already registered': 'Email sudah terdaftar. Silakan login.' };
    showToast(messages[err.message] || err.message, 'error');
    btn.disabled = false;
    btn.textContent = 'Daftar Sekarang';
  }
}
