/// Google OAuth credentials configuration
///
/// INSTRUCTIONS:
/// 1. Copy this file to google_credentials.dart
/// 2. Fill in your actual credentials from Google Cloud Console
/// 3. The real google_credentials.dart file is gitignored for security

class GoogleCredentials {
  // Desktop OAuth 2.0 credentials (from Google Cloud Console - Desktop app)
  static const String desktopClientId =
      'YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com';
  static const String desktopClientSecret = 'YOUR_DESKTOP_CLIENT_SECRET';

  // Mobile OAuth 2.0 client ID (from Google Cloud Console - Android app)
  // Note: Mobile doesn't use client secret, only client ID
  static const String mobileClientId =
      'YOUR_MOBILE_CLIENT_ID.apps.googleusercontent.com';
}
