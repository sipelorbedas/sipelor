#!/bin/bash
# Remove .env from git history
# This script removes the .env file from git history using BFG Repo-Cleaner
#
# IMPORTANT: Run this ONLY if you have:
# 1. Regenerated all Supabase API keys
# 2. Updated GitHub Secrets
# 3. Backed up your repository
#
# Usage:
#   ./scripts/remove_env_from_git.sh
#
# This script will:
# 1. Remove .env from current tracking (git rm --cached)
# 2. Show you the commands to remove from history
# 3. Verify .gitignore is correct

set -e

echo "================================"
echo "🔒 Remove .env from Git History"
echo "================================"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Skipping removal."
    exit 0
fi

echo "📋 Step 1: Remove .env from current tracking..."
git rm --cached .env 2>/dev/null || echo "ℹ️  .env already removed from tracking"

echo ""
echo "📋 Step 2: Verify .env is in .gitignore..."
if grep -q "^.env" .gitignore; then
    echo "✅ .env is in .gitignore"
else
    echo "❌ .env is NOT in .gitignore. Adding it now..."
    echo ".env" >> .gitignore
fi

echo ""
echo "📋 Step 3: Commit the removal..."
git add .gitignore
git commit -m "chore: remove .env from tracking and prevent future commits" 2>/dev/null || echo "ℹ️  No changes to commit"

echo ""
echo "⚠️  IMPORTANT: Remove .env from git HISTORY"
echo ""
echo "The above only removes .env from current tracking."
echo "To remove it from entire git history, use BFG Repo-Cleaner:"
echo ""
echo "1. Install BFG:"
echo "   brew install bfg          # macOS"
echo "   choco install bfg         # Windows"
echo "   apt install bfg           # Linux"
echo ""
echo "2. Remove from history:"
echo "   bfg --delete-files .env"
echo ""
echo "3. Or use git filter-branch (slower):"
echo "   git filter-branch --tree-filter 'rm -f .env' -- --all"
echo ""
echo "4. Force push to remote:"
echo "   git push origin --force-with-lease"
echo ""
echo "================================"
echo "✅ Done!"
echo "================================"
