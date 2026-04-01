@extends('layouts.base')

@section('title', 'SIPELOR BEDAS — Sistem Pemesanan Lapangan Olahraga Kabupaten Bandung')
@section('description', 'Pesan lapangan futsal, badminton, basket, dan voli di Kabupaten Bandung secara online. Mudah, cepat, dan aman.')

@section('content')

<!-- ===== NAVBAR ===== -->
<nav class="navbar" id="navbar">
  <div class="container navbar-inner">
    <a href="{{ route('home') }}" class="navbar-logo">
      <div class="navbar-logo-icon">SB</div>
      <span class="navbar-logo-text">SIPELOR <span>BEDAS</span></span>
    </a>

    <div class="navbar-nav">
      <a href="#sports" class="nav-link">Olahraga</a>
      <a href="#venues" class="nav-link">Lapangan</a>
      <a href="#cara-booking" class="nav-link">Cara Booking</a>
      <a href="#pembayaran" class="nav-link">Pembayaran</a>
      <a href="#tentang" class="nav-link">Tentang</a>
    </div>

    <div class="navbar-actions">
      <a href="{{ route('login') }}" class="btn btn-ghost btn-sm" id="nav-login-btn">Masuk</a>
      <a href="{{ route('booking') }}" class="btn btn-primary btn-sm">Booking Sekarang</a>
      <div id="nav-user-menu" style="display:none;align-items:center;gap:10px">
        <span style="font-size:0.8rem;color:var(--color-text-muted)">👤 <span id="nav-user-name"></span></span>
        <button class="btn btn-ghost btn-sm" onclick="handleLogout()">Keluar</button>
      </div>
    </div>

    <div class="navbar-mobile-toggle" id="mobile-toggle" onclick="toggleMobileMenu()">
      <span></span><span></span><span></span>
    </div>
  </div>
</nav>

<!-- Mobile Menu -->
<div class="mobile-menu" id="mobile-menu">
  <a href="#sports" class="nav-link" onclick="toggleMobileMenu()">Olahraga</a>
  <a href="#venues" class="nav-link" onclick="toggleMobileMenu()">Lapangan</a>
  <a href="#cara-booking" class="nav-link" onclick="toggleMobileMenu()">Cara Booking</a>
  <a href="#pembayaran" class="nav-link" onclick="toggleMobileMenu()">Pembayaran</a>
  <div class="mobile-menu-actions">
    <a href="{{ route('login') }}" class="btn btn-outline btn-full">Masuk</a>
    <a href="{{ route('booking') }}" class="btn btn-primary btn-full">Booking Sekarang</a>
  </div>
</div>

<!-- ===== HERO SECTION ===== -->
<section class="hero" id="home">
  <div class="hero-bg">
    <img
      src="https://images.pexels.com/photos/16378314/pexels-photo-16378314.jpeg?auto=compress&cs=tinysrgb&w=1920"
      alt="Futsal field - Laura Rincón on Pexels"
      loading="eager"
    >
    <div class="hero-bg-overlay"></div>
    <div class="hero-bg-grid"></div>
  </div>

  <div class="container hero-content">
    <div class="hero-badge">
      <span>Sistem Informasi Penyewaan Lapangan Olahraga</span>
    </div>

    <h1 class="hero-title">
      <span class="line1">SIPELOR</span>
      <span class="line2">BEDAS</span>
      <span class="line3">Kabupaten Bandung</span>
    </h1>

    <p class="hero-desc">
      Platform booking lapangan olahraga modern untuk Kabupaten Bandung.
      Pesan lapangan futsal, badminton, basket, dan voli — kapan saja, di mana saja.
    </p>

    <div class="hero-actions">
      <a href="{{ route('booking') }}" class="btn btn-primary btn-xl">⚡ Booking Sekarang</a>
      <a href="#cara-booking" class="btn btn-outline btn-lg">Cara Pesan</a>
    </div>

    <div class="hero-stats">
      <div class="hero-stat-item">
        <div class="hero-stat-num">12+</div>
        <div class="hero-stat-label">Lapangan</div>
      </div>
      <div class="hero-stat-item">
        <div class="hero-stat-num">4</div>
        <div class="hero-stat-label">Jenis Olahraga</div>
      </div>
      <div class="hero-stat-item">
        <div class="hero-stat-num">2.4K+</div>
        <div class="hero-stat-label">Booking/Bulan</div>
      </div>
      <div class="hero-stat-item">
        <div class="hero-stat-num">4.8⭐</div>
        <div class="hero-stat-label">Rating</div>
      </div>
    </div>
  </div>

  <div class="hero-scroll-hint">
    <div class="hero-scroll-arrow"></div>
    <span>Scroll</span>
  </div>
