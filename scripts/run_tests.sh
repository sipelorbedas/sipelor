#!/bin/bash

# SIPELOR BEDAS - Test Runner Script
# Run all tests with coverage and generate reports

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           🧪 SIPELOR BEDAS TEST SUITE                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Clean previous coverage
echo -e "${YELLOW}📦 Cleaning previous coverage...${NC}"
rm -rf coverage/
flutter clean

# Step 2: Get dependencies
echo -e "${YELLOW}📥 Getting dependencies...${NC}"
flutter pub get

# Step 3: Run code analysis
echo -e "${YELLOW}🔍 Running code analysis...${NC}"
flutter analyze || {
    echo -e "${RED}❌ Code analysis failed!${NC}"
    exit 1
}
echo -e "${GREEN}✅ Code analysis passed${NC}"
echo ""

# Step 4: Run tests with coverage
echo -e "${YELLOW}🧪 Running tests with coverage...${NC}"
flutter test --coverage || {
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
}
echo -e "${GREEN}✅ All tests passed${NC}"
echo ""

# Step 5: Generate coverage report
echo -e "${YELLOW}📊 Generating coverage report...${NC}"
if [ -f "coverage/lcov.info" ]; then
    # Calculate coverage percentage
    if command -v lcov &> /dev/null; then
        lcov --summary coverage/lcov.info 2>&1 | grep "lines" || true
    fi
    
    # Generate HTML report (optional, requires genhtml)
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}✅ HTML coverage report generated at coverage/html/index.html${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No coverage file generated${NC}"
fi
echo ""

# Step 6: Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           ✅ TEST SUITE COMPLETED                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  - Review coverage report: coverage/lcov.info"
echo "  - Fix any issues found"
echo "  - Commit changes"
echo ""
