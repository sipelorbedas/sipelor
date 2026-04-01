# 🔧 OAuth Redirect Setup - Custom Mobile-Optimized Page

## 📋 Masalah

Halaman intermediate redirect dari Supabase setelah OAuth **tidak full width** di mobile device karena:
- Default Supabase redirect page tidak memiliki viewport meta tag yang tepat
- Tampilan desktop-like di mobile device
- User experience buruk

## ✅ Solusi: Custom Redirect Page

Membuat custom redirect HTML page yang:
- ✅ Full width & responsive
- ✅ Mobile-optimized dengan proper viewport
- ✅ Langsung trigger deep link
- ✅ Auto-close setelah redirect

---

## 🚀 Setup Instructions

### Step 1: Host Redirect Page

File `web/auth-callback.html` sudah dibuat. Anda perlu host file ini di salah satu platform berikut:

#### Option A: GitHub Pages (FREE & RECOMMENDED)

1. **Create GitHub Repository**
   ```bash
   # Buat repo baru bernama "sipelor-oauth"
   ```

2. **Upload File**
   ```bash
   git init
   git add web/auth-callback.html
   git commit -m "Add OAuth callback page"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/sipelor-oauth.git
   git push -u origin main
   ```

3. **Enable GitHub Pages**
   - Buka repo di GitHub
   - Settings → Pages
   - Source: `main` branch, `/web` folder
   - Save

4. **Get URL**
   - URL akan jadi: `https://YOUR_USERNAME.github.io/sipelor-oauth/auth-callback.html`

#### Option B: Vercel (FREE)

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   cd web
   vercel --prod
   ```

3. **Note URL** yang diberikan (contoh: `https://sipelor-oauth.vercel.app/auth-callback.html`)

#### Option C: Netlify (FREE)

1. **Install Netlify CLI**
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy**
   ```bash
   cd web
   netlify deploy --prod
   ```

3. **Note URL** yang diberikan

#### Option D: Firebase Hosting (FREE)

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize**
   ```bash
   firebase init hosting
   # Pilih web/ sebagai public directory
   ```

3. **Deploy**
   ```bash
   firebase deploy --only hosting
   ```

4. **Get URL** dari console

---

### Step 2: Configure Supabase Dashboard

1. **Login ke Supabase Dashboard**
   - Buka https://app.supabase.com
   - Pilih project SIPELOR BEDAS

2. **Update Redirect URLs**
   - Authentication → URL Configuration
   - Tambahkan redirect URL baru:
     ```
     https://YOUR_DOMAIN/auth-callback.html
     ```
   - Contoh:
     ```
     https://yourusername.github.io/sipelor-oauth/auth-callback.html
     ```

3. **Keep Deep Link URL**
   - Pastikan ini juga ada di list:
     ```
     io.supabase.sipelor://login-callback/
     ```

4. **Save Changes**

---

### Step 3: Update Flutter Code

**File:** `lib/services/social_auth_service.dart`

Update fungsi `_getOAuthRedirectUrl()`:

```dart
static String _getOAuthRedirectUrl() {
  // PRODUCTION: Use custom mobile-optimized redirect page
  // This page has proper viewport and immediately triggers deep link
  const productionRedirectUrl = 'https://YOUR_DOMAIN/auth-callback.html';
  
  if (kDebugMode) {
    // Development: You can use same URL or localhost if testing web
    return productionRedirectUrl;
  } else {
    // Production: Always use custom redirect page
    return productionRedirectUrl;
  }
}
```

**Replace** `YOUR_DOMAIN` dengan URL actual dari Step 1.

Contoh:
```dart
const productionRedirectUrl = 
    'https://yourusername.github.io/sipelor-oauth/auth-callback.html';
```

---

### Step 4: Remove skip_http_redirect (Not Needed)

Since we're using custom redirect page, remove the `queryParams`:

**File:** `lib/services/social_auth_service.dart`

```dart
final response = await _client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: _getOAuthRedirectUrl(),
  authScreenLaunchMode: kIsWeb 
      ? LaunchMode.platformDefault 
      : LaunchMode.externalApplication,
  // Remove queryParams - not needed with custom page
);
```

---

### Step 5: Test

1. **Rebuild App**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test OAuth Flow**
   - Klik "Sign In With Gmail"
   - Browser terbuka → Pilih email → Klik "Lanjutkan"
   - **Expected:** Custom page muncul (full width, mobile-optimized)
   - **Expected:** Langsung redirect ke app dalam 1-2 detik
   - **Expected:** Browser auto-close
   - Login berhasil ✅

---

## 📊 How It Works

### Before (Problem):
```
[Google OAuth]
    ↓
[Supabase Default Redirect Page] ← NOT FULL WIDTH ❌
    ↓
[Deep Link]
    ↓
[App]
```