</section>

<!-- ===== STATS BAR ===== -->
<div class="stats-bar">
  <div class="container stats-bar-inner">
    <div class="stat-item">
      <div class="stat-icon">⚽</div>
      <div>
        <div class="stat-number">3 Lapangan</div>
        <div class="stat-text">Futsal Tersedia</div>
      </div>
    </div>
    <div class="stat-divider"></div>
    <div class="stat-item">
      <div class="stat-icon blue">🏸</div>
      <div>
        <div class="stat-number">4 Lapangan</div>
        <div class="stat-text">Badminton Tersedia</div>
      </div>
    </div>
    <div class="stat-divider"></div>
    <div class="stat-item">
      <div class="stat-icon">🏀</div>
      <div>
        <div class="stat-number">2 Lapangan</div>
        <div class="stat-text">Basketball Tersedia</div>
      </div>
    </div>
    <div class="stat-divider"></div>
    <div class="stat-item">
      <div class="stat-icon blue">🏐</div>
      <div>
        <div class="stat-number">3 Lapangan</div>
        <div class="stat-text">Voli Tersedia</div>
      </div>
    </div>
    <div class="stat-divider"></div>
    <div class="stat-item">
      <div class="stat-icon">💳</div>
      <div>
        <div class="stat-number">QRIS + Bank</div>
        <div class="stat-text">Metode Pembayaran</div>
      </div>
    </div>
  </div>
</div>

<!-- ===== SPORTS SECTION ===== -->
<section class="section" id="sports">
  <div class="container">
    <div class="text-center mb-8">
      <div class="section-label" style="margin:0 auto 20px">🏆 Jenis Olahraga</div>
      <h2 class="text-display-md">Pilih <span class="text-primary">Olahraga</span> Favoritmu</h2>
      <p class="text-muted mt-4" style="max-width:520px;margin-left:auto;margin-right:auto">
        Tersedia berbagai jenis lapangan olahraga dengan fasilitas lengkap dan berkualitas.
      </p>
    </div>

    <div class="sports-grid">
      <div class="sport-card" onclick="window.location.href='{{ route('booking') }}?sport=futsal'">
        <img src="https://images.pexels.com/photos/16378321/pexels-photo-16378321.jpeg?auto=compress&cs=tinysrgb&w=500" alt="Futsal - Laura Rincón on Pexels" class="sport-card-img">
        <div class="sport-card-gradient"></div>
        <div class="sport-card-overlay"></div>
        <span class="sport-card-badge">3 Lapangan</span>
        <div class="sport-card-content">
          <span class="sport-card-icon">⚽</span>
          <span class="sport-card-name">Futsal</span>
          <span class="sport-card-count">Mulai Rp 150.000/jam</span>
        </div>
      </div>

      <div class="sport-card" onclick="window.location.href='{{ route('booking') }}?sport=badminton'">
        <img src="https://images.pexels.com/photos/26238653/pexels-photo-26238653.jpeg?auto=compress&cs=tinysrgb&w=500" alt="Badminton - Ben Cheers on Pexels" class="sport-card-img">
        <div class="sport-card-gradient"></div>
        <div class="sport-card-overlay"></div>
        <span class="sport-card-badge">4 Lapangan</span>
        <div class="sport-card-content">
          <span class="sport-card-icon">🏸</span>
          <span class="sport-card-name">Badminton</span>
          <span class="sport-card-count">Mulai Rp 80.000/jam</span>
        </div>
      </div>

      <div class="sport-card" onclick="window.location.href='{{ route('booking') }}?sport=basketball'">
        <img src="https://images.unsplash.com/photo-1503198129995-3f110c24aaa0?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=500" alt="Basketball - Lance Asper on Unsplash" class="sport-card-img">
        <div class="sport-card-gradient"></div>
        <div class="sport-card-overlay"></div>
        <span class="sport-card-badge">2 Lapangan</span>
        <div class="sport-card-content">
          <span class="sport-card-icon">🏀</span>
          <span class="sport-card-name">Basketball</span>
          <span class="sport-card-count">Mulai Rp 200.000/jam</span>
        </div>
      </div>

      <div class="sport-card" onclick="window.location.href='{{ route('booking') }}?sport=volleyball'">
        <img src="https://images.pexels.com/photos/8007171/pexels-photo-8007171.jpeg?auto=compress&cs=tinysrgb&w=500" alt="Voli - SHVETS production on Pexels" class="sport-card-img">
        <div class="sport-card-gradient"></div>
        <div class="sport-card-overlay"></div>
        <span class="sport-card-badge">3 Lapangan</span>
        <div class="sport-card-content">
          <span class="sport-card-icon">🏐</span>
          <span class="sport-card-name">Voli</span>
          <span class="sport-card-count">Mulai Rp 100.000/jam</span>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ===== FEATURED VENUES ===== -->
