#!/bin/bash

# ============================================
# Security Testing Script for SIPELOR
# ============================================
# 
# Runs all security-related tests and checks

set -e

echo "🔒 SIPELOR Security Test Suite"
echo "==============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

run_test() {
    local test_name=$1
    echo "🧪 Running: $test_name"
    
    if flutter test "$test_name" --no-pub 2>&1 | tee /tmp/test_output.txt; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
    fi
    echo ""
}

# Ensure dependencies are installed
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Run security tests
echo "🔐 Running Security Tests..."
echo "----------------------------"
echo ""

run_test "test/utils/password_validator_test.dart"
run_test "test/utils/input_sanitizer_test.dart"
run_test "test/services/rate_limiter_test.dart"

# Check for sensitive files
echo "🔍 Checking for sensitive files..."
echo "-----------------------------------"

check_file() {
    local file=$1
    local should_exist=$2
    
    if [ -f "$file" ]; then
        if [ "$should_exist" == "no" ]; then
            echo -e "${RED}❌ FAIL: $file exists (should be gitignored)${NC}"
            ((FAILED++))
        else
            echo -e "${GREEN}✅ PASS: $file exists${NC}"
            ((PASSED++))
        fi
    else
        if [ "$should_exist" == "yes" ]; then
            echo -e "${YELLOW}⚠️  WARN: $file not found${NC}"
        else
            echo -e "${GREEN}✅ PASS: $file not in repository${NC}"
            ((PASSED++))
        fi
    fi
}

check_file ".env" "no"
check_file "android/key.properties" "no"
check_file ".gitignore" "yes"
check_file ".env.example" "yes"
check_file "android/key.properties.example" "yes"

echo ""

# Check .gitignore contents
echo "🔍 Verifying .gitignore..."
echo "-------------------------"

check_gitignore() {
    local pattern=$1
    
    if grep -q "$pattern" .gitignore 2>/dev/null; then
        echo -e "${GREEN}✅ PASS: '$pattern' in .gitignore${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL: '$pattern' missing from .gitignore${NC}"
        ((FAILED++))
    fi
}

check_gitignore "\.env"
check_gitignore "key\.properties"
check_gitignore "\.jks"
check_gitignore "\.keystore"

echo ""

# Check for hardcoded secrets
echo "🔍 Scanning for hardcoded secrets..."
echo "------------------------------------"

SECRET_PATTERNS=(
    "password.*=.*['\"]"
    "api[_-]?key.*=.*['\"]"
    "secret.*=.*['\"]"
    "token.*=.*['\"]"
)

FOUND_SECRETS=0

for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern" lib/ --exclude-dir=".git" --exclude="*.example" 2>/dev/null; then
        echo -e "${RED}❌ Found potential secret: $pattern${NC}"
        ((FOUND_SECRETS++))
        ((FAILED++))
    fi
done

if [ $FOUND_SECRETS -eq 0 ]; then
    echo -e "${GREEN}✅ No hardcoded secrets found${NC}"
    ((PASSED++))
fi

echo ""

# Security analysis
echo "📊 Running static analysis..."
echo "-----------------------------"

if flutter analyze --no-pub 2>&1 | tee /tmp/analyze_output.txt; then
    echo -e "${GREEN}✅ Static analysis passed${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Static analysis failed${NC}"
    ((FAILED++))
fi

echo ""

# Summary
echo "=============================="
echo "📊 Security Test Summary"
echo "=============================="
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All security tests passed!${NC}"
    echo ""
    echo "✅ Ready for production deployment"
    exit 0
else
    echo -e "${RED}⚠️  $FAILED security issues found!${NC}"
    echo ""
    echo "❌ Fix issues before deployment"
    exit 1
fi
