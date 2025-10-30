#!/bin/bash

# Setup script for Google OAuth credentials

CONFIG_DIR="lib/config"
EXAMPLE_FILE="$CONFIG_DIR/google_credentials.example.dart"
CREDENTIALS_FILE="$CONFIG_DIR/google_credentials.dart"

echo "🔑 Google OAuth Credentials Setup"
echo "=================================="
echo ""

# Check if credentials file already exists
if [ -f "$CREDENTIALS_FILE" ]; then
    echo "⚠️  Credentials file already exists at: $CREDENTIALS_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled"
        exit 1
    fi
fi

# Copy example file
cp "$EXAMPLE_FILE" "$CREDENTIALS_FILE"
echo "✅ Created $CREDENTIALS_FILE"
echo ""

# Prompt for credentials
echo "📝 Please enter your Google OAuth credentials:"
echo ""
echo "Desktop OAuth 2.0 Credentials (from Google Cloud Console - Desktop app):"
read -p "   Desktop Client ID: " DESKTOP_CLIENT_ID
read -p "   Desktop Client Secret: " DESKTOP_CLIENT_SECRET
echo ""

# Optional: Mobile credentials
read -p "Do you have Mobile (Android) credentials? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "   Mobile Client ID: " MOBILE_CLIENT_ID
else
    MOBILE_CLIENT_ID="YOUR_MOBILE_CLIENT_ID.apps.googleusercontent.com"
fi

# Update the credentials file
cat > "$CREDENTIALS_FILE" << EOF
/// Google OAuth credentials configuration
/// 
/// IMPORTANT: This file contains sensitive credentials and is gitignored.
/// Copy google_credentials.example.dart and fill in your actual credentials.

class GoogleCredentials {
  // Desktop OAuth 2.0 credentials (from Google Cloud Console - Desktop app)
  static const String desktopClientId = '$DESKTOP_CLIENT_ID';
  static const String desktopClientSecret = '$DESKTOP_CLIENT_SECRET';
  
  // Mobile OAuth 2.0 client ID (from Google Cloud Console - Android app)
  // Note: Mobile doesn't use client secret, only client ID
  static const String mobileClientId = '$MOBILE_CLIENT_ID';
}
EOF

echo ""
echo "✅ Credentials saved to $CREDENTIALS_FILE"
echo ""
echo "🔒 Security notes:"
echo "   • This file is gitignored - your credentials are safe"
echo "   • Never commit this file to version control"
echo "   • Keep your Client Secret private"
echo ""
echo "▶️  You can now run: flutter run -d linux"
echo ""