<section class="section" id="venues" style="background:var(--color-surface)">
  <div class="container">
    <div class="flex items-center justify-between mb-8" style="flex-wrap:wrap;gap:16px">
      <div>
        <div class="section-label">🏟️ Lapangan Pilihan</div>
        <h2 class="text-display-md">Lapangan <span class="text-primary">Terbaik</span></h2>
      </div>
      <a href="{{ route('booking') }}" class="btn btn-outline">Lihat Semua →</a>
    </div>

    <div class="grid-5" id="venues-grid">
      @php
        $venues = [
          ['img'=>'https://images.pexels.com/photos/16378314/pexels-photo-16378314.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Futsal A - Laura Rincón on Pexels','type'=>'Futsal','title'=>'Lapangan Futsal A','loc'=>'Jl. Prabu Gajah Agung No. 3','price'=>'150K','rating'=>'4.8','reviews'=>'124','status'=>'','pills'=>['🔒 CCTV','🚗 Parkir','🚿 Ruang Ganti']],
          ['img'=>'https://images.pexels.com/photos/26238656/pexels-photo-26238656.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Badminton B - Ben Cheers on Pexels','type'=>'Badminton','title'=>'Lapangan Badminton B','loc'=>'Jl. Mayor Abdurakhman No. 12','price'=>'80K','rating'=>'4.6','reviews'=>'89','status'=>'','pills'=>['🔒 CCTV','🚗 Parkir','🕌 Mushola']],
          ['img'=>'https://images.unsplash.com/photo-1555980414-8317bbc6b54b?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=400','alt'=>'Basketball C - Kiril Dobrev on Unsplash','type'=>'Basketball','title'=>'Lapangan Basketball C','loc'=>'Komplek GOR Kabupaten Bandung','price'=>'200K','rating'=>'4.9','reviews'=>'56','status'=>'','pills'=>['🔒 CCTV','🚗 Parkir','🪑 Ruang Tunggu']],
          ['img'=>'https://images.pexels.com/photos/6203529/pexels-photo-6203529.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Voli D - Pavel Danilyuk on Pexels','type'=>'Voli','title'=>'Lapangan Voli D','loc'=>'Jl. Pangeran Kornel No. 45','price'=>'100K','rating'=>'4.7','reviews'=>'73','status'=>'','pills'=>['🔒 CCTV','🚗 Parkir','🕌 Mushola']],
          ['img'=>'https://images.pexels.com/photos/16378313/pexels-photo-16378313.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Futsal B - Laura Rincón on Pexels','type'=>'Futsal','title'=>'Lapangan Futsal B','loc'=>'Jl. Suryakancana No. 8','price'=>'120K','rating'=>'4.5','reviews'=>'98','status'=>'booked','pills'=>['🔒 CCTV','📶 WiFi','🚗 Parkir']],
          ['img'=>'https://images.pexels.com/photos/26238671/pexels-photo-26238671.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Badminton C - Ben Cheers on Pexels','type'=>'Badminton','title'=>'Lapangan Badminton C','loc'=>'Jl. Siliwangi No. 17','price'=>'75K','rating'=>'4.5','reviews'=>'61','status'=>'','pills'=>['🔒 CCTV','🚗 Parkir','🚿 Ruang Ganti']],
          ['img'=>'https://images.unsplash.com/photo-1552741775-7817c0c85843?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=400','alt'=>'Futsal C - David Libeert on Unsplash','type'=>'Futsal','title'=>'Lapangan Futsal C','loc'=>'Jl. Ibrahim Adjie No. 5','price'=>'160K','rating'=>'4.7','reviews'=>'44','status'=>'','pills'=>['🔒 CCTV','🕌 Mushola','🚗 Parkir']],
          ['img'=>'https://images.unsplash.com/photo-1525973132219-a04334a76080?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=400','alt'=>'Basketball D - Edgar Chaparro on Unsplash','type'=>'Basketball','title'=>'Lapangan Basketball D','loc'=>'Jl. Ahmad Yani No. 21','price'=>'180K','rating'=>'4.8','reviews'=>'37','status'=>'','pills'=>['🔒 CCTV','🚗 Parkir','🪑 Tribun']],
          ['img'=>'https://images.pexels.com/photos/8007500/pexels-photo-8007500.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Badminton E - SHVETS production on Pexels','type'=>'Badminton','title'=>'Lapangan Badminton E','loc'=>'Jl. Otista No. 33','price'=>'90K','rating'=>'4.4','reviews'=>'52','status'=>'booked','pills'=>['🔒 CCTV','🚗 Parkir','📶 WiFi']],
          ['img'=>'https://images.pexels.com/photos/6203531/pexels-photo-6203531.jpeg?auto=compress&cs=tinysrgb&w=400','alt'=>'Voli F - Pavel Danilyuk on Pexels','type'=>'Voli','title'=>'Lapangan Voli F','loc'=>'Jl. Veteran No. 10','price'=>'110K','rating'=>'4.6','reviews'=>'41','status'=>'','pills'=>['🔒 CCTV','🕌 Mushola','🚗 Parkir']],
        ];
      @endphp

      @foreach($venues as $v)
      <div class="venue-card">
        <div class="venue-card-img-wrap">
          <img src="{{ $v['img'] }}" alt="{{ $v['alt'] }}" class="venue-card-img">
          <span class="venue-card-type">{{ $v['type'] }}</span>
          <span class="venue-card-status {{ $v['status'] }}"></span>
        </div>
        <div class="venue-card-body">
          <div class="venue-card-title">{{ $v['title'] }}</div>
          <div class="venue-card-location">📍 {{ $v['loc'] }}</div>
          <div class="venue-card-features">
            @foreach($v['pills'] as $pill)
              <span class="feature-pill">{{ $pill }}</span>
            @endforeach
          </div>
          <div class="venue-card-footer">
            <div class="venue-card-price">
              <span class="venue-card-price-amount">{{ $v['price'] }}</span>
              <span class="venue-card-price-unit">per jam</span>
            </div>
            <div class="venue-card-rating">⭐ {{ $v['rating'] }} <span style="color:var(--color-text-dim);font-weight:400">({{ $v['reviews'] }})</span></div>
          </div>
        </div>
      </div>
      @endforeach
    </div>
  </div>
