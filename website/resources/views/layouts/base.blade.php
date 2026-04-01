<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="csrf-token" content="{{ csrf_token() }}">
  <title>@yield('title', 'SIPELOR BEDAS — Sistem Pemesanan Lapangan Olahraga')</title>
  <meta name="description" content="@yield('description', 'Pesan lapangan futsal, badminton, basket, dan voli di Kabupaten Sumedang secara online. Mudah, cepat, dan aman.')">
  <link rel="icon" type="image/png" href="https://picsum.photos/32/32?random=99">
  <link rel="stylesheet" href="{{ asset('css/style.css') }}">
  @yield('styles')
</head>
<body>

<div id="toast-container" class="toast-container"></div>

@yield('content')

{{-- ===== SCRIPTS ===== --}}
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js"></script>

{{-- Config: Supabase & App (dinjeksikan dari .env via PHP) --}}
<script>
const SIPELOR_CONFIG = {
  SUPABASE_URL:      '{{ config('supabase.url', '') }}',
  SUPABASE_ANON_KEY: '{{ config('supabase.anon_key', '') }}',
  APP_NAME:    '{{ config('app.name', 'SIPELOR BEDAS') }}',
  APP_VERSION: '1.0.0',
  PAYMENT: {
    BRI:    { bank: 'BRI',    account_number: '0895 8765 4321 001', account_name: 'SIPELOR BEDAS' },
    MANDIRI:{ bank: 'Mandiri',account_number: '1234 5678 9012 345', account_name: 'SIPELOR BEDAS' },
    BNI:    { bank: 'BNI',    account_number: '9876 5432 1098 765', account_name: 'SIPELOR BEDAS' },
    GOPAY:  { name: 'GoPay / OVO / DANA', number: '0812-3456-7890' },
  },
};
</script>

<script src="{{ asset('js/helpers.js') }}"></script>

@yield('scripts')
</body>
</html>
