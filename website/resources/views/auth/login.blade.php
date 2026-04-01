@extends('layouts.base')

@section('title', 'Masuk / Daftar — SIPELOR BEDAS')
@section('description', 'Login atau daftar akun SIPELOR BEDAS untuk booking lapangan olahraga di Sumedang.')

@section('content')

<div class="auth-page">
  <!-- ===== VISUAL SIDE ===== -->
  <div class="auth-visual">
    <img
      src="https://images.pexels.com/photos/16378314/pexels-photo-16378314.jpeg?auto=compress&cs=tinysrgb&w=900"
      alt="Sports venue - Laura Rincón on Pexels"
      class="auth-visual-img"
    >
    <div class="auth-visual-overlay"></div>
    <div class="auth-visual-content">
      <a href="{{ route('home') }}" style="display:flex;align-items:center;gap:10px;margin-bottom:auto">
        <div class="navbar-logo-icon" style="width:44px;height:44px;font-size:22px">SB</div>
        <span class="navbar-logo-text" style="font-size:24px">SIPELOR <span>BEDAS</span></span>
      </a>
      <div>
        <div class="auth-visual-quote">"Olahraga itu<br>bukan pilihan,<br>tapi kebutuhan."</div>
        <div class="auth-visual-author">— SIPELOR BEDAS, Sumedang</div>
        <div style="margin-top:32px;display:flex;gap:12px;flex-wrap:wrap">
          <div style="display:flex;align-items:center;gap:8px;padding:8px 16px;border-radius:40px;background:rgba(255,255,255,0.15);backdrop-filter:blur(8px);font-size:0.8rem">
            🏟️ 12+ Lapangan
          </div>
          <div style="display:flex;align-items:center;gap:8px;padding:8px 16px;border-radius:40px;background:rgba(255,255,255,0.15);backdrop-filter:blur(8px);font-size:0.8rem">
            ⭐ Rating 4.8
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- ===== AUTH PANEL ===== -->
  <div class="auth-panel">
    <div class="auth-box">
      <div class="auth-logo">
        <div class="navbar-logo-icon">SB</div>
        <span class="navbar-logo-text">SIPELOR <span>BEDAS</span></span>
      </div>

      <!-- Tabs -->
      <div class="auth-tabs">
        <div class="auth-tab active" data-tab="login">Masuk</div>
        <div class="auth-tab" data-tab="register">Daftar</div>
      </div>

      <!-- ===== LOGIN PANEL ===== -->
      <div class="auth-form-panel active" id="panel-login">
        <div class="auth-title">Selamat Datang! 👋</div>
        <div class="auth-subtitle">Masuk ke akun SIPELOR BEDAS Anda</div>

        <form id="login-form" novalidate>
          <div class="form-group">
            <label class="form-label" for="login-email">Email</label>
            <input type="email" id="login-email" class="form-control" placeholder="email@contoh.com" autocomplete="email" required>
          </div>

          <div class="form-group" style="position:relative">
            <label class="form-label" for="login-password">Password</label>
            <div style="position:relative">
              <input type="password" id="login-password" class="form-control" placeholder="Masukkan password" autocomplete="current-password" required style="padding-right:48px">
              <button type="button" class="toggle-password" style="position:absolute;right:14px;top:50%;transform:translateY(-50%);font-size:1rem;background:none;border:none;cursor:pointer;color:var(--color-text-muted)">👁️</button>
            </div>
          </div>

          <a href="#" class="forgot-link" onclick="handleForgotPassword(event)">Lupa password?</a>

          <button type="submit" id="login-btn" class="btn btn-primary btn-full btn-lg">Masuk</button>

          <div class="form-divider">
            <div class="form-divider-text">atau</div>
          </div>

          <div style="padding:16px;border-radius:var(--radius-md);background:rgba(70,143,234,0.1);border:1px solid rgba(70,143,234,0.2);font-size:0.8rem;color:var(--color-text-muted)">
            <span style="color:var(--color-secondary);font-weight:700">💡 Mode Demo</span><br>
            Email: <code style="background:rgba(255,255,255,0.1);padding:1px 6px;border-radius:4px;color:var(--color-text)">demo@sipelor.com</code><br>
            Password: <code style="background:rgba(255,255,255,0.1);padding:1px 6px;border-radius:4px;color:var(--color-text)">demo123</code>
          </div>
        </form>
      </div>

      <!-- ===== REGISTER PANEL ===== -->
      <div class="auth-form-panel" id="panel-register">
        <div class="auth-title">Buat Akun Baru</div>
        <div class="auth-subtitle">Daftar gratis dan mulai booking lapangan</div>

        <form id="register-form" novalidate>
          <div class="form-group">
            <label class="form-label" for="reg-name">Nama Lengkap</label>
            <input type="text" id="reg-name" class="form-control" placeholder="Nama lengkap Anda" autocomplete="name" required>
          </div>
          <div class="form-group">
            <label class="form-label" for="reg-email">Email</label>
            <input type="email" id="reg-email" class="form-control" placeholder="email@contoh.com" autocomplete="email" required>
          </div>
          <div class="form-group">
            <label class="form-label" for="reg-phone">No. HP / WhatsApp</label>
            <input type="tel" id="reg-phone" class="form-control" placeholder="08123456789" autocomplete="tel">
          </div>
          <div class="form-group">
            <label class="form-label" for="reg-password">Password</label>
            <div style="position:relative">
              <input type="password" id="reg-password" class="form-control" placeholder="Minimal 8 karakter" autocomplete="new-password" required style="padding-right:48px">
              <button type="button" class="toggle-password" style="position:absolute;right:14px;top:50%;transform:translateY(-50%);font-size:1rem;background:none;border:none;cursor:pointer;color:var(--color-text-muted)">👁️</button>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label" for="reg-confirm">Konfirmasi Password</label>
            <input type="password" id="reg-confirm" class="form-control" placeholder="Ulangi password" autocomplete="new-password" required>
          </div>
          <div class="checkbox-group mb-6">
            <input type="checkbox" id="reg-terms" required>
            <label for="reg-terms">
              Saya menyetujui <a href="#">Syarat & Ketentuan</a> dan <a href="#">Kebijakan Privasi</a> SIPELOR BEDAS
            </label>
          </div>
          <button type="submit" id="register-btn" class="btn btn-primary btn-full btn-lg">Daftar Sekarang</button>
        </form>
      </div>

      <div style="margin-top:24px;text-align:center">
        <a href="{{ route('home') }}" style="font-size:0.8rem;color:var(--color-text-dim);transition:color 0.2s" onmouseover="this.style.color='var(--color-text)'" onmouseout="this.style.color='var(--color-text-dim)'">
          ← Kembali ke Beranda
        </a>
      </div>
    </div>
  </div>
</div>

@endsection

@section('scripts')
<script src="{{ asset('js/auth.js') }}"></script>
<script>
  // Forgot password
  async function handleForgotPassword(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    if (!email) { showToast('Masukkan email Anda terlebih dahulu', 'error'); return; }
    if (!supabaseClient) { showToast('Mode demo: Fitur reset password membutuhkan Supabase', 'info'); return; }
    const { error } = await supabaseClient.auth.resetPasswordForEmail(email, {
      redirectTo: window.location.origin + '/reset-password',
    });
    if (error) { showToast(error.message, 'error'); }
    else { showToast('Link reset password telah dikirim ke email Anda! 📧', 'success'); }
  }

  // Auto-switch tab dari URL
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('tab') === 'register') {
    document.addEventListener('DOMContentLoaded', () => {
      document.querySelector('[data-tab="register"]')?.click();
    });
  }

  // Simpan redirect param
  const redirect = urlParams.get('redirect');
  if (redirect) localStorage.setItem('auth_redirect', redirect);
</script>
@endsection