</section>

<!-- ===== HOW IT WORKS ===== -->
<section class="section" id="cara-booking">
  <div class="container">
    <div class="text-center mb-8">
      <div class="section-label" style="margin:0 auto 20px">📋 Cara Booking</div>
      <h2 class="text-display-md">Pesan Lapangan dalam <span class="text-primary">3 Langkah</span></h2>
      <p class="text-muted mt-4" style="max-width:480px;margin:16px auto 0">
        Proses booking yang simpel dan cepat. Tidak perlu antri — cukup dari HP kamu!
      </p>
    </div>

    <div class="steps-row">
      <div class="step-item">
        <div class="step-number s1">1</div>
        <div class="step-title">Pilih Lapangan</div>
        <p class="step-desc">Pilih jenis olahraga, lapangan, dan tanggal yang kamu inginkan dari daftar yang tersedia.</p>
      </div>
      <div class="step-item">
        <div class="step-number s2">2</div>
        <div class="step-title">Konfirmasi Booking</div>
        <p class="step-desc">Tentukan jam mulai dan durasi. Review detail booking dan konfirmasi pesananmu.</p>
      </div>
      <div class="step-item">
        <div class="step-number s3">3</div>
        <div class="step-title">Bayar & Main!</div>
        <p class="step-desc">Bayar via QRIS atau transfer bank. Upload bukti bayar dan lapangan siap dipakai!</p>
      </div>
    </div>

    <div class="text-center mt-8">
      <a href="{{ route('booking') }}" class="btn btn-primary btn-xl">Mulai Booking Sekarang ⚡</a>
    </div>
  </div>
