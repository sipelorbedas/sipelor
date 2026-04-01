#!/bin/bash
# Run all tests for SIPELOR BEDAS with coverage
# Unix/Linux/Mac shell script

set -e

echo "========================================"
echo "   SIPELOR BEDAS - Test Suite Runner"
echo "========================================"
echo ""

echo "[1/5] Generating mock classes..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "[2/5] Running unit tests..."
flutter test test/services/ test/utils/

echo ""
echo "[3/5] Running widget tests..."
flutter test test/widgets/

echo ""
echo "[4/5] Running integration tests..."
flutter test test/integration/

echo ""
echo "[5/5] Generating coverage report..."
flutter test --coverage

echo ""
echo "========================================"
echo "   All tests passed! ✅"
echo "   Coverage report: coverage/lcov.info"
echo "========================================"
echo ""
echo "To view coverage in browser:"
echo "  1. Install genhtml: apt-get install lcov (Ubuntu) or brew install lcov (Mac)"
echo "  2. Run: genhtml -o coverage/html coverage/lcov.info"
echo "  3. Open: coverage/html/index.html"
echo ""
