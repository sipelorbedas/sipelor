#!/bin/bash

# ============================================
# Auto Version Increment Script (Linux/Mac)
# ============================================
# Automatically increments build number in pubspec.yaml

set -e

# Parse arguments
TYPE="${1:-build}"  # build, patch, minor, major
DRY_RUN="${2:-false}"

PUBSPEC_PATH="pubspec.yaml"

if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "❌ ERROR: pubspec.yaml not found!"
    exit 1
fi

# Extract current version
VERSION_LINE=$(grep "^version:" "$PUBSPEC_PATH")
CURRENT_VERSION=$(echo "$VERSION_LINE" | sed 's/version: *//' | tr -d '\r')

if [ -z "$CURRENT_VERSION" ]; then
    echo "❌ ERROR: Version line not found in pubspec.yaml"
    exit 1
fi

# Parse version (format: major.minor.patch+build)
if [[ $CURRENT_VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    BUILD="${BASH_REMATCH[4]}"
else
    echo "❌ ERROR: Invalid version format: $CURRENT_VERSION"
    echo "   Expected format: major.minor.patch+build (e.g., 1.0.0+1)"
    exit 1
fi

OLD_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"

# Increment based on type
case $TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        BUILD=$((BUILD + 1))
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        BUILD=$((BUILD + 1))
        ;;
    patch)
        PATCH=$((PATCH + 1))
        BUILD=$((BUILD + 1))
        ;;
    build)
        BUILD=$((BUILD + 1))
        ;;
    *)
        echo "❌ ERROR: Invalid type: $TYPE"
        echo "   Valid types: major, minor, patch, build"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"

# Display changes
echo ""
echo "📦 Version Update"
echo "================="
echo -e "\033[33mOld Version:\033[0m $OLD_VERSION"
echo -e "\033[32mNew Version:\033[0m $NEW_VERSION"
echo -e "\033[36mUpdate Type:\033[0m $TYPE"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo "🔍 DRY RUN - No changes made"
    exit 0
fi

# Update pubspec.yaml (cross-platform compatible)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/version: $OLD_VERSION/version: $NEW_VERSION/" "$PUBSPEC_PATH"
else
    # Linux
    sed -i "s/version: $OLD_VERSION/version: $NEW_VERSION/" "$PUBSPEC_PATH"
fi

echo "✅ Version updated successfully!"
echo ""

# Create version info file for build artifacts
mkdir -p .kombai
cat > .kombai/version_info.txt << EOF
Version: $NEW_VERSION
Build Date: $(date "+%Y-%m-%d %H:%M:%S")
Build Type: $TYPE
EOF

exit 0
