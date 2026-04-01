# 🔐 Quick Start: GitHub Secrets Configuration

> **Fast setup guide untuk configure GitHub Secrets dalam 15 menit**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026

---

## 🎯 Goal

Setup GitHub Secrets agar CI/CD pipeline bisa build dan deploy aplikasi secara otomatis.

---

## 📋 What You Need

Prepare these before starting:

1. ✅ GitHub repository admin access
2. ✅ Supabase credentials (dev & prod)
3. ✅ Android keystore file (`android/app/keystore.jks`)
4. ✅ Keystore passwords (from `android/key.properties`)
5. ✅ Sentry DSN (from sentry.io)
6. ⚪ Google Play service account JSON (optional)
7. ⚪ Slack webhook URL (optional)

---

## ⚡ Quick Setup (15 Minutes)

### Step 1: Access GitHub Secrets (1 min)

**⚠️ IMPORTANT: Ini adalah REPOSITORY Settings, bukan Personal Account Settings!**

1. Go to your repository: `https://github.com/your-org/sipelor-bedas`
2. Click **Settings** tab (di bagian atas repository, sejajar dengan Code, Issues, Pull requests)
3. Scroll sidebar kiri ke bawah, section **"Security"**
4. Click **Secrets and variables** → **Actions**
5. Keep this page open

**Path lengkap:**
```
Repository Page → Settings (⚙️ tab atas) → Security section (sidebar) → Secrets and variables → Actions
```

**Troubleshooting:**
- ❌ **Menu Settings tidak muncul?** → Anda tidak punya akses Admin. Minta owner add Anda sebagai collaborator dengan role Admin/Maintainer.
- ❌ **Ada di Personal Settings?** → Salah halaman! Kembali ke repository page dulu.
- ✅ **Menu muncul?** → Anda punya akses yang benar!

### Step 2: Add Supabase Secrets (3 min)

Click **"New repository secret"** for each:

#### Development Secrets

```
Name: SUPABASE_URL_DEV
Value: https://xxxxxxxxxxxxx.supabase.co

Name: SUPABASE_ANON_KEY_DEV
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
```

**Where to find:**
- Supabase Dashboard → Project Settings → API
- Copy "Project URL" and "anon public" key

#### Production Secrets

```
Name: SUPABASE_URL_PROD
Value: https://yyyyyyyyyyyyy.supabase.co

Name: SUPABASE_ANON_KEY_PROD
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
```

### Step 3: Add Sentry Secret (1 min)

```
Name: SENTRY_DSN
Value: https://xxxxxxxxxxxxx@o1234567.ingest.sentry.io/1234567
```

**Where to find:**
- Sentry.io → Project Settings → Client Keys (DSN)

### Step 4: Add Android Keystore Secrets (5 min)

#### 4a. Convert Keystore to Base64

**On Windows (PowerShell):**

```powershell
cd android/app
$bytes = [System.IO.File]::ReadAllBytes("keystore.jks")
[Convert]::ToBase64String($bytes) | Out-File keystore_base64.txt
```

**On Mac/Linux:**

```bash
cd android/app
base64 keystore.jks > keystore_base64.txt
```

#### 4b. Add Keystore Secrets

```
Name: ANDROID_KEYSTORE_BASE64
Value: [Paste entire content from keystore_base64.txt]

Name: KEYSTORE_PASSWORD
Value: [From android/key.properties - storePassword]

Name: KEY_PASSWORD
Value: [From android/key.properties - keyPassword]

Name: KEY_ALIAS
Value: [From android/key.properties - keyAlias]
```

**Example key.properties:**
```properties
storePassword=sipelor2026
keyPassword=sipelor2026
keyAlias=sipelor
storeFile=keystore.jks
```

### Step 5: (Optional) Add Google Play Secret (3 min)

**Only if you want auto-deploy to Play Store**

