#!/bin/bash

# ============================================================
# SIPELOR BEDAS - Production Build Script (Linux/Mac)
# ============================================================
# 
# IMPORTANT: 
# 1. Copy this file to: build_production_env.sh
# 2. Fill in your actual credentials below
# 3. Make executable: chmod +x build_production_env.sh
# 4. Add build_production_env.sh to .gitignore
# 5. NEVER commit this file with real credentials!
#
# ============================================================

set -e  # Exit on error

echo ""
echo "============================================================"
echo "   BUILDING SIPELOR BEDAS PRODUCTION APK"
echo "============================================================"
echo ""

# ============================
# CONFIGURATION
# ============================
# Replace these with your actual values:

SUPABASE_URL="https://your-project-id.supabase.co"
SUPABASE_ANON_KEY="your-anon-key-here"
SENTRY_DSN="https://your-sentry-dsn@sentry.io/project-id"
ENVIRONMENT="production"

# ============================
# VALIDATION
# ============================

echo "Validating configuration..."
if [ "$SUPABASE_URL" = "https://your-project-id.supabase.co" ]; then
    echo "ERROR: SUPABASE_URL not configured!"
    echo "Please edit this file and set your actual Supabase URL"
    exit 1
fi

if [ "$SUPABASE_ANON_KEY" = "your-anon-key-here" ]; then
    echo "ERROR: SUPABASE_ANON_KEY not configured!"
    echo "Please edit this file and set your actual Supabase anon key"
    exit 1
fi

echo "Configuration validated successfully!"
echo ""

# ============================
# PRE-BUILD CHECKS
# ============================

echo "Running pre-build checks..."
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found in PATH"
    echo "Please install Flutter or add it to your PATH"
    exit 1
fi

echo "Flutter: OK"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
echo "Clean: OK"
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get
echo "Dependencies: OK"
echo ""

# ============================
# BUILD APK
# ============================

echo ""
echo "============================================================"
echo "   BUILDING RELEASE APK"
echo "============================================================"
echo ""
echo "Configuration:"
echo "- Environment: $ENVIRONMENT"
echo "- Supabase URL: $SUPABASE_URL"
echo "- Sentry: Enabled"
echo ""
echo "Building... This may take a few minutes..."
echo ""

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=SENTRY_DSN="$SENTRY_DSN" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --dart-define=ENABLE_SSL_PINNING=true

# ============================
# POST-BUILD
# ============================

echo ""
echo "============================================================"
echo "   BUILD SUCCESSFUL!"
echo "============================================================"
echo ""

# Get APK info
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)

echo "APK Location: $APK_PATH"
echo "APK Size: $APK_SIZE"
echo ""

# Optional: Copy to home directory
echo "Copying APK to home directory..."
cp "$APK_PATH" "$HOME/sipelor-v1.0.0.apk"
echo "APK copied to: ~/sipelor-v1.0.0.apk"
echo ""

echo "============================================================"
echo "   NEXT STEPS"
echo "============================================================"
echo ""
echo "1. Test the APK on a physical device"
echo "2. Verify all features work correctly"
echo "3. Check Sentry integration (trigger test error)"
echo "4. Upload to Play Console for testing"
echo ""
echo "============================================================"
echo ""

# Open output folder (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "Open output folder? (y/n): " OPEN_FOLDER
    if [ "$OPEN_FOLDER" = "y" ]; then
        open "build/app/outputs/flutter-apk"
    fi
fi
