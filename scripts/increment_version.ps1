# ============================================
# Auto Version Increment Script (Windows)
# ============================================
# Automatically increments build number in pubspec.yaml

param(
    [string]$type = "build",
    [switch]$dryRun = $false
)

$pubspecPath = "pubspec.yaml"

if (-not (Test-Path $pubspecPath)) {
    Write-Host "ERROR: pubspec.yaml not found!" -ForegroundColor Red
    exit 1
}

# Read pubspec.yaml
$content = Get-Content $pubspecPath -Raw
$lines = Get-Content $pubspecPath

# Find version line
$versionLine = $lines | Where-Object { $_ -match "^version:\s*(.+)$" }

if (-not $versionLine) {
    Write-Host "ERROR: Version line not found in pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Extract current version
$versionLine -match "^version:\s*(.+)$" | Out-Null
$currentVersion = $matches[1].Trim()

# Parse version (format: major.minor.patch+build)
if ($currentVersion -match "^(\d+)\.(\d+)\.(\d+)\+(\d+)$") {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]
} else {
    Write-Host "ERROR: Invalid version format: $currentVersion" -ForegroundColor Red
    Write-Host "   Expected format: major.minor.patch+build (e.g., 1.0.0+1)" -ForegroundColor Yellow
    exit 1
}

# Store old version
$oldVersion = "$major.$minor.$patch+$build"

# Increment based on type
switch ($type) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
        $build++
    }
    "minor" {
        $minor++
        $patch = 0
        $build++
    }
    "patch" {
        $patch++
        $build++
    }
    "build" {
        $build++
    }
    default {
        Write-Host "ERROR: Invalid type: $type" -ForegroundColor Red
        Write-Host "   Valid types: major, minor, patch, build" -ForegroundColor Yellow
        exit 1
    }
}

$newVersion = "$major.$minor.$patch+$build"

# Display changes
Write-Host ""
Write-Host "Version Update" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "Old Version: " -NoNewline -ForegroundColor Yellow
Write-Host $oldVersion -ForegroundColor White
Write-Host "New Version: " -NoNewline -ForegroundColor Green
Write-Host $newVersion -ForegroundColor White
Write-Host "Update Type: " -NoNewline -ForegroundColor Cyan
Write-Host $type -ForegroundColor White
Write-Host ""

if ($dryRun) {
    Write-Host "DRY RUN - No changes made" -ForegroundColor Magenta
    exit 0
}

# Update pubspec.yaml
$newContent = $content -replace "version:\s*$([regex]::Escape($oldVersion))", "version: $newVersion"
Set-Content -Path $pubspecPath -Value $newContent -NoNewline

Write-Host "Version updated successfully!" -ForegroundColor Green
Write-Host ""

# Create version info file for build artifacts
$versionInfo = @"
Version: $newVersion
Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Build Type: $type
"@

$null = New-Item -Path ".kombai" -ItemType Directory -Force
Set-Content -Path ".kombai/version_info.txt" -Value $versionInfo

exit 0
