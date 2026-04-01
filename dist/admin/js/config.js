// =============================================
// SIPELOR BEDAS — Admin Dashboard Config
// =============================================

const SIPELOR_ADMIN_CONFIG = {
  SUPABASE_URL:      'https://gbhprmibbcqfwjgrkfzq.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiaHBybWliYmNxZndqZ3JrZnpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5MDgwNTcsImV4cCI6MjA4NDQ4NDA1N30.vMuV0A4NEC5IhA34TrVmJGBtB4UerOt2Dk8fe4uxwrY',
  APP_NAME:          'SIPELOR BEDAS',
  APP_VERSION:       '1.0.0',
  ITEMS_PER_PAGE:    10,
};

// ⚠️  CARA KONFIGURASI:
// 1. Login ke Supabase Dashboard → Project Settings → API
// 2. Copy "Project URL" → paste ke SUPABASE_URL
// 3. Copy "anon public" key → paste ke SUPABASE_ANON_KEY
//
// MEMBUAT ADMIN USER DI SUPABASE:
// Jalankan SQL di file: website/admin/sql/create_admin_user.sql
// (via Supabase Dashboard → SQL Editor)
//
// CATATAN KEAMANAN:
// - anon key aman untuk diekspos di browser
// - Pastikan RLS (Row Level Security) aktif di semua tabel
// - Jangan pernah expose service_role key di frontend