</section>

<!-- ===== PAYMENT SECTION ===== -->
<section class="section payment-section" id="pembayaran">
  <div class="container">
    <div class="payment-grid">
      <div>
        <div class="section-label blue">💳 Pembayaran</div>
        <h2 class="text-display-md mb-6">Bayar dengan <span class="text-secondary">Mudah & Aman</span></h2>
        <p class="text-muted mb-8">
          Berbagai metode pembayaran digital tersedia. Scan QR Code QRIS, transfer bank, atau dompet digital.
          Bukti bayar diverifikasi admin dalam 1×24 jam.
        </p>
        <div class="payment-features">
          <div class="payment-feature-item">
            <div class="payment-feature-icon orange">📱</div>
            <div>
              <div class="payment-feature-title">QR Code QRIS</div>
              <div class="payment-feature-desc">Scan QR dengan aplikasi m-banking atau dompet digital (GoPay, OVO, DANA, dll)</div>
            </div>
          </div>
          <div class="payment-feature-item">
            <div class="payment-feature-icon blue">🏦</div>
            <div>
              <div class="payment-feature-title">Transfer Bank</div>
              <div class="payment-feature-desc">BRI, Mandiri, BNI, BCA — transfer ke rekening resmi SIPELOR BEDAS</div>
            </div>
          </div>
          <div class="payment-feature-item">
            <div class="payment-feature-icon green">✅</div>
            <div>
              <div class="payment-feature-title">Verifikasi Cepat</div>
              <div class="payment-feature-desc">Upload bukti bayar dan admin akan mengkonfirmasi booking dalam 1×24 jam</div>
            </div>
          </div>
        </div>
      </div>

      <div class="payment-visual">
        <div class="payment-mockup">
          <div class="payment-mockup-header">
            <div class="payment-mockup-logo">SIPELOR BEDAS</div>
            <div class="payment-mockup-subtitle">Pembayaran Booking Lapangan</div>
          </div>
          <div class="qr-box">
            <div class="qr-placeholder">
              <img
                src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=SIPELOR-BEDAS-DEMO-QRIS-2024&bgcolor=ffffff&color=000000"
                alt="QR Code Demo"
                style="width:180px;height:180px"
                onerror="this.parentElement.innerHTML='<div style=\'text-align:center;padding:20px;color:#333\'><div style=\'font-size:3rem\'>📱</div><div style=\'font-size:0.75rem;margin-top:8px\'>QR CODE</div></div>'"
              >
            </div>
          </div>
          <div class="payment-mockup-amount">
            <div class="amount-label">Total Pembayaran</div>
            <div class="amount-value">Rp 150.000</div>
            <div class="amount-venue">Lapangan Futsal A · 1 Jam</div>
          </div>
          <div class="payment-timer">
            ⏱️ Berlaku selama <strong style="margin-left:4px">14:58</strong>
          </div>
          <div class="bank-options">
            <div class="bank-badge">BRI</div>
            <div class="bank-badge">Mandiri</div>
            <div class="bank-badge">BNI</div>
            <div class="bank-badge">GoPay</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ===== TESTIMONIALS ===== -->
