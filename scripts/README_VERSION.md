# 📦 Automatic Version Management

Sistem manajemen versi otomatis untuk aplikasi SIPELOR yang akan menaikkan nomor build secara otomatis setiap kali Anda melakukan build production.

## 🎯 Format Versi

Format versi mengikuti standar semantic versioning dengan build number:

```
major.minor.patch+build
```

Contoh: `1.0.0+1`, `1.2.3+45`, `2.0.0+100`

- **major**: Perubahan besar yang tidak kompatibel dengan versi sebelumnya
- **minor**: Penambahan fitur baru yang kompatibel dengan versi sebelumnya  
- **patch**: Perbaikan bug yang kompatibel dengan versi sebelumnya
- **build**: Nomor build yang terus bertambah untuk setiap build

## 🚀 Penggunaan

### Automatic (Recommended)

Saat menjalankan script build production, versi akan otomatis bertambah:

**Windows:**
```cmd
scripts\build_production.bat
```

**Linux/Mac:**
```bash
./scripts/build_production.sh
```

Build number akan otomatis bertambah 1 setiap kali build.

### Manual

Jika Anda ingin mengatur versi secara manual:

**Windows:**
```powershell
# Increment build number only (default)
powershell -ExecutionPolicy Bypass -File scripts\increment_version.ps1

# Increment patch version (also increments build)
powershell -ExecutionPolicy Bypass -File scripts\increment_version.ps1 -type patch

# Increment minor version (also increments build)
powershell -ExecutionPolicy Bypass -File scripts\increment_version.ps1 -type minor

# Increment major version (also increments build)
powershell -ExecutionPolicy Bypass -File scripts\increment_version.ps1 -type major

# Dry run (lihat perubahan tanpa menerapkannya)
powershell -ExecutionPolicy Bypass -File scripts\increment_version.ps1 -dryRun
```

**Linux/Mac:**
```bash
# Increment build number only (default)
bash scripts/increment_version.sh

# Increment patch version (also increments build)
bash scripts/increment_version.sh patch

# Increment minor version (also increments build)
bash scripts/increment_version.sh minor

# Increment major version (also increments build)
bash scripts/increment_version.sh major

# Dry run (lihat perubahan tanpa menerapkannya)
bash scripts/increment_version.sh build true
```

## 📋 Contoh Skenario

### Skenario 1: Bug Fix Release
```bash
# Current version: 1.0.0+1
bash scripts/increment_version.sh patch
# New version: 1.0.1+2
```

### Skenario 2: New Feature Release
```bash
# Current version: 1.0.1+2
bash scripts/increment_version.sh minor
# New version: 1.1.0+3
```

### Skenario 3: Breaking Changes
```bash
# Current version: 1.1.0+3
bash scripts/increment_version.sh major
# New version: 2.0.0+4
```

### Skenario 4: Daily Builds
```bash
# Build pertama hari ini: 1.0.0+1
scripts\build_production.bat
# Version setelah build: 1.0.0+2

# Build kedua hari ini: 1.0.0+2
scripts\build_production.bat
# Version setelah build: 1.0.0+3
```

## 📁 File Version Info

Setelah increment version, informasi versi akan disimpan di:
```
.kombai/version_info.txt
```

File ini berisi:
- Nomor versi terbaru
- Tanggal dan waktu build
- Tipe update (major/minor/patch/build)

## ⚙️ Integrasi dengan CI/CD

Anda dapat mengintegrasikan script ini dengan CI/CD pipeline:

```yaml
# Example: GitHub Actions
- name: Increment version
  run: bash scripts/increment_version.sh build

- name: Build APK
  run: flutter build apk --release
```

## 🔍 Troubleshooting

### Error: "Version line not found"
Pastikan `pubspec.yaml` memiliki format yang benar:
```yaml
version: 1.0.0+1
```

### Error: "Invalid version format"
Format versi harus: `major.minor.patch+build`
- ✅ Benar: `1.0.0+1`
- ❌ Salah: `1.0.0`, `1.0+1`, `v1.0.0+1`

### Version tidak update di Google Play Console
Pastikan Anda melakukan commit perubahan `pubspec.yaml` ke git setelah increment version, atau jalankan increment version sebelum commit.

## 📝 Best Practices

1. **Automatic Builds**: Gunakan script `build_production.*` yang sudah otomatis increment version
2. **Manual Control**: Gunakan `increment_version.*` saat perlu mengubah major/minor/patch version
3. **Commit Version**: Commit perubahan `pubspec.yaml` setelah release ke production
4. **Build Numbers**: Build number harus selalu naik, tidak boleh turun atau sama
5. **Google Play**: Build number baru harus lebih tinggi dari yang sudah di Play Store

## 🎯 Kapan Mengubah Version Number?

| Tipe Perubahan | Version Command | Contoh |
|----------------|----------------|--------|
| Hotfix/Bug Fix | `patch` | 1.0.0 → 1.0.1 |
| Fitur Baru | `minor` | 1.0.1 → 1.1.0 |
| Breaking Changes | `major` | 1.1.0 → 2.0.0 |
| Development Build | `build` (auto) | 1.0.0+1 → 1.0.0+2 |

## 📚 Referensi

- [Semantic Versioning](https://semver.org/)
- [Flutter Version Documentation](https://docs.flutter.dev/deployment/android#reviewing-the-app-manifest)
- [Google Play Version Codes](https://developer.android.com/studio/publish/versioning)
