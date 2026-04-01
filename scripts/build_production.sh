#!/bin/bash

# ============================================
# Production Build Script for SIPELOR
# ============================================
# 
# This script builds the app for production with
# proper security configuration.

set -e

echo "🚀 SIPELOR Production Build"
echo "============================="
echo ""

# Auto-increment version
echo "📦 Incrementing build version..."
bash scripts/increment_version.sh build
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to increment version!"
    exit 1
fi
echo ""

# Check if .env file exists (it shouldn't be in production!)
if [ -f ".env" ]; then
    echo "⚠️  WARNING: .env file detected!"
    echo "   .env files should not be used in production builds."
    echo "   Using --dart-define instead for better security."
    echo ""
fi

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo "❌ ERROR: android/key.properties not found!"
    echo "   Run: ./scripts/generate_keystore.sh"
    exit 1
fi

# Prompt for Supabase credentials
echo "📝 Enter Supabase credentials:"
echo "(These will be compiled into the app, not stored in files)"
echo ""
read -p "Supabase URL: " SUPABASE_URL
read -p "Supabase Anon Key: " SUPABASE_ANON_KEY

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ ERROR: Credentials cannot be empty!"
    exit 1
fi

echo ""
echo "🔧 Build Configuration:"
echo "   - Credentials: Using --dart-define"
echo "   - Obfuscation: Enabled"
echo "   - Debug info: Split to build/symbols"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

echo ""
echo "🔨 Building Android APK (Release)..."
flutter build apk --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols \
    --target-platform android-arm,android-arm64

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""
echo "📦 Output files:"
ls -lh build/app/outputs/flutter-apk/*.apk
echo ""

# Show version info
if [ -f ".kombai/version_info.txt" ]; then
    echo "📋 Version Info:"
    cat .kombai/version_info.txt
    echo ""
fi

echo "🔒 Security Checklist:"
echo "  [✓] Credentials passed via --dart-define"
echo "  [✓] Code obfuscation enabled"
echo "  [✓] Debug symbols split"
echo "  [✓] Version auto-incremented"
echo "  [ ] Verify keystore is correct"
echo "  [ ] Test APK on device"
echo "  [ ] Run security scan"
echo ""

echo "📋 Next Steps:"
echo "  1. Test the APK: adb install build/app/outputs/flutter-apk/app-release.apk"
echo "  2. Verify functionality on real device"
echo "  3. Run security audit before publishing"
echo "  4. Upload to Google Play Console"
echo ""
echo "⚠️  REMEMBER:"
echo "  - Keep build/app/outputs/symbols for crash reports"
echo "  - Never share APK publicly before Play Store review"
echo "  - Test payment flow thoroughly"
echo ""