<section class="section" id="tentang">
  <div class="container">
    <div class="text-center mb-8">
      <div class="section-label" style="margin:0 auto 20px">💬 Testimoni</div>
      <h2 class="text-display-md">Apa Kata <span class="text-primary">Pengguna</span> Kami</h2>
    </div>
    <div class="testimonials-grid">
      <div class="testimonial-featured">
        <div class="testimonial-stars">⭐⭐⭐⭐⭐</div>
        <p class="testimonial-text">
          "SIPELOR BEDAS benar-benar mengubah cara kami booking lapangan. Dulu harus telepon dulu atau datang langsung,
          sekarang cukup buka website, pilih lapangan, bayar QR, selesai! Super mudah dan prosesnya cepat banget.
          Tim admin juga responsif dalam verifikasi pembayaran."
        </p>
        <div class="testimonial-author">
          <img src="https://i.pravatar.cc/44?u=budi-santoso" alt="Budi Santoso" class="testimonial-avatar">
          <div>
            <div class="testimonial-name">Budi Santoso</div>
            <div class="testimonial-role">Ketua Tim Futsal RT 05, Kabupaten Bandung</div>
          </div>
        </div>
      </div>
      <div class="testimonial-card">
        <div class="testimonial-stars">⭐⭐⭐⭐⭐</div>
        <p class="testimonial-text">"Lapangan badmintonnya bersih dan terawat. Booking online via SIPELOR sangat membantu, nggak perlu khawatir lapangan udah dipakai orang lain."</p>
        <div class="testimonial-author">
          <img src="https://i.pravatar.cc/44?u=sari-dewi" alt="Sari Dewi" class="testimonial-avatar">
          <div>
            <div class="testimonial-name">Sari Dewi</div>
            <div class="testimonial-role">Pegawai Swasta, Kabupaten Bandung</div>
          </div>
        </div>
      </div>
      <div class="testimonial-card">
        <div class="testimonial-stars">⭐⭐⭐⭐⭐</div>
        <p class="testimonial-text">"Sangat membantu untuk event sekolah. QR Code pembayarannya canggih dan praktis. Admin verifikasi cepat, dalam hitungan jam langsung dikonfirmasi!"</p>
        <div class="testimonial-author">
          <img src="https://i.pravatar.cc/44?u=pak-guru-ahmad" alt="Ahmad Fauzi" class="testimonial-avatar">
          <div>
            <div class="testimonial-name">Ahmad Fauzi, S.Pd</div>
            <div class="testimonial-role">Guru Olahraga SMP N 1 Kabupaten Bandung</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ===== CTA SECTION ===== -->
<section class="cta-section">
  <div class="cta-bg"></div>
  <div class="cta-orb-1"></div>
  <div class="cta-orb-2"></div>
  <div class="container cta-content">
    <div class="section-label" style="margin:0 auto 24px">🚀 Mulai Sekarang</div>
    <h2 class="text-display-lg mb-6">Siap untuk <span class="text-primary">Bermain?</span></h2>
    <p class="text-muted mb-8" style="max-width:480px;margin-left:auto;margin-right:auto;font-size:1.1rem">
      Daftarkan diri dan nikmati kemudahan booking lapangan olahraga di Kabupaten Bandung. Gratis, mudah, dan cepat!
    </p>
    <div class="flex justify-center gap-4" style="flex-wrap:wrap">
      <a href="{{ route('login') }}?tab=register" class="btn btn-primary btn-xl">Daftar Gratis 🎉</a>
      <a href="{{ route('booking') }}" class="btn btn-outline btn-xl">Lihat Lapangan</a>
    </div>
  </div>
