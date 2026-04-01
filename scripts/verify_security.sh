#!/bin/bash

# ============================================
# Security Verification Script for SIPELOR
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🔒 SIPELOR Security Verification"
echo "============================================"
echo ""

ISSUES=0

# Check 1: Verify .env not in git history
echo "📝 [1/5] Checking .env in git history..."
if git log --all --full-history -- .env 2>/dev/null | grep -q "commit"; then
    echo -e "${RED}❌ [FAIL] .env found in git history - ROTATE SUPABASE KEYS!${NC}"
    ((ISSUES++))
else
    echo -e "${GREEN}✅ [PASS] .env never committed to git${NC}"
fi
echo ""

# Check 2: Verify keystore files not in git history
echo "🔑 [2/5] Checking keystore files in git history..."
if git log --all --full-history -- "*.jks" 2>/dev/null | grep -q "commit"; then
    echo -e "${RED}❌ [FAIL] Keystore files found in git history - GENERATE NEW KEYSTORE!${NC}"
    ((ISSUES++))
else
    echo -e "${GREEN}✅ [PASS] No keystore files in git history${NC}"
fi
echo ""

# Check 3: Verify key.properties not in git history
echo "🔐 [3/5] Checking key.properties in git history..."
if git log --all --full-history -- android/key.properties 2>/dev/null | grep -q "commit"; then
    echo -e "${RED}❌ [FAIL] key.properties found in git history - GENERATE NEW KEYSTORE!${NC}"
    ((ISSUES++))
else
    echo -e "${GREEN}✅ [PASS] key.properties never committed${NC}"
fi
echo ""

# Check 4: Verify .gitignore exists and is correct
echo "📋 [4/5] Checking .gitignore configuration..."

if grep -q "\.env" .gitignore 2>/dev/null; then
    echo -e "${GREEN}✅ [PASS] .env is gitignored${NC}"
else
    echo -e "${RED}❌ [FAIL] .env not in .gitignore${NC}"
    ((ISSUES++))
fi

if grep -q "key\.properties" .gitignore 2>/dev/null; then
    echo -e "${GREEN}✅ [PASS] key.properties is gitignored${NC}"
else
    echo -e "${RED}❌ [FAIL] key.properties not in .gitignore${NC}"
    ((ISSUES++))
fi

if grep -q "\.jks" .gitignore 2>/dev/null; then
    echo -e "${GREEN}✅ [PASS] .jks files are gitignored${NC}"
else
    echo -e "${RED}❌ [FAIL] .jks not in .gitignore${NC}"
    ((ISSUES++))
fi
echo ""

# Check 5: Run Flutter analysis
echo "🔍 [5/5] Running static analysis..."
if flutter analyze --no-pub 2>&1 > /dev/null; then
    echo -e "${GREEN}✅ [PASS] Static analysis passed${NC}"
else
    echo -e "${YELLOW}⚠️  [WARN] Static analysis found issues${NC}"
fi
echo ""

# Summary
echo "============================================"
echo "📊 Security Verification Complete"
echo "============================================"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}🎉 [SUCCESS] No security issues found!${NC}"
    echo ""
    echo "Your project is SECURE and ready for production! 🚀"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  [WARNING] $ISSUES security issue(s) found!${NC}"
    echo ""
    echo "Please review and fix the issues above."
    echo "See QUICK_SECURITY_FIXES.md for detailed instructions."
    echo ""
    exit 1
fi
