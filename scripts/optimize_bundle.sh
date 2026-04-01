#!/bin/bash
# =========================================
#  Bundle Size Optimization Script
#  For Linux/Mac
# =========================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        📦 SIPELOR BEDAS - BUNDLE OPTIMIZATION             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Clean build
echo "[1/5] Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Clean failed"
    exit 1
fi
echo "✅ Clean completed"
echo ""

# Get dependencies
echo "[2/5] Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Dependencies failed"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

# Analyze code
echo "[3/5] Analyzing code..."
flutter analyze --no-pub
echo "✅ Analysis completed"
echo ""

# Build optimized APK with size analysis
echo "[4/5] Building optimized APK..."
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug/ \
  --analyze-size \
  --target-platform android-arm64

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi
echo "✅ Build completed"
echo ""

# Show build size
echo "[5/5] Build Summary:"
echo ""
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    ✅ OPTIMIZATION COMPLETE                ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║ APK Location:                                              ║"
echo "║   build/app/outputs/flutter-apk/app-release.apk           ║"
echo "║                                                            ║"
echo "║ Debug Info:                                                ║"
echo "║   build/debug/                                             ║"
echo "║                                                            ║"
echo "║ Optimizations Applied:                                     ║"
echo "║   ✓ Code obfuscation                                      ║"
echo "║   ✓ Split debug info                                      ║"
echo "║   ✓ Tree shaking                                          ║"
echo "║   ✓ Minification                                          ║"
echo "║   ✓ ARM64 optimization                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
