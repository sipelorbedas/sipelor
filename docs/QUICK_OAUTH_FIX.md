# ⚡ Quick Fix: OAuth Redirect Not Full Width

## 🎯 Masalah
Halaman redirect setelah login Gmail **tidak full width** di mobile.

## ✅ Solusi Cepat (5 Menit)

### Step 1: Host Redirect Page di GitHub Pages

1. **Buat repo GitHub baru**
   - Nama: `sipelor-oauth` (atau apapun)
   - Public repository

2. **Upload file**
   - Copy file `web/auth-callback.html` dari project
   - Commit ke repo

3. **Enable GitHub Pages**
   - Settings → Pages
   - Source: `main` branch
   - Folder: `/` (root)
   - Save

4. **Dapatkan URL**
   - Contoh: `https://username.github.io/sipelor-oauth/auth-callback.html`

### Step 2: Update Supabase

1. Login ke https://app.supabase.com
2. Pilih project → Authentication → URL Configuration
3. Tambahkan redirect URL:
   ```
   https://username.github.io/sipelor-oauth/auth-callback.html
   ```
   (ganti `username` dengan GitHub username Anda)

### Step 3: Update Code

**File:** `lib/services/social_auth_service.dart`

Cari fungsi `_getOAuthRedirectUrl()` dan update:

```dart
static String _getOAuthRedirectUrl() {
  // Ganti dengan URL GitHub Pages Anda
  return 'https://username.github.io/sipelor-oauth/auth-callback.html';
}
```

**Hapus** `queryParams` dari `signInWithOAuth`:

```dart
// BEFORE (hapus ini):
queryParams: {
  'skip_http_redirect': 'true',
},

// AFTER: (tidak ada queryParams)
final response = await _client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: _getOAuthRedirectUrl(),
  authScreenLaunchMode: kIsWeb 
      ? LaunchMode.platformDefault 
      : LaunchMode.externalApplication,
);
```

### Step 4: Test

```powershell
flutter clean
flutter pub get  
flutter run
```

Test login Gmail → Halaman redirect sekarang **FULL WIDTH** ✅

---

## 🔗 Alternatif Hosting

Jika tidak mau pakai GitHub Pages, bisa pakai:

### Vercel (1 menit)
```bash
cd web
npx vercel --prod
```

### Netlify Drop
1. Buka https://app.netlify.com/drop
2. Drag & drop file `auth-callback.html`
3. Copy URL yang diberikan

---

## ✅ Hasil

**Sebelum:**
- ❌ Redirect page tidak full width
- ❌ Viewport tidak responsive

**Sesudah:**
- ✅ Custom redirect page full width
- ✅ Mobile-optimized viewport
- ✅ Auto deep link trigger
- ✅ Smooth experience

---

## 📄 File Locations

- Custom redirect page: `web/auth-callback.html`
- Setup guide lengkap: `docs/OAUTH_REDIRECT_SETUP.md`
- Code to update: `lib/services/social_auth_service.dart`

---

**Waktu setup: ~5 menit**  
**Status: Production-ready** ✨
