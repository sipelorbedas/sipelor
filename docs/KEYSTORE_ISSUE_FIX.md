# 🔐 Keystore Issue & Fix Guide

> **Problem**: APK Release build gagal karena keystore password tidak cocok
> 
> **Error**: `Keystore was tampered with, or password was incorrect`  
> **Date**: 28 Januari 2026

---

## ❌ Problem Description

Saat mencoba build APK release:
```bash
flutter build apk --release
```

Error muncul:
```
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:packageRelease'.
> com.android.ide.common.signing.KeytoolException: Failed to read key sipelor from store "D:\RAMA\PROJECT DISPORA\sipelorbedas\sipelor\android\app\sipelor-keystore.jks": Keystore was tampered with, or password was incorrect
```

### Root Cause

Password di `android/key.properties` tidak cocok dengan password yang digunakan saat membuat keystore file (`sipelor-keystore.jks`).

Current password in `android/key.properties`:
```properties
storePassword=S1pelor123&*!@%^Bedas
keyPassword=S1pelor123&*!@%^Bedas
```

Kemungkinan:
1. Password salah/typo
2. Keystore dibuat dengan password lain
3. Special characters (`&*!@%^`) menyebabkan parsing error

---

## ✅ Solution Options

### Option 1: Find Correct Password (Recommended)

Jika password keystore masih diingat:

1. **Verify password** dengan keytool:
   ```powershell
   keytool -list -v -keystore android\app\sipelor-keystore.jks -alias sipelor
   ```
   
2. **Update `android/key.properties`** dengan password yang benar:
   ```properties
   storePassword=YourCorrectPassword
   keyPassword=YourCorrectPassword
   keyAlias=sipelor
   storeFile=app/sipelor-keystore.jks
   ```

3. **Rebuild APK**:
   ```bash
   flutter build apk --release
   ```

---

### Option 2: Generate New Keystore (If Password Lost)

**⚠️ WARNING**: Ini akan membuat keystore baru. Jika app sudah dipublish di Play Store, JANGAN lakukan ini karena akan menyebabkan update conflict!

#### Step 1: Backup Old Keystore
```powershell
Copy-Item android\app\sipelor-keystore.jks android\app\sipelor-keystore-OLD.jks
```

#### Step 2: Generate New Keystore
```powershell
keytool -genkey -v -keystore android\app\sipelor-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sipelor
```

Masukkan informasi:
- **Password**: Gunakan password baru yang mudah diingat (misal: `Sipelor2026!`)
- **Nama**: DISPORA Kabupaten Bandung
- **Organization**: Dinas Pemuda dan Olahraga
- **City**: Bandung
- **Country**: ID

#### Step 3: Update key.properties
```properties
storePassword=Sipelor2026!
keyPassword=Sipelor2026!
keyAlias=sipelor
storeFile=app/sipelor-keystore.jks
```

#### Step 4: Test Build
```bash
flutter build apk --release
```

---

### Option 3: Build Debug APK (Temporary Solution)

Untuk testing immediate tanpa signing:

```bash
# Debug APK (no signing required)
flutter build apk --debug

# Atau dengan split per ABI untuk size lebih kecil
flutter build apk --debug --split-per-abi
```

**Output location**: `build/app/outputs/flutter-apk/app-debug.apk`

**Limitations**:
- ❌ Tidak bisa di-publish ke Play Store
- ❌ Performance mode debug (lebih lambat)
- ✅ Bisa untuk internal testing
- ✅ Install langsung ke device

---

### Option 4: Remove Signing Config (Last Resort)

Edit `android/app/build.gradle.kts`, ubah signingConfig:

```kotlin
buildTypes {
    release {
        // Comment out signing config
        // signingConfig = signingConfigs.getByName("release")
        
        // Use debug signing instead
        signingConfig = signingConfigs.getByName("debug")
        
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

Then build:
```bash
flutter build apk --release
```

**Warning**: APK will be signed dengan debug certificate, tidak cocok untuk production!

---

## 📋 Checklist - Production Release

Sebelum publish ke Play Store:

- [ ] **Verify keystore password** dengan keytool
- [ ] **Backup keystore file** ke tempat aman (Google Drive, etc.)
- [ ] **Document password** di password manager (1Password, LastPass)
- [ ] **Test install APK** di real device
- [ ] **Check APK size** (< 50 MB ideal)
- [ ] **Verify app signature** dengan jarsigner
- [ ] **Test all critical features** di production APK

---

## 🔒 Best Practices - Keystore Management

### 1. Password Guidelines
```
✅ DO:
- Use strong but memorable password
- Mix uppercase, lowercase, numbers
- Length: 12-16 characters
- Example: Sipelor2026Bedas!

❌ DON'T:
- Too complex: S1p@l0r#2026&*!@%^
- Too simple: sipelor123
- Same as old password
```

### 2. Secure Storage
```
✅ Store keystore in:
- Private Git repository (encrypted)
- Company password manager
- Encrypted USB drive (backup)
- Google Cloud Storage (private bucket)

❌ DON'T store in:
- Public repository
- Unencrypted cloud storage
- Email attachments
- Shared folders
```

### 3. Access Control
```
Only these people should have access:
- Lead Developer
- DevOps Engineer
- Project Manager (backup only)
- CTO/Technical Director

Keep password in:
- Company password manager (e.g., 1Password Team)
- Sealed envelope in safe (physical backup)
```

---

## 🚀 After Fix - Next Steps

Once keystore issue is resolved:

1. **Build release APK**:
   ```bash
   flutter build apk --release --split-per-abi
   ```

2. **Verify output**:
   ```bash
   ls build\app\outputs\flutter-apk\*.apk
   ```

3. **Test installation**:
   ```bash
   adb install build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
   ```

4. **Sign for Play Store** (if needed):
   - Use bundletool for AAB format
   - Or use Play App Signing (Google manages keys)

---

## 📞 Need Help?

Contact:
- **Lead Developer**: [Your Contact]
- **DevOps Team**: [DevOps Contact]
- **Documentation**: See `docs/BUILD_GUIDE.md`

---

## 🔗 Related Documents

- [Flutter App Signing Guide](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Android Keystore System](https://developer.android.com/training/articles/keystore)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)

---

**Last Updated**: 28 Januari 2026  
**Version**: 1.0  
**Status**: ⚠️ Issue Pending Resolution
