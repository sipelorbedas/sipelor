#!/bin/bash

# ============================================
# Deep Link Testing Script for SIPELOR
# ============================================

echo "🧪 Testing Deep Links for SIPELOR"
echo "===================================="
echo ""

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ ERROR: ADB not found in PATH!"
    echo "   Please install Android SDK Platform Tools"
    echo "   Download: https://developer.android.com/tools/releases/platform-tools"
    exit 1
fi

# Check if device is connected
DEVICE_COUNT=$(adb devices | grep -w "device" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ ERROR: No Android device connected!"
    echo "   Please connect your device and enable USB debugging"
    exit 1
fi

echo "✅ Device connected. Starting tests..."
echo ""

# Test 1: Basic callback
echo "1️⃣  Testing basic callback deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://callback"
sleep 3
echo "   ✓ Done. Check if app opened."
echo ""

# Test 2: Reset password
echo "2️⃣  Testing reset password deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://reset-password"
sleep 3
echo "   ✓ Done. Check if reset password screen opened."
echo ""

# Test 3: Auth callback
echo "3️⃣  Testing auth callback deep link..."
adb shell am start -W -a android.intent.action.VIEW -d "sipelor://auth/callback"
sleep 3
echo "   ✓ Done. Check if app handled auth callback."
echo ""

# Test 4: Legacy Supabase callback
echo "4️⃣  Testing legacy Supabase callback..."
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.sipelor://login-callback"
sleep 3
echo "   ✓ Done. Check if app handled legacy callback."
echo ""

echo "============================================"
echo "✅ All tests completed!"
echo "============================================"
echo ""
echo "Check the app and Flutter console for:"
echo "  • App opened successfully"
echo "  • Correct screens displayed"
echo "  • No errors in console"
echo ""
echo "To monitor logs in real-time, run:"
echo "  adb logcat | grep -E 'Deep|sipelor|Flutter'"
echo ""
