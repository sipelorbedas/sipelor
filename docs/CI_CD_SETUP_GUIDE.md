# CI/CD Setup Guide - SIPELOR BEDAS

## Overview

This guide explains how to set up Continuous Integration and Continuous Deployment (CI/CD) for the SIPELOR BEDAS project using GitHub Actions.

---

## 📋 Prerequisites

- GitHub repository
- Supabase project credentials
- Sentry account (optional, for error tracking)
- Basic understanding of GitHub Actions

---

## 🔧 GitHub Actions Workflows

The project includes two main workflows:

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**

| Job | Description |
|-----|-------------|
| **analyze** | Code formatting & analysis |
| **test** | Unit tests with coverage |
| **build-android** | Build Android APK |
| **build-web** | Build web version |
| **security** | Security vulnerability scan |
| **notify** | Build status notification |

### 2. Release Workflow (`.github/workflows/release.yml`)

**Triggers:**
- Tag push matching `v*` pattern (e.g., `v1.0.0`)

**Jobs:**

| Job | Description |
|-----|-------------|
| **create-release** | Create GitHub release |
| **build-android-release** | Build production APK & AAB |

---

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository:

**Path:** Repository → Settings → Secrets and variables → Actions

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | `eyJhbGciOiJI...` |
| `SENTRY_DSN` | Sentry DSN (optional) | `https://xxx@sentry.io/xxx` |

### How to Add Secrets:

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its name and value

---

## 🚀 Deployment Workflows

### Development Deployment

```bash
# Push to develop branch triggers CI
git checkout develop
git add .
git commit -m "feat: add new feature"
git push origin develop
```

**Result:**
- ✅ Code analysis
- ✅ Tests run
- ✅ Debug APK built
- ✅ Artifacts uploaded

### Production Deployment

```bash
# Push to main branch triggers full build
git checkout main
git merge develop
git push origin main
```

**Result:**
- ✅ Code analysis
- ✅ Tests run
- ✅ Release APK built with production credentials
- ✅ Web version built
- ✅ Security scan
- ✅ Artifacts uploaded

### Release Deployment

```bash
# Create and push a tag
git tag v1.0.0
git push origin v1.0.0
```

**Result:**
- ✅ GitHub release created
- ✅ Production APK & AAB built
- ✅ Assets attached to release

---

## 📊 Build Artifacts

After successful builds, artifacts are available for download:

**Location:** Repository → Actions → Select workflow run → Artifacts

| Artifact | Description | Retention |
|----------|-------------|-----------|
| `sipelor-apk-{sha}` | Android APK file | 30 days |
| `sipelor-web-{sha}` | Web build files | 30 days |

---

## 🧪 Running Tests Locally

### Using Scripts:

**Linux/Mac:**
```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

**Windows:**
```batch
scripts\run_tests.bat
```

### Manual Commands:

```bash
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Run analysis
flutter analyze

# Run tests with coverage
flutter test --coverage

# View coverage (if lcov installed)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📈 Code Coverage

### Viewing Coverage Reports

**Local:**
1. Run tests: `flutter test --coverage`
2. Open: `coverage/lcov.info`
3. Use VS Code extension: **Coverage Gutters**

**CI/CD:**
- Coverage reports uploaded to Codecov (if configured)
- View in workflow artifacts

### Coverage Goals

| Component | Target |
|-----------|--------|
| Models | 80%+ |
| Services | 70%+ |
| Repositories | 70%+ |
| Widgets | 50%+ |
| Overall | 60%+ |

---

## 🔒 Security Scanning

### Trivy Vulnerability Scanner

Automatically scans for:
- Dependency vulnerabilities
- Misconfigurations
- Secrets in code

**Results:** Repository → Security → Code scanning alerts

---

## 🐛 Troubleshooting

### Build Fails on CI but Works Locally

**Possible causes:**
1. Missing GitHub secrets
2. Different Flutter version
3. Platform-specific issues

**Solutions:**
```bash
# Check Flutter version matches CI (3.38.4)
flutter --version

# Run exact CI commands
flutter pub get
flutter analyze
flutter test
```

### Secrets Not Working

**Check:**
1. Secret names match exactly (case-sensitive)
2. No extra spaces in secret values
3. Secrets available to workflow

### APK Build Fails

**Common issues:**
1. Missing signing configuration
2. Incorrect `--dart-define` values
3. Java version mismatch

**Solution:**
```bash
# Ensure Java 17 is installed
java -version

# Test build locally
flutter build apk --release \
  --dart-define=SUPABASE_URL=test \
  --dart-define=SUPABASE_ANON_KEY=test
```

---

## 📋 Workflow Status Badges

Add to your README.md:

```markdown
![CI/CD](https://github.com/your-username/sipelor/workflows/CI/CD%20Pipeline/badge.svg)
![Tests](https://github.com/your-username/sipelor/workflows/CI/CD%20Pipeline/badge.svg?event=push)
```

---

## 🔄 Workflow Customization

### Modify Triggers

Edit `.github/workflows/ci.yml`:

```yaml
on:
  push:
    branches: [ main, develop, feature/* ]  # Add more branches
  schedule:
    - cron: '0 0 * * *'  # Run daily at midnight
```

### Add More Jobs

```yaml
jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: flutter analyze --fatal-infos
```

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Codecov Integration](https://about.codecov.io/)

---

## ✅ Checklist

After setting up CI/CD:

- [ ] GitHub secrets configured
- [ ] First CI build successful
- [ ] Tests passing in CI
- [ ] Coverage reports generated
- [ ] Release workflow tested
- [ ] Team members have access
- [ ] Documentation updated

---

**Last Updated:** 2026-02-20

**Maintained by:** SIPELOR Development Team