### After (Solution):
```
[Google OAuth]
    ↓
[Custom Mobile-Optimized Page] ← FULL WIDTH ✅
    ↓ (Immediate)
[Deep Link Triggered]
    ↓
[App Opens]
```

---

## 🎨 Custom Page Features

File `web/auth-callback.html` memiliki:

### Mobile Optimization
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, 
                               maximum-scale=1.0, user-scalable=no">
```

### Proper Sizing
```css
html, body {
    width: 100%;
    height: 100%;
}

.container {
    width: 100%;
    max-width: 100%;
    padding: 0 16px;
}
```

### Responsive Text
```css
h1 {
    font-size: clamp(20px, 5vw, 24px);
}

p {
    font-size: clamp(14px, 4vw, 16px);
}
```

### Multiple Deep Link Methods
```javascript
// Method 1: Direct assignment
window.location.href = deepLink;

// Method 2: Invisible link click
link.click();

// Method 3: iframe approach
iframe.src = deepLink;
```

### Auto-Close
```javascript
// Close after 3 seconds if still open
setTimeout(() => {
    window.close();
}, 3000);
```

---

## 🧪 Verification Checklist

After setup, verify:

- [ ] Custom redirect URL hosted and accessible
- [ ] Supabase Dashboard has correct redirect URL
- [ ] Flutter code updated with correct URL
- [ ] App rebuilt and deployed
- [ ] OAuth flow tested on real device
- [ ] Custom page shows full width
- [ ] Deep link triggers correctly
- [ ] Browser closes automatically
- [ ] Login successful

---

## 🔍 Troubleshooting

### Issue: Custom page not loading

**Check:**
- URL correct di Supabase Dashboard
- URL correct di Flutter code
- File hosted dan accessible (test di browser)
- HTTPS enabled (required untuk OAuth)

**Fix:**
```bash
# Test URL di browser mobile
curl -I https://YOUR_DOMAIN/auth-callback.html

# Should return 200 OK
```

### Issue: Deep link not triggered

**Check:**
- AndroidManifest.xml has correct intent filter
- Deep link scheme matches: `io.supabase.sipelor://login-callback/`
- Check browser console for errors

**Fix:**
```bash
# Test deep link manually
adb shell am start -a android.intent.action.VIEW \
  -d "io.supabase.sipelor://login-callback/"
```

### Issue: Page still not full width

**Check:**
- File `web/auth-callback.html` uploaded correctly
- No caching issues (force refresh: Ctrl+Shift+R)
- Viewport meta tag present

**Fix:**
```bash
# Clear cache and test
# Or add cache-busting: ?v=2 to URL
```

### Issue: Browser doesn't close

**Normal behavior:**
- Beberapa browser tidak allow auto-close for security
- User bisa manually close atau switch back to app
- Page akan attempt close after 3 seconds

---

## 📱 Platform-Specific Notes

### Android
- ✅ Works with Chrome, Firefox, Samsung Internet
- Deep link might show "Open with SIPELOR BEDAS" dialog (normal)
- Browser might not auto-close (user can close manually)

### iOS
- ✅ Works with Safari, Chrome
- Universal Links would be better (future enhancement)
- Browser usually auto-closes well

### Web
- Not applicable (OAuth happens in same browser)
- Use `LaunchMode.platformDefault` for web

---

## 🚀 Advanced: Universal Links (Future)

For best UX, consider implementing Universal Links (iOS) / App Links (Android):

**Benefits:**
- No intermediate page at all
- Direct app opening
- Better security
- Seamless experience

**Setup:** (Future enhancement)
- Configure Apple App Site Association
- Configure Android assetlinks.json
- Update deep link handling

See: https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app

---

## 📝 Summary

**Files Created:**
- ✅ `web/auth-callback.html` - Mobile-optimized redirect page

**Files Modified:**
- ✅ `lib/services/social_auth_service.dart` - Update redirect URL

**External Setup Required:**
1. Host `auth-callback.html` (GitHub Pages/Vercel/Netlify)
2. Update Supabase Dashboard redirect URLs
3. Update Flutter code with hosted URL
4. Rebuild and test

**Expected Result:**
- ✅ Full width redirect page
- ✅ Mobile-optimized viewport
- ✅ Smooth OAuth flow
- ✅ Auto deep link trigger
- ✅ Browser auto-close
- ✅ Successful login

---

**Need Help?**
- GitHub Pages tutorial: https://pages.github.com/
- Vercel deployment: https://vercel.com/docs
- Supabase OAuth: https://supabase.com/docs/guides/auth/social-login

---

**Status:** Ready to Deploy 🚀  
**Created:** 5 Februari 2026  
**Last Updated:** 5 Februari 2026
