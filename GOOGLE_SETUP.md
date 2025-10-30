# Google API Setup Guide

This guide will help you set up Google Drive and Google Calendar API access for Keystone.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Desktop (Linux/Windows/macOS) Setup](#desktop-setup)
- [Mobile (Android) Setup](#mobile-setup)
- [Testing Your Setup](#testing-your-setup)

## Prerequisites

1. A Google Cloud Platform account (free tier is sufficient)
2. Google Cloud Console access: https://console.cloud.google.com/

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name (e.g., "Keystone App")
4. Click "Create"
5. Wait for the project to be created, then select it

## Step 2: Enable Required APIs

1. In your project, go to "APIs & Services" → "Library"
2. Search for and enable these APIs:
   - **Google Drive API**
   - **Google Calendar API**

## Desktop Setup

### Step 1: Create OAuth 2.0 Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. If prompted, configure the OAuth consent screen:
   - User Type: External
   - App name: Keystone
   - User support email: your email
   - Developer contact: your email
   - Scopes: Add `../auth/drive.file` and `../auth/calendar`
   - Test users: Add your Google account email
   - Click "Save and Continue"
4. Back to creating OAuth client ID:
   - Application type: **Desktop app**
   - Name: "Keystone Desktop"
   - Click "Create"
5. Download the JSON file or copy the Client ID and Client Secret

### Step 2: Configure Environment Variables

#### Option A: Using .env file (Recommended for development)

1. Create a `.env` file in the project root:
```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

2. Build and run with environment variables:
```bash
# Linux
flutter run -d linux \
  --dart-define=GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com \
  --dart-define=GOOGLE_CLIENT_SECRET=your-client-secret

# Or export them first
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-client-secret"
flutter run -d linux
```

#### Option B: Using compile-time constants

Alternatively, you can directly edit the source files (not recommended for public repos):

Edit `lib/services/sync_service_desktop.dart`:
```dart
static const String _clientId = 'your-client-id.apps.googleusercontent.com';
static const String _clientSecret = 'your-client-secret';
```

## Mobile Setup

### Step 1: Create OAuth 2.0 Credentials for Android

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: **Android**
4. Package name: `com.example.keystone` (or your package name)
5. Get your SHA-1 certificate fingerprint:

```bash
# Debug certificate (for development)
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA1

# Release certificate (for production)
keytool -list -v -keystore /path/to/your/release.keystore \
  -alias your-key-alias | grep SHA1
```

6. Paste the SHA-1 fingerprint
7. Click "Create"

### Step 2: Configure Android App

The OAuth client ID for Android is automatically used by `google_sign_in`. No additional configuration needed in code!

Just make sure your `android/app/build.gradle` has the correct package name:
```gradle
defaultConfig {
    applicationId "com.example.keystone"
    // ...
}
```

### Step 3: Add google-services.json (Optional but recommended)

1. Go to Firebase Console: https://console.firebase.google.com/
2. Add your app to Firebase
3. Download `google-services.json`
4. Place it in `android/app/`
5. Follow Firebase setup instructions for Android

## Testing Your Setup

### Desktop Testing

1. Run the app:
```bash
flutter run -d linux \
  --dart-define=GOOGLE_CLIENT_ID=your-id \
  --dart-define=GOOGLE_CLIENT_SECRET=your-secret
```

2. Go to Settings → "Sign in to Google Drive"
3. Browser should open for authentication
4. Grant permissions
5. You should see "Successfully signed in to Google Drive!"

### Mobile Testing

1. Build and install the app:
```bash
flutter run -d <your-device>
```

2. Go to Settings → "Sign in to Google Drive"
3. Google Sign-In dialog should appear
4. Select your Google account
5. Grant permissions
6. You should see successful sign-in

## Troubleshooting

### Desktop Issues

**Problem:** "Invalid client" error
- **Solution:** Double-check your Client ID and Client Secret
- Make sure you created a "Desktop app" type credential

**Problem:** Browser doesn't open
- **Solution:** Copy the URL from console and paste in browser manually

**Problem:** "redirect_uri_mismatch" error
- **Solution:** Desktop apps use `http://localhost` - this should work automatically
- If not, add `http://localhost:33215` to authorized redirect URIs in Google Console

### Mobile Issues

**Problem:** Sign-in dialog doesn't appear
- **Solution:** Check that SHA-1 fingerprint matches your debug/release keystore
- Verify package name in Google Console matches your app

**Problem:** "Sign in failed" or "DEVELOPER_ERROR"
- **Solution:** 
  1. Check package name in `android/app/build.gradle`
  2. Verify SHA-1 certificate fingerprint
  3. Make sure you enabled Google Drive API and Calendar API
  4. Check that OAuth consent screen is configured

**Problem:** "Access blocked" on consent screen
- **Solution:** Add your Google account email as a test user in OAuth consent screen

## Security Best Practices

1. **Never commit credentials to Git**
   - The `.env` file is already in `.gitignore`
   - Use environment variables for builds
   - For public releases, use user-provided credentials or Firebase Remote Config

2. **Limit OAuth scopes**
   - Only request `drive.file` scope (access to app-created files only)
   - Only request `calendar` scope for calendar features

3. **Use different credentials for development vs production**
   - Create separate OAuth clients for debug and release builds

4. **Rotate credentials if exposed**
   - If credentials are accidentally committed, immediately rotate them in Google Console

## Building for Release

### Desktop Release Build

```bash
flutter build linux \
  --dart-define=GOOGLE_CLIENT_ID=your-id \
  --dart-define=GOOGLE_CLIENT_SECRET=your-secret \
  --release
```

### Android Release Build

1. Make sure you've created an OAuth client ID with your **release** SHA-1 fingerprint
2. Build:
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Additional Resources

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google APIs for Dart](https://pub.dev/packages/googleapis)
- [OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
