#!/bin/bash

# Helper script to get SHA-1 fingerprint for Google OAuth setup
# Run this to get the fingerprint you need for Google Cloud Console

echo "==============================================="
echo "  Keystone - Google OAuth SHA-1 Fingerprint"
echo "==============================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found!"
    echo "   keytool is part of the Java Development Kit (JDK)"
    echo "   Please install JDK first"
    exit 1
fi

# Get debug keystore location
KEYSTORE="$HOME/.android/debug.keystore"

if [ ! -f "$KEYSTORE" ]; then
    echo "❌ Error: Debug keystore not found at: $KEYSTORE"
    echo "   Run an Android build first to generate it:"
    echo "   flutter build apk --debug"
    exit 1
fi

echo "📋 Debug Keystore Location:"
echo "   $KEYSTORE"
echo ""

echo "🔑 SHA-1 Fingerprint:"
echo ""

# Extract SHA-1 fingerprint
keytool -list -v -keystore "$KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | awk '{print $2}'

echo ""
echo "✅ Copy the fingerprint above and paste it in Google Cloud Console"
echo ""
echo "📝 Next Steps:"
echo "   1. Go to: https://console.cloud.google.com/"
echo "   2. Create OAuth Client ID for Android"
echo "   3. Package name: com.example.keystone"
echo "   4. Paste the SHA-1 fingerprint from above"
echo ""
echo "For release builds, you'll need the release keystore SHA-1"
echo ""
