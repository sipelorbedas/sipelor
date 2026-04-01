#!/bin/bash

# ============================================
# Android Keystore Generation Script
# ============================================
# 
# This script helps generate a new Android keystore
# for signing your app releases.
#
# IMPORTANT: Run this script only once and keep
# the generated keystore file VERY SECURE!

set -e

echo "🔐 Android Keystore Generation for SIPELOR"
echo "==========================================="
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "  1. This will create a NEW keystore file"
echo "  2. Keep the keystore file VERY SECURE"
echo "  3. NEVER commit keystore to version control"
echo "  4. Store backup in encrypted password manager"
echo "  5. If you lose this keystore, you can't update your app!"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cancelled by user"
    exit 1
fi

# Configuration
KEYSTORE_DIR="android/app"
KEYSTORE_NAME="sipelor-keystore.jks"
KEYSTORE_PATH="$KEYSTORE_DIR/$KEYSTORE_NAME"
KEY_ALIAS="sipelor"
KEY_PROPERTIES="android/key.properties"

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo "⚠️  WARNING: Keystore file already exists at: $KEYSTORE_PATH"
    read -p "Do you want to OVERWRITE it? (yes/no): " overwrite
    
    if [ "$overwrite" != "yes" ]; then
        echo "❌ Keeping existing keystore. Exiting..."
        exit 0
    fi
    
    echo "🗑️  Backing up old keystore..."
    mv "$KEYSTORE_PATH" "$KEYSTORE_PATH.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

echo ""
echo "🔨 Generating new keystore..."
echo "   Location: $KEYSTORE_PATH"
echo "   Alias: $KEY_ALIAS"
echo ""
echo "You will be asked to provide:"
echo "  - Keystore password (remember this!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name, organization, city, country"
echo ""

# Generate keystore
keytool -genkey -v -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS"

if [ $? -ne 0 ]; then
    echo "❌ Error generating keystore"
    exit 1
fi

echo ""
echo "✅ Keystore generated successfully!"
echo ""

# Prompt for passwords to create key.properties
echo "📝 Creating key.properties file..."
echo ""
read -sp "Enter the keystore password: " STORE_PASSWORD
echo ""
read -sp "Enter the key password (press Enter if same as keystore): " KEY_PASSWORD
echo ""

if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD="$STORE_PASSWORD"
fi

# Create key.properties file
cat > "$KEY_PROPERTIES" << EOF
# Android Keystore Configuration
# Generated on: $(date)
# 
# ⚠️  SECURITY WARNING:
# This file contains sensitive credentials!
# - NEVER commit to version control
# - Keep backup in secure password manager
# - File is already in .gitignore

storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=app/$KEYSTORE_NAME
EOF

echo ""
echo "✅ key.properties file created at: $KEY_PROPERTIES"
echo ""

# Display keystore information
echo "📋 Keystore Information:"
echo "========================================"
keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" | head -20
echo ""

# Security checklist
echo "🔒 SECURITY CHECKLIST:"
echo "========================================"
echo "✅ Keystore created: $KEYSTORE_PATH"
echo "✅ key.properties created: $KEY_PROPERTIES"
echo ""
echo "📝 NEXT STEPS (CRITICAL!):"
echo "  1. ✅ Backup keystore file to secure location (encrypted USB, password manager)"
echo "  2. ✅ Save passwords in password manager (DO NOT WRITE ON PAPER!)"
echo "  3. ✅ Verify .gitignore includes key.properties and *.jks"
echo "  4. ✅ Test signing: flutter build apk --release"
echo "  5. ✅ Document keystore details (creation date, validity, etc.)"
echo ""
echo "⚠️  REMEMBER:"
echo "  - If you lose this keystore, you CANNOT update your app on Play Store"
echo "  - Google Play App Signing is recommended for additional security"
echo "  - Rotate keystore every 1-2 years for better security"
echo ""
echo "🎉 Setup complete! You can now build release APKs."
echo ""

# Verify .gitignore
if ! grep -q "key.properties" .gitignore 2>/dev/null; then
    echo "⚠️  WARNING: key.properties not found in .gitignore!"
    echo "   Add it to prevent accidental commits."
fi

if ! grep -q "*.jks" .gitignore 2>/dev/null && ! grep -q "*.keystore" .gitignore 2>/dev/null; then
    echo "⚠️  WARNING: Keystore files not in .gitignore!"
    echo "   Add *.jks and *.keystore to prevent accidental commits."
fi