</section>

<!-- ===== FOOTER ===== -->
<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <a href="{{ route('home') }}" class="navbar-logo">
          <div class="navbar-logo-icon">SB</div>
          <span class="navbar-logo-text">SIPELOR <span>BEDAS</span></span>
        </a>
        <p class="footer-brand-desc">
          Sistem Informasi Pemesanan Lapangan Olahraga Berbasis Digital untuk Kabupaten Bandung.
          Dari Dinas Pemuda dan Olahraga Kabupaten Bandung.
        </p>
        <div class="footer-social">
          <a href="#" class="footer-social-btn" title="Instagram">📸</a>
          <a href="#" class="footer-social-btn" title="Facebook">📘</a>
          <a href="#" class="footer-social-btn" title="WhatsApp">📱</a>
          <a href="#" class="footer-social-btn" title="YouTube">📺</a>
        </div>
      </div>
      <div>
        <div class="footer-col-title">Layanan</div>
        <div class="footer-links">
          <a href="{{ route('booking') }}" class="footer-link">Booking Lapangan</a>
          <a href="#sports" class="footer-link">Jenis Olahraga</a>
          <a href="#venues" class="footer-link">Daftar Lapangan</a>
          <a href="#pembayaran" class="footer-link">Cara Pembayaran</a>
        </div>
      </div>
      <div>
        <div class="footer-col-title">Informasi</div>
        <div class="footer-links">
          <a href="#tentang" class="footer-link">Tentang SIPELOR</a>
          <a href="#cara-booking" class="footer-link">Cara Booking</a>
          <a href="#" class="footer-link">FAQ</a>
          <a href="#" class="footer-link">Kontak Kami</a>
        </div>
      </div>
      <div>
        <div class="footer-col-title">Kontak</div>
        <div class="footer-links">
          <span class="footer-link">📍 Jl. Prabu Gajah Agung No. 3, Kabupaten Bandung</span>
          <span class="footer-link">📞 (0261) 123-4567</span>
          <span class="footer-link">📧 sipelor@bandungkab.go.id</span>
          <span class="footer-link">🕐 Buka 06:00 – 22:00 WIB</span>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="footer-bottom-text">© {{ date('Y') }} SIPELOR BEDAS — Dinas Pemuda dan Olahraga Kabupaten Bandung.</div>
      <div class="footer-bottom-text">
        <a href="#" style="color:inherit;margin-right:16px">Kebijakan Privasi</a>
        <a href="#" style="color:inherit">Syarat & Ketentuan</a>
      </div>
    </div>
  </div>
</footer>

@endsection

@section('scripts')
<script src="{{ asset('js/auth.js') }}"></script>
<script>
  // Navbar scroll effect
  const navbar = document.getElementById('navbar');
  window.addEventListener('scroll', () => { navbar.classList.toggle('scrolled', window.scrollY > 20); });
  if (window.scrollY > 20) navbar.classList.add('scrolled');

  // Mobile menu
  function toggleMobileMenu() {
    document.getElementById('mobile-menu').classList.toggle('open');
  }
  document.addEventListener('click', (e) => {
    const menu = document.getElementById('mobile-menu');
    const toggle = document.getElementById('mobile-toggle');
    if (menu && toggle && !menu.contains(e.target) && !toggle.contains(e.target)) {
      menu.classList.remove('open');
    }
  });

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', e => {
      const id = a.getAttribute('href');
      const el = document.querySelector(id);
      if (el) { e.preventDefault(); el.scrollIntoView({ behavior: 'smooth', block: 'start' }); }
    });
  });

  // Auth check
  document.addEventListener('DOMContentLoaded', async () => {
    await updateNavbarAuth();
  });

  // Scroll animations
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
      }
    });
  }, { threshold: 0.1 });

  document.querySelectorAll('.venue-card, .sport-card, .step-item, .payment-feature-item, .testimonial-card').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    observer.observe(el);
  });
</script>
@endsection
