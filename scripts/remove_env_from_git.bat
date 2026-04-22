@echo off
REM Remove .env from git history (Windows)
REM This script removes the .env file from git history
REM
REM IMPORTANT: Run this ONLY if you have:
REM 1. Regenerated all Supabase API keys
REM 2. Updated GitHub Secrets
REM 3. Backed up your repository
REM
REM Usage:
REM   remove_env_from_git.bat

setlocal enabledelayedexpansion

echo ================================
echo 🔒 Remove .env from Git History
echo ================================
echo.

REM Check if .env file exists
if not exist ".env" (
    echo ⚠️  .env file not found. Skipping removal.
    exit /b 0
)

echo 📋 Step 1: Remove .env from current tracking...
git rm --cached .env 2>nul || echo ℹ️  .env already removed from tracking

echo.
echo 📋 Step 2: Verify .env is in .gitignore...
findstr /M "^\.env" .gitignore >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ .env is in .gitignore
) else (
    echo ❌ .env is NOT in .gitignore. Adding it now...
    echo .env >> .gitignore
)

echo.
echo 📋 Step 3: Commit the removal...
git add .gitignore
git commit -m "chore: remove .env from tracking and prevent future commits" 2>nul || echo ℹ️  No changes to commit

echo.
echo ⚠️  IMPORTANT: Remove .env from git HISTORY
echo.
echo The above only removes .env from current tracking.
echo To remove it from entire git history, use BFG Repo-Cleaner:
echo.
echo 1. Install BFG (if not installed):
echo    choco install bfg
echo.
echo 2. Remove from history:
echo    bfg --delete-files .env
echo.
echo 3. Or use git filter-branch (slower):
echo    git filter-branch --tree-filter "del .env" -- --all
echo.
echo 4. Force push to remote:
echo    git push origin --force-with-lease
echo.
echo ================================
echo ✅ Done!
echo ================================