1. Create service account:
   - Go to [Google Play Console](https://play.google.com/console)
   - Setup → API access
   - Create new service account
   - Grant "Release Manager" permission
   - Download JSON key

2. Add secret:
```
Name: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
Value: [Paste entire JSON content]
```

### Step 6: (Optional) Add Slack Webhook (2 min)

**Only if you want Slack notifications**

```
Name: SLACK_WEBHOOK_URL
Value: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

**How to create webhook:**
- Slack → Apps → Incoming Webhooks → Add to Slack

---

## ✅ Verify Setup

### Check All Secrets Added

Your secrets list should have minimum 10 items:

- [x] SUPABASE_URL_DEV
- [x] SUPABASE_ANON_KEY_DEV
- [x] SUPABASE_URL_PROD
- [x] SUPABASE_ANON_KEY_PROD
- [x] SENTRY_DSN
- [x] ANDROID_KEYSTORE_BASE64
- [x] KEYSTORE_PASSWORD
- [x] KEY_PASSWORD
- [x] KEY_ALIAS
- [x] GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (optional)
- [x] SLACK_WEBHOOK_URL (optional)

### Test CI/CD Pipeline

```bash
# 1. Create test branch
git checkout -b test/ci-pipeline

# 2. Make small change
echo "Testing CI/CD" >> README.md

# 3. Commit and push
git add .
git commit -m "test: verify CI/CD pipeline"
git push origin test/ci-pipeline

# 4. Create Pull Request on GitHub
# 5. Go to "Actions" tab - should see workflow running
```

**Expected result:**
- ✅ "Flutter CI/CD Pipeline" workflow starts
- ✅ "Code Analysis" job completes
- ✅ "Run Tests" job completes
- ✅ "Build Android Debug APK" job completes
- ✅ APK artifact available for download

---

## 🚨 Troubleshooting

### Error: "Secret not found"

**Problem:**
```
Error: Secret SUPABASE_URL_DEV is not defined
```

**Solution:**
1. Check secret name matches exactly (case sensitive!)
2. Make sure no extra spaces in name
3. Re-add the secret

### Error: "Keystore decode failed"

**Problem:**
```
Error: Could not decode keystore
```

**Solution:**
1. Re-generate base64:
   ```powershell
   # Make sure no line breaks
   $bytes = [System.IO.File]::ReadAllBytes("keystore.jks")
   [Convert]::ToBase64String($bytes) | Set-Content keystore_base64.txt -NoNewline
   ```
2. Copy entire string (no line breaks!)
3. Re-add ANDROID_KEYSTORE_BASE64 secret

### Error: "Wrong password for keystore"

**Problem:**
```
Error: Keystore password incorrect
```

**Solution:**
1. Check `android/key.properties` file
2. Make sure passwords match exactly
3. Re-add KEYSTORE_PASSWORD and KEY_PASSWORD secrets

### Error: "Gradle build failed"

**Problem:**
```
Error: Could not find keystore file
```

**Solution:**
Check `.github/workflows/flutter-ci.yml` line 139-141:
```yaml
- name: 🔑 Decode keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks
```

Make sure path is: `android/app/keystore.jks` (not `android/keystore.jks`)

---

## 📊 What Happens After Setup?

### On Pull Request:
1. Code analysis runs
2. Tests execute
3. **Debug APK builds** ← You can download this
4. Results posted in PR

### On Push to Main:
1. All above +
2. **Release APK builds** ← Production-ready
3. **App Bundle builds** ← For Play Store
4. (Optional) Auto-deploys to Play Store Internal Track
5. (Optional) Slack notification sent

### On Git Tag (e.g., v1.0.0):
1. All above +
2. **GitHub Release created** with APK & AAB files attached

---

## 🎯 Next Steps

After GitHub Secrets configured:

1. ✅ **Verify pipeline works** (create test PR)
2. ⏳ **Execute manual testing** (see `MANUAL_TESTING_PLAN.md`)
3. ⏳ **Deploy email templates** (see `EMAIL_TEMPLATES.md`)
4. 🚀 **Production deployment**

---

## 📞 Need Help?

**Common issues:** See troubleshooting section above

**Still stuck?**
- Check Actions logs for detailed error messages
- Ask in team Slack: #sipelor-deployment
- Email: dev-team@sipelor-bedas.com

---

**Setup Time**: ~15 minutes  
**Difficulty**: ⭐⭐ (Easy-Medium)  
**Once done**: You're ready for automated builds! 🎉

---

*Last Updated: 28 Januari 2026*
